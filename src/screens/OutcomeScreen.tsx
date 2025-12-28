import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  Alert,
  FlatList,
  KeyboardAvoidingView,
  Platform,
  Keyboard,
  TouchableWithoutFeedback,
  TextInput,
  Pressable,
  LayoutAnimation,
  UIManager
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import Slider from "@react-native-community/slider";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { WizardProgress } from "../components/WizardProgress";
import { useWizard } from "../context/WizardContext";
import { clampPercent, isRequiredTextValid } from "../utils/validation";
import { createThoughtRecord } from "../storage/thoughtRecordsRepo";
import { nowIso } from "../utils/date";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";
import { Accordion } from "../components/Accordion";
import { PrimaryButton } from "../components/PrimaryButton";
import {
  AutomaticThought,
  Emotion,
  ThoughtOutcome
} from "../models/ThoughtRecord";

const buildDefaultOutcome = (
  thought: AutomaticThought,
  emotions: Emotion[]
): ThoughtOutcome => ({
  beliefAfter: thought.beliefBefore,
  emotionsAfter: emotions.reduce<Record<string, number>>((acc, emotion) => {
    acc[emotion.id] = emotion.intensityBefore;
    return acc;
  }, {}),
  reflection: "",
  isComplete: false
});

const mergeOutcome = (
  thought: AutomaticThought,
  emotions: Emotion[],
  existing?: ThoughtOutcome
): ThoughtOutcome => {
  const defaults = buildDefaultOutcome(thought, emotions);
  const mergedEmotions = {
    ...defaults.emotionsAfter,
    ...(existing?.emotionsAfter ?? {})
  };
  return {
    beliefAfter: existing?.beliefAfter ?? defaults.beliefAfter,
    emotionsAfter: mergedEmotions,
    reflection: existing?.reflection ?? defaults.reflection,
    isComplete: existing?.isComplete ?? false
  };
};

export const OutcomeScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep7">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft, clearDraft } = useWizard();
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const [expandedThoughtId, setExpandedThoughtId] = useState<string | null>(
    null
  );
  const [showIncompleteHint, setShowIncompleteHint] = useState(false);
  const listRef = useRef<FlatList<AutomaticThought> | null>(null);
  const thoughtPositions = useRef<Record<string, number>>({});

  useEffect(() => {
    if (Platform.OS === "android") {
      UIManager.setLayoutAnimationEnabledExperimental?.(true);
    }
  }, []);

  useEffect(() => {
    setDraft((current) => {
      const nextOutcomes = { ...(current.outcomesByThought ?? {}) };
      let changed = false;

      current.automaticThoughts.forEach((thought) => {
        const existing = nextOutcomes[thought.id];
        const ensured = mergeOutcome(thought, current.emotions, existing);
        const emotionsEqual =
          existing &&
          Object.keys(ensured.emotionsAfter).every(
            (key) => existing.emotionsAfter?.[key] === ensured.emotionsAfter[key]
          ) &&
          Object.keys(existing.emotionsAfter ?? {}).every((key) =>
            Object.prototype.hasOwnProperty.call(ensured.emotionsAfter, key)
          );
        const needsUpdate =
          !existing ||
          existing.beliefAfter !== ensured.beliefAfter ||
          existing.reflection !== ensured.reflection ||
          existing.isComplete !== ensured.isComplete ||
          !emotionsEqual;

        if (needsUpdate) {
          nextOutcomes[thought.id] = ensured;
          changed = true;
        }
      });

      Object.keys(nextOutcomes).forEach((id) => {
        if (!current.automaticThoughts.some((thought) => thought.id === id)) {
          delete nextOutcomes[id];
          changed = true;
        }
      });

      if (!changed) {
        return current;
      }
      return { ...current, outcomesByThought: nextOutcomes };
    });
  }, [draft.automaticThoughts, draft.emotions, setDraft]);

  useEffect(() => {
    if (expandedThoughtId || draft.automaticThoughts.length === 0) {
      return;
    }
    const firstIncomplete = draft.automaticThoughts.find(
      (thought) => !draft.outcomesByThought?.[thought.id]?.isComplete
    );
    setExpandedThoughtId(firstIncomplete?.id ?? draft.automaticThoughts[0].id);
  }, [draft.automaticThoughts, draft.outcomesByThought, expandedThoughtId]);

  const updateEmotionAfter = useCallback(
    (thoughtId: string, emotionId: string, value: number) => {
      const intensity = clampPercent(value);
      setDraft((current) => {
        const thought = current.automaticThoughts.find(
          (item) => item.id === thoughtId
        );
        if (!thought) {
          return current;
        }
        const nextOutcomes = { ...(current.outcomesByThought ?? {}) };
        const outcome = mergeOutcome(
          thought,
          current.emotions,
          nextOutcomes[thoughtId]
        );
        nextOutcomes[thoughtId] = {
          ...outcome,
          emotionsAfter: {
            ...outcome.emotionsAfter,
            [emotionId]: intensity
          }
        };
        return { ...current, outcomesByThought: nextOutcomes };
      });
    },
    [setDraft]
  );

  const updateBeliefAfter = useCallback(
    (thoughtId: string, value: number) => {
      const belief = clampPercent(value);
      setDraft((current) => {
        const thought = current.automaticThoughts.find(
          (item) => item.id === thoughtId
        );
        if (!thought) {
          return current;
        }
        const nextOutcomes = { ...(current.outcomesByThought ?? {}) };
        const outcome = mergeOutcome(
          thought,
          current.emotions,
          nextOutcomes[thoughtId]
        );
        nextOutcomes[thoughtId] = {
          ...outcome,
          beliefAfter: belief
        };
        return { ...current, outcomesByThought: nextOutcomes };
      });
    },
    [setDraft]
  );

  const updateReflection = useCallback(
    (thoughtId: string, text: string) => {
      setDraft((current) => {
        const thought = current.automaticThoughts.find(
          (item) => item.id === thoughtId
        );
        if (!thought) {
          return current;
        }
        const nextOutcomes = { ...(current.outcomesByThought ?? {}) };
        const outcome = mergeOutcome(
          thought,
          current.emotions,
          nextOutcomes[thoughtId]
        );
        nextOutcomes[thoughtId] = {
          ...outcome,
          reflection: text
        };
        return { ...current, outcomesByThought: nextOutcomes };
      });
    },
    [setDraft]
  );

  const markComplete = useCallback(
    (thoughtId: string) => {
      LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
      setDraft((current) => {
        const thought = current.automaticThoughts.find(
          (item) => item.id === thoughtId
        );
        if (!thought) {
          return current;
        }
        const nextOutcomes = { ...(current.outcomesByThought ?? {}) };
        const outcome = mergeOutcome(
          thought,
          current.emotions,
          nextOutcomes[thoughtId]
        );
        nextOutcomes[thoughtId] = { ...outcome, isComplete: true };
        return { ...current, outcomesByThought: nextOutcomes };
      });
      const nextThought = draft.automaticThoughts.find(
        (thought) =>
          thought.id !== thoughtId &&
          !draft.outcomesByThought?.[thought.id]?.isComplete
      );
      setExpandedThoughtId(nextThought?.id ?? null);
    },
    [draft.automaticThoughts, draft.outcomesByThought, setDraft]
  );

  const completedCount = useMemo(() => {
    return draft.automaticThoughts.reduce((count, thought) => {
      return count + (draft.outcomesByThought?.[thought.id]?.isComplete ? 1 : 0);
    }, 0);
  }, [draft.automaticThoughts, draft.outcomesByThought]);

  const totalThoughts = draft.automaticThoughts.length;
  const allComplete = totalThoughts > 0 && completedCount === totalThoughts;

  useEffect(() => {
    if (allComplete && showIncompleteHint) {
      setShowIncompleteHint(false);
    }
  }, [allComplete, showIncompleteHint]);

  const handleFinish = useCallback(async () => {
    if (!allComplete) {
      const firstIncomplete = draft.automaticThoughts.find(
        (thought) => !draft.outcomesByThought?.[thought.id]?.isComplete
      );
      if (firstIncomplete) {
        setExpandedThoughtId(firstIncomplete.id);
        const y = thoughtPositions.current[firstIncomplete.id];
        if (typeof y === "number") {
          listRef.current?.scrollToOffset({
            offset: Math.max(0, y - 16),
            animated: true
          });
        }
      }
      setShowIncompleteHint(true);
      return;
    }
    if (!isRequiredTextValid(draft.situationText)) {
      Alert.alert("Missing situation", "Add a situation before saving.");
      return;
    }

    const record = {
      ...draft,
      updatedAt: nowIso()
    };

    await createThoughtRecord(record);
    await clearDraft();
    navigation.popToTop();
  }, [allComplete, clearDraft, draft, navigation]);

  const renderThoughtItem = useCallback(
    ({ item: thought }: { item: AutomaticThought }) => {
      const outcome = mergeOutcome(
        thought,
        draft.emotions,
        draft.outcomesByThought?.[thought.id]
      );
      const isExpanded = expandedThoughtId === thought.id;
      const isComplete = Boolean(outcome.isComplete);
      const beliefDelta = outcome.beliefAfter - thought.beliefBefore;
      const deltaLabel =
        beliefDelta === 0
          ? `${thought.beliefBefore}% → ${outcome.beliefAfter}% 0%`
          : beliefDelta < 0
          ? `${thought.beliefBefore}% → ${outcome.beliefAfter}% ↓ ${Math.abs(
              beliefDelta
            )}%`
          : `${thought.beliefBefore}% → ${outcome.beliefAfter}% ↑ ${beliefDelta}%`;

      return (
        <View
          onLayout={(event) => {
            thoughtPositions.current[thought.id] =
              event.nativeEvent.layout.y;
          }}
        >
          <Accordion
            isExpanded={isExpanded}
            onToggle={() => {
              LayoutAnimation.configureNext(
                LayoutAnimation.Presets.easeInEaseOut
              );
              setExpandedThoughtId((current) => {
                const next = current === thought.id ? null : thought.id;
                if (next) {
                  const y = thoughtPositions.current[next];
                  if (typeof y === "number") {
                    listRef.current?.scrollToOffset({
                      offset: Math.max(0, y - 16),
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
                    <Text style={styles.deltaText}>{deltaLabel}</Text>
                    {isComplete ? (
                      <View
                        style={[styles.statusPill, styles.statusPillComplete]}
                      >
                        <Text style={styles.statusPillText}>Complete</Text>
                      </View>
                    ) : null}
                  </View>
                </View>
                <Text style={styles.chevron}>{isExpanded ? "v" : ">"}</Text>
              </View>
            }
          >
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>
                How much do you believe this thought now?
              </Text>
              <Text style={styles.sliderValue}>{outcome.beliefAfter}%</Text>
              <Slider
                minimumValue={0}
                maximumValue={100}
                step={1}
                value={outcome.beliefAfter}
                onValueChange={(value) => updateBeliefAfter(thought.id, value)}
                onSlidingStart={() => Keyboard.dismiss()}
                onTouchStart={() => Keyboard.dismiss()}
                minimumTrackTintColor={theme.accent}
                maximumTrackTintColor={theme.border}
                thumbTintColor={theme.accent}
              />
              <Text style={styles.referenceText}>
                Original belief: {thought.beliefBefore}%
              </Text>
            </View>

            <View style={styles.sectionDivider} />

            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Re-rate emotions</Text>
              {draft.emotions.length === 0 ? (
                <Text style={styles.helperMuted}>
                  No emotions were selected earlier.
                </Text>
              ) : null}
              {draft.emotions.map((emotion) => {
                const currentIntensity =
                  outcome.emotionsAfter[emotion.id] ??
                  emotion.intensityBefore;
                return (
                  <View key={emotion.id} style={styles.emotionBlock}>
                    <View style={styles.emotionHeader}>
                      <Text style={styles.emotionLabel}>{emotion.label}</Text>
                      <Text style={styles.emotionBefore}>
                        Before: {emotion.intensityBefore}
                      </Text>
                    </View>
                    <Text style={styles.emotionValue}>{currentIntensity}</Text>
                    <Slider
                      minimumValue={0}
                      maximumValue={100}
                      step={1}
                      value={currentIntensity}
                      onValueChange={(value) =>
                        updateEmotionAfter(thought.id, emotion.id, value)
                      }
                      onSlidingStart={() => Keyboard.dismiss()}
                      onTouchStart={() => Keyboard.dismiss()}
                      minimumTrackTintColor={theme.accent}
                      maximumTrackTintColor={theme.border}
                      thumbTintColor={theme.accent}
                    />
                  </View>
                );
              })}
            </View>

            <View style={styles.sectionDivider} />

            <View style={styles.section}>
              <Text style={styles.sectionTitle}>
                Anything you want to note after this thought?
              </Text>
              <TextInput
                style={styles.reflectionInput}
                placeholder="Optional reflection"
                placeholderTextColor={theme.placeholder}
                value={outcome.reflection ?? ""}
                onChangeText={(text) => updateReflection(thought.id, text)}
                multiline
                numberOfLines={3}
                returnKeyType="done"
                blurOnSubmit
                onSubmitEditing={() => Keyboard.dismiss()}
              />
            </View>

            <PrimaryButton
              label={isComplete ? "Thought Complete" : "Mark Thought Complete"}
              onPress={() => markComplete(thought.id)}
              disabled={isComplete}
              style={styles.completeButton}
            />
          </Accordion>
        </View>
      );
    },
    [
      draft.emotions,
      draft.outcomesByThought,
      expandedThoughtId,
      markComplete,
      theme.accent,
      theme.border,
      theme.placeholder,
      updateBeliefAfter,
      updateEmotionAfter,
      updateReflection
    ]
  );

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <TouchableWithoutFeedback onPress={Keyboard.dismiss} accessible={false}>
        <View style={styles.container}>
          <FlatList
            ref={listRef}
            data={draft.automaticThoughts}
            keyExtractor={(item) => item.id}
            renderItem={renderThoughtItem}
            contentContainerStyle={styles.scrollContent}
            keyboardShouldPersistTaps="handled"
            keyboardDismissMode={
              Platform.OS === "ios" ? "interactive" : "on-drag"
            }
            ListHeaderComponent={
              <>
                <WizardProgress step={6} total={6} />
                <Text style={styles.title}>Outcome</Text>
                <Text style={styles.helper}>
                  Notice how your belief and emotions shift after working through
                  each thought.
                </Text>
                <View style={styles.progressRow}>
                  <Text style={styles.progressText}>
                    {completedCount} / {totalThoughts} thoughts completed
                  </Text>
                  {showIncompleteHint ? (
                    <Text style={styles.validationHint}>
                      Complete each thought to finish.
                    </Text>
                  ) : null}
                </View>
              </>
            }
            removeClippedSubviews
            initialNumToRender={4}
            windowSize={7}
          />

          <SafeAreaView edges={["bottom"]} style={styles.bottomBar}>
            <View style={styles.bottomActions}>
              <Pressable
                onPress={async () => {
                  await persistDraft();
                  navigation.goBack();
                }}
                style={({ pressed }) => [
                  styles.backButton,
                  pressed && styles.backButtonPressed
                ]}
              >
                <Text style={styles.backButtonText}>Back</Text>
              </Pressable>
              <PrimaryButton
                label="Save & Finish"
                disabled={!allComplete}
                onPress={handleFinish}
                onDisabledPress={handleFinish}
                style={styles.finishButton}
              />
            </View>
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
      marginBottom: 8,
      color: theme.textPrimary
    },
    helper: {
      fontSize: 13,
      color: theme.textSecondary,
      marginBottom: 12,
      lineHeight: 18
    },
    progressRow: {
      marginBottom: 8
    },
    progressText: {
      fontSize: 12,
      color: theme.textSecondary
    },
    validationHint: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: 6
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
    deltaText: {
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
    statusPillText: {
      fontSize: 10,
      color: theme.textSecondary
    },
    chevron: {
      fontSize: 18,
      color: theme.textSecondary,
      marginLeft: 4
    },
    section: {
      paddingTop: 10
    },
    sectionTitle: {
      fontSize: 14,
      color: theme.textPrimary,
      marginBottom: 8,
      lineHeight: 18
    },
    sectionDivider: {
      height: 1,
      backgroundColor: theme.border,
      marginTop: 12
    },
    sliderValue: {
      fontSize: 20,
      color: theme.textPrimary,
      fontWeight: "600",
      textAlign: "center",
      marginBottom: 4
    },
    referenceText: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: 6
    },
    helperMuted: {
      fontSize: 12,
      color: theme.textSecondary,
      marginBottom: 8
    },
    emotionBlock: {
      marginBottom: 10
    },
    emotionHeader: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    emotionLabel: {
      fontSize: 13,
      color: theme.textPrimary
    },
    emotionBefore: {
      fontSize: 11,
      color: theme.textSecondary
    },
    emotionValue: {
      fontSize: 16,
      color: theme.textPrimary,
      textAlign: "center",
      marginVertical: 4
    },
    reflectionInput: {
      minHeight: 70,
      maxHeight: 90,
      textAlignVertical: "top",
      borderWidth: 1,
      borderColor: theme.border,
      borderRadius: 8,
      padding: 10,
      backgroundColor: theme.card,
      color: theme.textPrimary
    },
    completeButton: {
      marginTop: 12
    },
    bottomBar: {
      paddingHorizontal: 16,
      paddingTop: 12,
      backgroundColor: theme.background,
      borderTopWidth: 1,
      borderTopColor: theme.border
    },
    bottomActions: {
      flexDirection: "row",
      alignItems: "center"
    },
    backButton: {
      borderWidth: 1,
      borderColor: theme.border,
      borderRadius: 8,
      paddingVertical: 12,
      paddingHorizontal: 16
    },
    backButtonPressed: {
      opacity: 0.85
    },
    backButtonText: {
      fontSize: 14,
      color: theme.textSecondary
    },
    finishButton: {
      flex: 1,
      marginLeft: 12
    }
  });
