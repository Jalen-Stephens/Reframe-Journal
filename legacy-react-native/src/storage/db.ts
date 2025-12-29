import { openDatabaseSync, type SQLiteDatabase } from "expo-sqlite";

const DB_NAME = "reframe_journal.db";

let dbInstance: SQLiteDatabase | null = null;

export const getDb = (): SQLiteDatabase => {
  if (!dbInstance) {
    dbInstance = openDatabaseSync(DB_NAME);
  }
  return dbInstance;
};

export const initDb = async () => {
  const db = getDb();
  await db.execAsync(
    `CREATE TABLE IF NOT EXISTS thought_records (
      id TEXT PRIMARY KEY NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      situationText TEXT NOT NULL,
      sensations TEXT NOT NULL,
      automaticThoughts TEXT NOT NULL,
      emotions TEXT NOT NULL,
      thinkingStyles TEXT,
      adaptiveResponses TEXT NOT NULL,
      outcomesByThought TEXT NOT NULL DEFAULT '{}',
      beliefAfterMainThought INTEGER,
      notes TEXT
    );`
  );

  try {
    await db.execAsync(
      "ALTER TABLE thought_records ADD COLUMN outcomesByThought TEXT NOT NULL DEFAULT '{}';"
    );
  } catch {
    // Column already exists in most cases; ignore migration errors.
  }

  await db.execAsync(
    `CREATE TABLE IF NOT EXISTS wizard_draft (
      id TEXT PRIMARY KEY NOT NULL,
      data TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );`
  );
};
