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
      beliefAfterMainThought INTEGER,
      notes TEXT
    );`
  );

  await db.execAsync(
    `CREATE TABLE IF NOT EXISTS wizard_draft (
      id TEXT PRIMARY KEY NOT NULL,
      data TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );`
  );
};
