import { getDb } from "./db";
import { AutomaticThought, Emotion, ThoughtRecord } from "../models/ThoughtRecord";

const DRAFT_ID = "wizard_draft";

type ThoughtRecordRow = {
  id: string;
  createdAt: string;
  updatedAt: string;
  situationText: string;
  sensations: string;
  automaticThoughts: string;
  emotions: string;
  thinkingStyles: string | null;
  adaptiveResponses: string;
  outcomesByThought: string;
  beliefAfterMainThought: number | null;
  notes: string | null;
};

const serialize = (record: ThoughtRecord) => {
  return {
    ...record,
    sensations: JSON.stringify(record.sensations || []),
    automaticThoughts: JSON.stringify(record.automaticThoughts || []),
    emotions: JSON.stringify(record.emotions || []),
    thinkingStyles: JSON.stringify(record.thinkingStyles || []),
    adaptiveResponses: JSON.stringify(record.adaptiveResponses || {}),
    outcomesByThought: JSON.stringify(record.outcomesByThought || {})
  };
};

const parseJsonArray = <T>(value: string | null): T[] => {
  if (!value) {
    return [];
  }
  try {
    return JSON.parse(value) as T[];
  } catch {
    return [];
  }
};

const parseJsonObject = <T>(value: string | null, fallback: T): T => {
  if (!value) {
    return fallback;
  }
  try {
    const parsed = JSON.parse(value) as T;
    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
      return parsed;
    }
    return fallback;
  } catch {
    return fallback;
  }
};

const deserialize = (row: ThoughtRecordRow): ThoughtRecord => {
  return {
    id: row.id,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    situationText: row.situationText,
    sensations: parseJsonArray<string>(row.sensations),
    automaticThoughts: parseJsonArray<AutomaticThought>(row.automaticThoughts),
    emotions: parseJsonArray<Emotion>(row.emotions),
    thinkingStyles: parseJsonArray<string>(row.thinkingStyles),
    adaptiveResponses: parseJsonObject<ThoughtRecord["adaptiveResponses"]>(
      row.adaptiveResponses,
      {}
    ),
    outcomesByThought: parseJsonObject<ThoughtRecord["outcomesByThought"]>(
      row.outcomesByThought,
      {}
    ),
    beliefAfterMainThought: row.beliefAfterMainThought ?? undefined,
    notes: row.notes ?? ""
  };
};

const runSql = async (
  sql: string,
  params: (string | number | null)[] = []
) => {
  const db = getDb();
  await db.runAsync(sql, params);
};

export const createThoughtRecord = async (record: ThoughtRecord) => {
  const serialized = serialize(record);
  await runSql(
    `INSERT INTO thought_records (
      id, createdAt, updatedAt, situationText, sensations,
      automaticThoughts, emotions, thinkingStyles, adaptiveResponses,
      outcomesByThought,
      beliefAfterMainThought, notes
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);`,
    [
      serialized.id,
      serialized.createdAt,
      serialized.updatedAt,
      serialized.situationText,
      serialized.sensations,
      serialized.automaticThoughts,
      serialized.emotions,
      serialized.thinkingStyles,
      serialized.adaptiveResponses,
      serialized.outcomesByThought,
      serialized.beliefAfterMainThought ?? null,
      serialized.notes ?? null
    ]
  );
};

export const updateThoughtRecord = async (record: ThoughtRecord) => {
  const serialized = serialize(record);
  await runSql(
    `UPDATE thought_records SET
      updatedAt = ?,
      situationText = ?,
      sensations = ?,
      automaticThoughts = ?,
      emotions = ?,
      thinkingStyles = ?,
      adaptiveResponses = ?,
      outcomesByThought = ?,
      beliefAfterMainThought = ?,
      notes = ?
    WHERE id = ?;`,
    [
      serialized.updatedAt,
      serialized.situationText,
      serialized.sensations,
      serialized.automaticThoughts,
      serialized.emotions,
      serialized.thinkingStyles,
      serialized.adaptiveResponses,
      serialized.outcomesByThought,
      serialized.beliefAfterMainThought ?? null,
      serialized.notes ?? null,
      serialized.id
    ]
  );
};

export const getThoughtRecordById = async (id: string) => {
  const db = getDb();
  const row = await db.getFirstAsync<ThoughtRecordRow>(
    "SELECT * FROM thought_records WHERE id = ?;",
    [id]
  );
  return row ? deserialize(row) : null;
};

export const listThoughtRecords = async (limit = 20) => {
  const db = getDb();
  const rows = await db.getAllAsync<ThoughtRecordRow>(
    "SELECT * FROM thought_records ORDER BY createdAt DESC LIMIT ?;",
    [limit]
  );
  return rows.map(deserialize);
};

export const deleteThoughtRecord = async (id: string) => {
  await runSql("DELETE FROM thought_records WHERE id = ?;", [id]);
};

export const saveDraft = async (data: ThoughtRecord, updatedAt: string) => {
  await runSql(
    `INSERT OR REPLACE INTO wizard_draft (id, data, updatedAt)
     VALUES (?, ?, ?);`,
    [DRAFT_ID, JSON.stringify(data), updatedAt]
  );
};

export const getDraft = async () => {
  const db = getDb();
  const row = await db.getFirstAsync<{ data: string }>(
    "SELECT data FROM wizard_draft WHERE id = ?;",
    [DRAFT_ID]
  );
  if (!row) {
    return null;
  }
  try {
    return JSON.parse(row.data) as ThoughtRecord;
  } catch {
    return null;
  }
};

export const deleteDraft = async () => {
  await runSql("DELETE FROM wizard_draft WHERE id = ?;", [DRAFT_ID]);
};
