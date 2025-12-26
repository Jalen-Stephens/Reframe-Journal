export type AutomaticThought = {
  id: string;
  text: string;
  beliefBefore: number;
};

export type Emotion = {
  id: string;
  label: string;
  intensityBefore: number;
  intensityAfter?: number;
};

export type AdaptiveResponse = {
  id: string;
  promptKey: string;
  responseText: string;
  beliefInResponse: number;
};

export type ThoughtRecord = {
  id: string;
  createdAt: string;
  updatedAt: string;
  situationText: string;
  sensations: string[];
  automaticThoughts: AutomaticThought[];
  emotions: Emotion[];
  thinkingStyles?: string[];
  adaptiveResponses: AdaptiveResponse[];
  beliefAfterMainThought?: number;
  notes?: string;
};

export const createEmptyThoughtRecord = (nowIso: string): ThoughtRecord => ({
  id: "",
  createdAt: nowIso,
  updatedAt: nowIso,
  situationText: "",
  sensations: [],
  automaticThoughts: [],
  emotions: [],
  thinkingStyles: [],
  adaptiveResponses: [],
  beliefAfterMainThought: undefined,
  notes: ""
});
