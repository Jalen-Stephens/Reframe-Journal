import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Keyboard,
  TouchableWithoutFeedback,
  TextInput,
  findNodeHandle,
  Pressable
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import Slider from "@react-native-community/slider";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { WizardProgress } from "../components/WizardProgress";
import { PrimaryButton } from "../components/PrimaryButton";
import { Accordion } from "../components/Accordion";
import { useWizard } from "../context/WizardContext";
import { clampPercent } from "../utils/validation";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";
import { AdaptiveResponsesForThought } from "../models/ThoughtRecord";

const QUICK_SET_VALUES = [0, 25, 50, 75, 100];
const KEYBOARD_SCROLL_OFFSET = 160;

type PromptConfig = {
  id: string;
  label: string;
  textKey: TextKey;
  beliefKey: BeliefKey;
};

type TextKey =
  | "evidenceText"
  | "alternativeText"
  | "outcomeText"
  | "friendText";

type BeliefKey =
  | "evidenceBelief"
  | "alternativeBelief"
  | "outcomeBelief"
  | "friendBelief";

const PROMPTS: PromptConfig[] = [
  {
    id: "evidence",
    label: "What is the evidence that the thought is true? Not true?",
    textKey: "evidenceText",
    beliefKey: "evidenceBelief"
  },
  {
    id: "alternative",
    label: "Is there an alternative explanation?",
    textKey: "alternativeText",
    beliefKey: "alternativeBelief"
  },
  {
    id: "outcome",
    label:
      "What's the worst that could happen? What's the best that could happen? What's the most realistic outcome?",
    textKey: "outcomeText",
    beliefKey: "outcomeBelief"
  },
  {
    id: "friend",
    label:
      "If a friend were in this situation and had this thought, what would I tell him/her?",
    textKey: "friendText",
    beliefKey: "friendBelief"
  }
];

const createEmptyPromptSet = (): AdaptiveResponsesForThought => ({
  evidenceText: "",
  evidenceBelief: 0,
  alternativeText: "",
  alternativeBelief: 0,
  outcomeText: "",
  outcomeBelief: 0,
  friendText: "",
  friendBelief: 0
});

const ensureThoughtResponses = (
  responses?: AdaptiveResponsesForThought
): AdaptiveResponsesForThought => {
  if (!responses) {
    return createEmptyPromptSet();
  }
  const merged = { ...createEmptyPromptSet(), ...responses };
  return merged;
};

const countAnsweredPrompts = (responses?: AdaptiveResponsesForThought) => {
  if (!responses) {
    return 0;
  }
  return PROMPTS.reduce((count, prompt) => {
    const text = responses[prompt.textKey] ?? "";
    return count + (text.trim().length > 0 ? 1 : 0);
  }, 0);
};

export const AdaptiveResponseScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep6">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const [expandedThoughtId, setExpandedThoughtId] = useState<string | null>(
    null
  );
  const [promptIndexByThought, setPromptIndexByThought] = useState<
    Record<string, number>
  >({});
  const scrollRef = useRef<ScrollView | null>(null);
  const inputRefs = useRef<Record<string, TextInput | null>>({});
  const thoughtPositions = useRef<Record<string, number>>({});
  const [showIncompleteHint, setShowIncompleteHint] = useState(false);
  const hasAutoExpanded = useRef(false);

  useEffect(() => {
    if (
      !expandedThoughtId &&
      !hasAutoExpanded.current &&
      draft.automaticThoughts.length > 0
    ) {
      hasAutoExpanded.current = true;
      setExpandedThoughtId(draft.automaticThoughts[0].id);
    }
  }, [draft.automaticThoughts, expandedThoughtId]);

  useEffect(() => {
    if (
      expandedThoughtId &&
      !draft.automaticThoughts.some((thought) => thought.id === expandedThoughtId)
    ) {
      setExpandedThoughtId(draft.automaticThoughts[0]?.id ?? null);
    }
  }, [draft.automaticThoughts, expandedThoughtId]);

  useEffect(() => {
    setDraft((current) => {
      let changed = false;
      const nextResponses = { ...current.adaptiveResponses };
      current.automaticThoughts.forEach((thought) => {
        const ensured = ensureThoughtResponses(nextResponses[thought.id]);
        if (ensured !== nextResponses[thought.id]) {
          nextResponses[thought.id] = ensured;
          changed = true;
        }
      });
      if (!changed) {
        return current;
      }
      return { ...current, adaptiveResponses: nextResponses };
    });
  }, [draft.automaticThoughts, setDraft]);

  useEffect(() => {
    setPromptIndexByThought((current) => {
      if (draft.automaticThoughts.length === 0) {
        return Object.keys(current).length > 0 ? {} : current;
      }
      const next = { ...current };
      let changed = false;
      draft.automaticThoughts.forEach((thought) => {
        if (typeof next[thought.id] !== "number") {
          next[thought.id] = 0;
          changed = true;
        }
      });
      Object.keys(next).forEach((id) => {
        if (!draft.automaticThoughts.some((thought) => thought.id === id)) {
          delete next[id];
          changed = true;
        }
      });
      return changed ? next : current;
    });
  }, [draft.automaticThoughts]);

  const updateResponse = useCallback(
    (thoughtId: string, promptKey: TextKey, text: string) => {
      setDraft((current) => {
        const nextResponses = { ...current.adaptiveResponses };
        const thoughtResponses = ensureThoughtResponses(nextResponses[thoughtId]);
        nextResponses[thoughtId] = {
          ...thoughtResponses,
          [promptKey]: text
        };
        return { ...current, adaptiveResponses: nextResponses };
      });
    },
    [setDraft]
  );

  const updateBelief = useCallback(
    (thoughtId: string, promptKey: BeliefKey, value: number) => {
      const belief = clampPercent(value);
      setDraft((current) => {
        const nextResponses = { ...current.adaptiveResponses };
        const thoughtResponses = ensureThoughtResponses(nextResponses[thoughtId]);
        nextResponses[thoughtId] = {
          ...thoughtResponses,
          [promptKey]: belief
        };
        return { ...current, adaptiveResponses: nextResponses };
      });
    },
    [setDraft]
  );

  const scrollToInput = useCallback((key: string) => {
    const input = inputRefs.current[key];
    const scrollView = scrollRef.current;
    if (!input || !scrollView) {
      return;
    }
    const inputNode = findNodeHandle(input);
    if (!inputNode) {
      return;
    }
    const scrollResponder = scrollView.getScrollResponder?.();
    if (!scrollResponder?.scrollResponderScrollNativeHandleToKeyboard) {
      return;
    }
    scrollResponder.scrollResponderScrollNativeHandleToKeyboard(
      inputNode,
      KEYBOARD_SCROLL_OFFSET,
      true
    );
  }, []);

  const advancePrompt = useCallback(
    (thoughtId: string) => {
      setPromptIndexByThought((current) => {
        const next = { ...current };
        const currentIndex = next[thoughtId] ?? 0;
        next[thoughtId] = Math.min(currentIndex + 1, PROMPTS.length - 1);
        return next;
      });
    },
    [setPromptIndexByThought]
  );

  const retreatPrompt = useCallback(
    (thoughtId: string) => {
      setPromptIndexByThought((current) => {
        const next = { ...current };
        const currentIndex = next[thoughtId] ?? 0;
        next[thoughtId] = Math.max(currentIndex - 1, 0);
        return next;
      });
    },
    [setPromptIndexByThought]
  );

  const completionByThought = useMemo(() => {
    const counts: Record<string, number> = {};
    draft.automaticThoughts.forEach((thought) => {
      counts[thought.id] = countAnsweredPrompts(
        draft.adaptiveResponses[thought.id]
      );
    });
    return counts;
  }, [draft.automaticThoughts, draft.adaptiveResponses]);

  const canProceed = useMemo(() => {
    if (draft.automaticThoughts.length === 0) {
      return false;
    }
    return draft.automaticThoughts.every(
      (thought) => (completionByThought[thought.id] ?? 0) >= 1
    );
  }, [draft.automaticThoughts, completionByThought]);

  useEffect(() => {
    if (canProceed && showIncompleteHint) {
      setShowIncompleteHint(false);
    }
  }, [canProceed, showIncompleteHint]);

  const handleNext = useCallback(async () => {
    if (canProceed) {
      await persistDraft();
      navigation.navigate("WizardStep7");
      return;
    }
    const firstIncomplete = draft.automaticThoughts.find(
      (thought) => (completionByThought[thought.id] ?? 0) < 1
    );
    if (firstIncomplete) {
      setExpandedThoughtId(firstIncomplete.id);
      const y = thoughtPositions.current[firstIncomplete.id];
      if (typeof y === "number") {
        scrollRef.current?.scrollTo({ y: Math.max(0, y - 16), animated: true });
      }
    }
    setShowIncompleteHint(true);
  }, [
    canProceed,
    completionByThought,
    draft.automaticThoughts,
    navigation,
    persistDraft
  ]);

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <TouchableWithoutFeedback onPress={Keyboard.dismiss} accessible={false}>
        <View style={styles.container}>
          <ScrollView
            ref={scrollRef}
            contentContainerStyle={styles.scrollContent}
            keyboardShouldPersistTaps="handled"
            keyboardDismissMode={
              Platform.OS === "ios" ? "interactive" : "on-drag"
            }
          >
            <WizardProgress step={5} total={6} />
            <Text style={styles.title}>Adaptive Response</Text>
            <Text style={styles.helper}>
              Respond to each automatic thought using the prompts below. Add at
              least one grounded response per thought.
            </Text>
            {showIncompleteHint ? (
              <Text style={styles.validationHint}>
                Complete at least one response for each thought before continuing.
              </Text>
            ) : null}

            {draft.automaticThoughts.map((thought) => {
              const isExpanded = expandedThoughtId === thought.id;
              const responses = draft.adaptiveResponses[thought.id];
              const answeredCount = completionByThought[thought.id] ?? 0;
              const isComplete = answeredCount === PROMPTS.length;
              const currentPromptIndex = promptIndexByThought[thought.id] ?? 0;
              const currentPrompt =
                PROMPTS[currentPromptIndex] ?? PROMPTS[0];
              const currentText =
                responses?.[currentPrompt.textKey]?.trim() ?? "";
              const currentBelief =
                responses?.[currentPrompt.beliefKey] ?? 0;
              const isLastPrompt =
                currentPromptIndex === PROMPTS.length - 1;
              const canAdvance = currentText.length > 0;

              return (
                <View
                  key={thought.id}
                  onLayout={(event) => {
                    thoughtPositions.current[thought.id] =
                      event.nativeEvent.layout.y;
                  }}
                >
                  <Accordion
                    isExpanded={isExpanded}
                    onToggle={() => {
                      setExpandedThoughtId((current) => {
                        const next = current === thought.id ? null : thought.id;
                        if (next) {
                          const y = thoughtPositions.current[next];
                          if (typeof y === "number") {
                            scrollRef.current?.scrollTo({
                              y: Math.max(0, y - 16),
                              animated: true
                            });
                          }
                        }
                        return next;
                      });
                    }}
                    header={
                      <View style={styles.accordionHeader}>
                        <View style={styles.headerTextWrap}>
                          <Text
                            style={styles.thoughtText}
                            numberOfLines={1}
                            ellipsizeMode="tail"
                          >
                            {thought.text}
                          </Text>
                          <View style={styles.headerMetaRow}>
                            <View style={styles.beliefPill}>
                              <Text style={styles.beliefPillText}>
                                Original {thought.beliefBefore}%
                              </Text>
                            </View>
                            <Text style={styles.completionText}>
                              {answeredCount} / {PROMPTS.length} answered
                            </Text>
                            <View
                              style={[
                                styles.statusPill,
                                isComplete
                                  ? styles.statusPillComplete
                                  : styles.statusPillIncomplete
                              ]}
                            >
                              <Text style={styles.statusPillText}>
                                {isComplete ? "Complete" : "Incomplete"}
                              </Text>
                            </View>
                          </View>
                        </View>
                        <Text style={styles.chevron}>
                          {isExpanded ? "v" : ">"}
                        </Text>
                      </View>
                    }
                  >
                    <View style={styles.expandedIntro}>
                      <Text style={styles.respondingLabel}>
                        Responding to: "{thought.text}"
                      </Text>
                      <Text style={styles.questionCount}>
                        Question {currentPromptIndex + 1} of {PROMPTS.length}
                      </Text>
                    </View>

                    <View style={styles.promptSection}>
                      <Text style={styles.promptTitle}>
                        {currentPrompt.label}
                      </Text>
                      <TextInput
                        ref={(ref) => {
                          inputRefs.current[
                            `${thought.id}:${currentPrompt.id}`
                          ] = ref;
                        }}
                        style={styles.multilineInput}
                        placeholder="Write a grounded response"
                        placeholderTextColor={theme.placeholder}
                        value={currentText}
                        onChangeText={(value) =>
                          updateResponse(thought.id, currentPrompt.textKey, value)
                        }
                        multiline
                        returnKeyType="done"
                        blurOnSubmit
                        onFocus={() =>
                          scrollToInput(`${thought.id}:${currentPrompt.id}`)
                        }
                        onSubmitEditing={() => Keyboard.dismiss()}
                      />
                    <View style={styles.sliderSection}>
                      <Text style={styles.sliderLabel}>
                        How much do you believe this response?
                      </Text>
                      <Text style={styles.sliderValue}>
                        {currentBelief}%
                      </Text>
                      <Slider
                          minimumValue={0}
                          maximumValue={100}
                          step={1}
                          value={currentBelief}
                          onValueChange={(value) =>
                            updateBelief(
                              thought.id,
                              currentPrompt.beliefKey,
                              value
                            )
                          }
                          onSlidingStart={() => Keyboard.dismiss()}
                          onTouchStart={() => Keyboard.dismiss()}
                          minimumTrackTintColor={theme.accent}
                          maximumTrackTintColor={theme.border}
                          thumbTintColor={theme.accent}
                        />
                        <View style={styles.quickSetRow}>
                          {QUICK_SET_VALUES.map((value) => (
                            <Pressable
                              key={`${currentPrompt.id}-${value}`}
                              onPress={() =>
                                updateBelief(
                                  thought.id,
                                  currentPrompt.beliefKey,
                                  value
                                )
                              }
                              style={({ pressed }) => [
                                styles.quickSetPill,
                                value === currentBelief &&
                                  styles.quickSetPillActive,
                                pressed && styles.quickSetPillPressed
                              ]}
                            >
                              <Text
                                style={[
                                  styles.quickSetText,
                                  value === currentBelief &&
                                    styles.quickSetTextActive
                                ]}
                              >
                                {value}
                              </Text>
                            </Pressable>
                          ))}
                        </View>
                      </View>
                    </View>

                    <View style={styles.promptDivider} />

                    <View style={styles.promptActions}>
                      <Pressable
                        onPress={() => retreatPrompt(thought.id)}
                        disabled={currentPromptIndex === 0}
                        style={({ pressed }) => [
                          styles.backButton,
                          currentPromptIndex === 0 && styles.backButtonDisabled,
                          pressed && currentPromptIndex !== 0 && styles.backButtonPressed
                        ]}
                      >
                        <Text style={styles.backButtonText}>Back</Text>
                      </Pressable>
                      <PrimaryButton
                        label={isLastPrompt ? "Mark Thought Complete" : "Save & Continue"}
                        onPress={() => {
                          if (!canAdvance) {
                            return;
                          }
                          if (isLastPrompt) {
                            const currentIndex =
                              draft.automaticThoughts.findIndex(
                                (item) => item.id === thought.id
                              );
                            const nextThought =
                              draft.automaticThoughts[currentIndex + 1];
                            setExpandedThoughtId(nextThought?.id ?? null);
                            if (nextThought?.id) {
                              const y = thoughtPositions.current[nextThought.id];
                              if (typeof y === "number") {
                                scrollRef.current?.scrollTo({
                                  y: Math.max(0, y - 16),
                                  animated: true
                                });
                              }
                            }
                            return;
                          }
                          advancePrompt(thought.id);
                        }}
                        disabled={!canAdvance}
                        style={styles.primaryAction}
                      />
                    </View>
                  </Accordion>
                </View>
              );
            })}
          </ScrollView>

          <SafeAreaView edges={["bottom"]} style={styles.bottomBar}>
            <PrimaryButton
              label="Next"
              disabled={!canProceed}
              onPress={handleNext}
              onDisabledPress={handleNext}
            />
          </SafeAreaView>
        </View>
      </TouchableWithoutFeedback>
    </KeyboardAvoidingView>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.background
    },
    scrollContent: {
      padding: 16,
      paddingBottom: 200
    },
    title: {
      fontSize: 18,
      fontWeight: "600",
      marginBottom: 12,
      color: theme.textPrimary
    },
    helper: {
      fontSize: 13,
      color: theme.textSecondary,
      marginBottom: 16,
      lineHeight: 18
    },
    validationHint: {
      fontSize: 12,
      color: theme.textSecondary,
      marginBottom: 12
    },
    accordionHeader: {
      flexDirection: "row",
      alignItems: "center"
    },
    headerTextWrap: {
      flex: 1,
      paddingRight: 8
    },
    thoughtText: {
      fontSize: 14,
      color: theme.textPrimary,
      marginBottom: 6,
      lineHeight: 18
    },
    headerMetaRow: {
      flexDirection: "row",
      alignItems: "center"
    },
    beliefPill: {
      backgroundColor: theme.muted,
      paddingHorizontal: 8,
      paddingVertical: 4,
      borderRadius: 999,
      marginRight: 8
    },
    beliefPillText: {
      fontSize: 11,
      color: theme.textSecondary
    },
    completionText: {
      fontSize: 11,
      color: theme.textSecondary,
      marginRight: 8
    },
    statusPill: {
      borderWidth: 1,
      paddingHorizontal: 8,
      paddingVertical: 3,
      borderRadius: 999
    },
    statusPillComplete: {
      borderColor: theme.accent,
      backgroundColor: theme.muted
    },
    statusPillIncomplete: {
      borderColor: theme.border,
      backgroundColor: theme.card
    },
    statusPillText: {
      fontSize: 10,
      color: theme.textSecondary
    },
    chevron: {
      fontSize: 18,
      color: theme.textSecondary,
      marginLeft: 4
    },
    expandedIntro: {
      paddingTop: 10,
      paddingBottom: 6
    },
    respondingLabel: {
      fontSize: 13,
      color: theme.textSecondary,
      marginBottom: 6
    },
    questionCount: {
      fontSize: 12,
      color: theme.textPrimary,
      marginBottom: 4
    },
    promptSection: {
      paddingTop: 10
    },
    promptTitle: {
      fontSize: 14,
      color: theme.textPrimary,
      marginBottom: 8,
      lineHeight: 18
    },
    multilineInput: {
      minHeight: 100,
      textAlignVertical: "top",
      borderWidth: 1,
      borderColor: theme.border,
      borderRadius: 8,
      padding: 10,
      backgroundColor: theme.card,
      color: theme.textPrimary
    },
    sliderSection: {
      marginTop: 8
    },
    sliderLabel: {
      fontSize: 12,
      color: theme.textSecondary,
      textAlign: "center",
      marginBottom: 4
    },
    sliderValue: {
      fontSize: 18,
      color: theme.textPrimary,
      fontWeight: "600",
      textAlign: "center",
      marginBottom: 4
    },
    quickSetRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      marginTop: 6
    },
    quickSetPill: {
      borderWidth: 1,
      borderColor: theme.border,
      borderRadius: 999,
      paddingVertical: 4,
      paddingHorizontal: 10,
      backgroundColor: theme.card
    },
    quickSetPillActive: {
      borderColor: theme.accent,
      backgroundColor: theme.muted
    },
    quickSetPillPressed: {
      opacity: 0.85
    },
    quickSetText: {
      fontSize: 11,
      color: theme.textSecondary
    },
    quickSetTextActive: {
      color: theme.textPrimary
    },
    promptDivider: {
      height: 1,
      backgroundColor: theme.border,
      marginTop: 12
    },
    promptActions: {
      flexDirection: "row",
      alignItems: "center",
      marginTop: 12
    },
    backButton: {
      borderWidth: 1,
      borderColor: theme.border,
      borderRadius: 8,
      paddingVertical: 12,
      paddingHorizontal: 16
    },
    backButtonDisabled: {
      opacity: 0.5
    },
    backButtonPressed: {
      opacity: 0.85
    },
    backButtonText: {
      fontSize: 14,
      color: theme.textSecondary
    },
    primaryAction: {
      flex: 1,
      marginLeft: 12
    },
    bottomBar: {
      paddingHorizontal: 16,
      paddingTop: 12,
      backgroundColor: theme.background,
      borderTopWidth: 1,
      borderTopColor: theme.border
    }
  });
