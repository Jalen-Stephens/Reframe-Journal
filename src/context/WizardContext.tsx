import React, { createContext, useContext, useEffect, useState } from "react";
import { ThoughtRecord, createEmptyThoughtRecord } from "../models/ThoughtRecord";
import { nowIso } from "../utils/date";
import { generateId } from "../utils/uuid";
import { deleteDraft, getDraft, saveDraft } from "../storage/thoughtRecordsRepo";

type WizardContextValue = {
  draft: ThoughtRecord;
  setDraft: React.Dispatch<React.SetStateAction<ThoughtRecord>>;
  resetDraft: () => void;
  persistDraft: (nextDraft?: ThoughtRecord) => Promise<void>;
  loadDraft: () => Promise<void>;
  clearDraft: () => Promise<void>;
};

const WizardContext = createContext<WizardContextValue | undefined>(undefined);

const buildFreshDraft = (): ThoughtRecord => {
  const now = nowIso();
  return {
    ...createEmptyThoughtRecord(now),
    id: generateId()
  };
};

export const WizardProvider: React.FC<{ children: React.ReactNode }> = ({
  children
}) => {
  const [draft, setDraft] = useState<ThoughtRecord>(buildFreshDraft());

  const loadDraft = async () => {
    const stored = await getDraft();
    if (stored) {
      setDraft(stored);
    }
  };

  const persistDraft = async (nextDraft?: ThoughtRecord) => {
    const base = nextDraft ?? draft;
    const updated = {
      ...base,
      updatedAt: nowIso()
    };
    setDraft(updated);
    await saveDraft(updated, updated.updatedAt);
  };

  const resetDraft = () => {
    setDraft(buildFreshDraft());
  };

  const clearDraft = async () => {
    await deleteDraft();
    resetDraft();
  };

  useEffect(() => {
    loadDraft().catch((error) => console.error("Load draft failed", error));
  }, []);

  return (
    <WizardContext.Provider
      value={{ draft, setDraft, resetDraft, persistDraft, loadDraft, clearDraft }}
    >
      {children}
    </WizardContext.Provider>
  );
};

export const useWizard = (): WizardContextValue => {
  const ctx = useContext(WizardContext);
  if (!ctx) {
    throw new Error("useWizard must be used within WizardProvider");
  }
  return ctx;
};
