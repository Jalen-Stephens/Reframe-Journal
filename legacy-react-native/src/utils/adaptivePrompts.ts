export const ADAPTIVE_PROMPTS = [
  {
    key: "evidence",
    label: "What is the evidence that the thought is true? Not true?",
    textKey: "evidenceText",
    beliefKey: "evidenceBelief"
  },
  {
    key: "alternative",
    label: "Is there an alternative explanation?",
    textKey: "alternativeText",
    beliefKey: "alternativeBelief"
  },
  {
    key: "outcome",
    label:
      "What's the worst that could happen? What's the best that could happen? What's the most realistic outcome?",
    textKey: "outcomeText",
    beliefKey: "outcomeBelief"
  },
  {
    key: "friend",
    label:
      "If a friend were in this situation and had this thought, what would I tell him/her?",
    textKey: "friendText",
    beliefKey: "friendBelief"
  }
] as const;
