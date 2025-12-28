import React, { useEffect, useLayoutEffect, useMemo, useState } from "react";
import {
  FlatList,
  Platform,
  Pressable,
  Modal,
  ScrollView,
  StyleSheet,
  Text,
  UIManager,
  View
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { ThoughtRecord } from "../models/ThoughtRecord";
import { getThoughtRecordById } from "../storage/thoughtRecordsRepo";
import { useTheme } from "../context/ThemeProvider";
import { useWizard } from "../context/WizardContext";
import { ThemeTokens } from "../theme/theme";
import { PrimaryButton } from "../components/PrimaryButton";
import { SectionCard } from "../components/SectionCard";
import { ProgressPill, ProgressStatus } from "../components/ProgressPill";
import { SlimMeterRow } from "../components/SlimMeterRow";
import { ChangeSummaryCard } from "../components/ChangeSummaryCard";
import { ExpandableText } from "../components/ExpandableText";
import { ADAPTIVE_PROMPTS } from "../utils/adaptivePrompts";
import { clampPercent } from "../utils/metrics";

type NormalizedThought = {
  id: string;
  text: string;
  belief: number;
};

type NormalizedEmotion = {
  id: string;
  label: string;
  intensity: number;
};

type AdaptiveSummary = {
  thoughtId: string;
  thoughtText: string;
  originalBelief: number;
  completedCount: number;
  totalCount: number;
};

type OutcomeDeltas = {
  belief?: { before: number; after: number };
  emotions: Array<{ label: string; before: number; after: number; delta: number }>;
};

const formatRelativeDate = (iso: string): string => {
  const date = new Date(iso);
  const now = new Date();
  const startOfToday = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate()
  );
  const startOfYesterday = new Date(startOfToday);
  startOfYesterday.setDate(startOfToday.getDate() - 1);

  let label = date.toLocaleDateString();
  if (date >= startOfToday) {
    label = "Today";
  } else if (date >= startOfYesterday) {
    label = "Yesterday";
  }

  const time = date.toLocaleTimeString([], {
    hour: "numeric",
    minute: "2-digit"
  });

  return `${label} · ${time}`;
};

const computeOutcomeDeltas = (record: ThoughtRecord): OutcomeDeltas => {
  const mainThought = record.automaticThoughts[0];
  const outcome = mainThought ? record.outcomesByThought?.[mainThought.id] : undefined;
  const beliefBefore = mainThought?.beliefBefore;
  const beliefAfter = record.beliefAfterMainThought ?? outcome?.beliefAfter;

  const belief =
    typeof beliefBefore === "number" && typeof beliefAfter === "number"
      ? { before: beliefBefore, after: beliefAfter }
      : undefined;

  if (!outcome?.emotionsAfter) {
    return { belief, emotions: [] };
  }

  const beforeByLabel = new Map<string, number>();
  const afterByLabel = new Map<string, number>();

  record.emotions.forEach((emotion) => {
    const label = emotion.label.trim() || "Untitled emotion";
    const key = label.toLowerCase();
    beforeByLabel.set(key, emotion.intensityBefore ?? 0);
    const after = outcome.emotionsAfter?.[emotion.id];
    if (typeof after === "number") {
      afterByLabel.set(key, after);
    }
  });

  const emotions = Array.from(afterByLabel.entries())
    .map(([key, after]) => {
      const before = beforeByLabel.get(key);
      if (typeof before !== "number") {
        return null;
      }
      const delta = after - before;
      if (before === after) {
        return null;
      }
      const label =
        record.emotions.find(
          (emotion) => (emotion.label.trim() || "Untitled emotion").toLowerCase() === key
        )?.label.trim() || "Untitled emotion";
      return {
        label,
        before,
        after,
        delta
      };
    })
    .filter(
      (item): item is { label: string; before: number; after: number; delta: number } =>
        Boolean(item)
    )
    .sort((a, b) => Math.abs(b.delta) - Math.abs(a.delta));

  return { belief, emotions };
};

const getStatus = (record: ThoughtRecord): ProgressStatus => {
  const hasThoughts = record.automaticThoughts.length > 0;
  if (!hasThoughts) {
    return "in_progress";
  }
  const isComplete = record.automaticThoughts.every(
    (thought) => record.outcomesByThought?.[thought.id]?.isComplete
  );
  return isComplete ? "complete" : "in_progress";
};

const normalizeThoughts = (record: ThoughtRecord): NormalizedThought[] =>
  record.automaticThoughts.map((thought) => ({
    id: thought.id,
    text: thought.text.trim() || "Untitled thought",
    belief: thought.beliefBefore ?? 0
  }));

const normalizeEmotionsBefore = (record: ThoughtRecord): NormalizedEmotion[] =>
  record.emotions.map((emotion) => ({
    id: emotion.id,
    label: emotion.label.trim() || "Untitled emotion",
    intensity: emotion.intensityBefore ?? 0
  }));

const normalizeEmotionsAfter = (
  record: ThoughtRecord,
  thoughtId?: string
): NormalizedEmotion[] => {
  if (!thoughtId) {
    return [];
  }
  const outcome = record.outcomesByThought?.[thoughtId];
  if (!outcome?.emotionsAfter) {
    return [];
  }
  return record.emotions
    .map((emotion) => {
      const intensity = outcome.emotionsAfter?.[emotion.id];
      if (typeof intensity !== "number") {
        return null;
      }
      return {
        id: emotion.id,
        label: emotion.label.trim() || "Untitled emotion",
        intensity
      };
    })
    .filter((item): item is NormalizedEmotion => Boolean(item));
};

const normalizeAdaptiveSummaries = (record: ThoughtRecord): AdaptiveSummary[] =>
  record.automaticThoughts.map((thought) => {
    const responses = record.adaptiveResponses?.[thought.id];
    const completedCount = ADAPTIVE_PROMPTS.reduce((count, prompt) => {
      const responseText = (responses?.[prompt.textKey] as string | undefined) ?? "";
      return count + (responseText.trim().length > 0 ? 1 : 0);
    }, 0);

    return {
      thoughtId: thought.id,
      thoughtText: thought.text.trim() || "Untitled thought",
      originalBelief: thought.beliefBefore ?? 0,
      completedCount,
      totalCount: ADAPTIVE_PROMPTS.length
    };
  });

export const EntryDetailScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "EntryDetail">
> = ({ route, navigation }) => {
  const [record, setRecord] = useState<ThoughtRecord | null>(null);
  const [isEditMenuOpen, setIsEditMenuOpen] = useState(false);
  const { theme } = useTheme();
  const { setDraft, persistDraft, setIsEditing } = useWizard();
  const styles = useMemo(() => createStyles(theme), [theme]);

  useEffect(() => {
    getThoughtRecordById(route.params.id).then(setRecord);
  }, [route.params.id]);

  useEffect(() => {
    if (Platform.OS === "android") {
      UIManager.setLayoutAnimationEnabledExperimental?.(true);
    }
  }, []);

  useLayoutEffect(() => {
    navigation.setOptions({ headerShown: false });
  }, [navigation]);

  if (!record) {
    return (
      <View style={styles.container}>
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  const situationTitle = record.situationText.trim() || "Untitled situation";
  const timeLabel = formatRelativeDate(record.createdAt);
  const status = getStatus(record);
  const thoughts = normalizeThoughts(record);
  const emotionsBefore = normalizeEmotionsBefore(record);
  const adaptiveSummaries = normalizeAdaptiveSummaries(record);
  const mainThought = thoughts[0];
  const outcomeByThought = mainThought
    ? record.outcomesByThought?.[mainThought.id]
    : undefined;
  const beliefAfter =
    record.beliefAfterMainThought ?? outcomeByThought?.beliefAfter;
  const emotionsAfter = normalizeEmotionsAfter(record, mainThought?.id);
  const deltas = computeOutcomeDeltas(record);

  const changeItems = [
    deltas.belief
      ? `Belief: ${deltas.belief.before}% -> ${deltas.belief.after}%`
      : null,
    ...deltas.emotions.slice(0, 3).map((item) => {
      return `${item.label}: ${item.before}% -> ${item.after}%`;
    })
  ].filter((item): item is string => Boolean(item));

  const beforeSummaryItems = [
    mainThought
      ? `Main thought before: ${clampPercent(mainThought.belief)}%`
      : null,
    thoughts.length > 0 ? `Thoughts recorded: ${thoughts.length}` : null,
    emotionsBefore.length > 0 ? `Emotions noted: ${emotionsBefore.length}` : null
  ].filter((item): item is string => Boolean(item));

  const editSections = [
    { label: "Date & time", screen: "WizardStep1" as const },
    { label: "Situation", screen: "WizardStep2" as const },
    { label: "Automatic thoughts", screen: "WizardStep3" as const },
    { label: "Emotions", screen: "WizardStep4" as const },
    { label: "Adaptive responses", screen: "WizardStep6" as const },
    { label: "Outcome", screen: "WizardStep7" as const }
  ];

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Go back"
            onPress={() => navigation.goBack()}
            style={({ pressed }) => [
              styles.iconButton,
              pressed && styles.iconButtonPressed
            ]}
          >
            <Text style={styles.iconButtonText}>Back</Text>
          </Pressable>
          <Text style={styles.headerTitle}>Entry</Text>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="More options"
            onPress={() => setIsEditMenuOpen(true)}
            style={({ pressed }) => [
              styles.iconButton,
              pressed && styles.iconButtonPressed
            ]}
          >
            <Text style={styles.iconButtonText}>More</Text>
          </Pressable>
        </View>

        <View style={styles.contextCard}>
          <ExpandableText
            text={situationTitle}
            numberOfLines={2}
            textStyle={styles.situationTitle}
            accessibilityLabel="Situation"
          />
          <View style={styles.metaRow}>
            <Text style={styles.metaText}>{timeLabel}</Text>
            <ProgressPill status={status} />
          </View>
        </View>

            <View style={styles.outcomeCard}>
              <View style={styles.outcomeHeader}>
                <Text style={styles.outcomeTitle}>Outcome</Text>
                <Text style={styles.outcomeSubtitle}>Belief in main thought</Text>
              </View>
              <Text style={styles.outcomeValue}>
                {beliefAfter !== undefined
                  ? `${clampPercent(beliefAfter)}%`
                  : "Not recorded"}
              </Text>
              {emotionsAfter.length > 0 ? (
                <View style={styles.outcomeEmotions}>
                  {emotionsAfter.map((emotion) => (
                    <SlimMeterRow
                      key={emotion.id}
                      label={emotion.label}
                      value={emotion.intensity}
                      labelLines={1}
                    />
                  ))}
                </View>
              ) : (
                <Text style={styles.emptyText}>No emotions recorded after.</Text>
              )}
            </View>

            <ChangeSummaryCard
              title={changeItems.length > 0 ? "You made progress" : "What changed"}
              items={changeItems}
              emptyState="No changes recorded yet."
            />

            <View style={styles.beforeCard}>
              <Text style={styles.beforeTitle}>Before snapshot</Text>
              {beforeSummaryItems.length > 0 ? (
                beforeSummaryItems.map((item) => (
                  <Text key={item} style={styles.beforeItem}>
                    {item}
                  </Text>
                ))
              ) : (
                <Text style={styles.emptyText}>No before details saved.</Text>
              )}
            </View>

            <SectionCard
              title="Automatic thoughts at the time"
              subtitle="How true these felt in the moment"
              collapsible
            >
              {thoughts.length === 0 ? (
                <Text style={styles.emptyText}>No automatic thoughts saved.</Text>
              ) : (
                <FlatList
                  data={thoughts}
                  keyExtractor={(item) => item.id}
                  scrollEnabled={false}
                  renderItem={({ item }) => (
                    <SlimMeterRow
                      label={item.text}
                      value={item.belief}
                      boldLabel
                    />
                  )}
                />
              )}
            </SectionCard>

            <SectionCard title="Emotions you noticed" collapsible>
              {emotionsBefore.length === 0 ? (
                <Text style={styles.emptyText}>No emotions saved.</Text>
              ) : (
                <FlatList
                  data={emotionsBefore}
                  keyExtractor={(item) => item.id}
                  scrollEnabled={false}
                  renderItem={({ item }) => (
                    <SlimMeterRow
                      label={item.label}
                      value={item.intensity}
                      labelLines={1}
                    />
                  )}
                />
              )}
            </SectionCard>

            <SectionCard
              title="Adaptive responses"
              subtitle="Reframing work you completed"
              collapsible
            >
              {adaptiveSummaries.length === 0 ? (
                <Text style={styles.emptyText}>No adaptive responses saved.</Text>
              ) : (
                <FlatList
                  data={adaptiveSummaries}
                  keyExtractor={(item) => item.thoughtId}
                  scrollEnabled={false}
                  renderItem={({ item }) => {
                    const isComplete = item.completedCount === item.totalCount;
                    const progressLabel = `${item.completedCount}/${item.totalCount}`;
                    return (
                      <Pressable
                        accessibilityRole="button"
                        accessibilityLabel={`View adaptive responses for ${item.thoughtText}`}
                        onPress={() =>
                          navigation.navigate("ThoughtResponseDetail", {
                            entryId: record.id,
                            thoughtId: item.thoughtId
                          })
                        }
                        style={({ pressed }) => [
                          styles.responseRow,
                          pressed && styles.responseRowPressed
                        ]}
                      >
                        <View style={styles.responseTextBlock}>
                          <Text style={styles.responseThought} numberOfLines={2}>
                            {item.thoughtText}
                          </Text>
                          <Text style={styles.responseMeta}>
                            Original {item.originalBelief}%
                          </Text>
                        </View>
                        <View style={styles.responseRight}>
                          {isComplete ? (
                            <ProgressPill status="complete" label="Complete" />
                          ) : (
                            <Text style={styles.responseProgress}>{progressLabel}</Text>
                          )}
                          <Text style={styles.responseChevron}>{">"}</Text>
                        </View>
                      </Pressable>
                    );
                  }}
                />
              )}
            </SectionCard>

        <View style={styles.actionsSection}>
          <PrimaryButton
            label="Done"
            accessibilityLabel="Done"
            onPress={() => navigation.goBack()}
          />
        </View>
        <Modal
          visible={isEditMenuOpen}
          transparent
          animationType="fade"
          onRequestClose={() => setIsEditMenuOpen(false)}
        >
          <Pressable
            style={styles.modalBackdrop}
            onPress={() => setIsEditMenuOpen(false)}
          >
            <Pressable style={styles.modalCard} onPress={() => {}}>
              <Text style={styles.modalTitle}>Edit entry</Text>
              {editSections.map((item) => (
                <Pressable
                  key={item.screen}
                  accessibilityRole="button"
                  accessibilityLabel={`Edit ${item.label}`}
                  onPress={async () => {
                    setDraft(record);
                    setIsEditing(true);
                    await persistDraft(record);
                    setIsEditMenuOpen(false);
                    navigation.navigate(item.screen);
                  }}
                  style={({ pressed }) => [
                    styles.modalRow,
                    pressed && styles.modalRowPressed
                  ]}
                >
                  <Text style={styles.modalRowText}>{item.label}</Text>
                  <Text style={styles.modalRowChevron}>{">"}</Text>
                </Pressable>
              ))}
              <Pressable
                accessibilityRole="button"
                accessibilityLabel="Close"
                onPress={() => setIsEditMenuOpen(false)}
                style={({ pressed }) => [
                  styles.modalCancel,
                  pressed && styles.modalRowPressed
                ]}
              >
                <Text style={styles.modalCancelText}>Cancel</Text>
              </Pressable>
            </Pressable>
          </Pressable>
        </Modal>
      </ScrollView>
    </SafeAreaView>
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
      paddingBottom: 32
    },
    loadingText: {
      color: theme.textSecondary
    },
    header: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 12
    },
    iconButton: {
      paddingVertical: 6,
      paddingHorizontal: 10,
      borderRadius: 10,
      backgroundColor: theme.card,
      borderWidth: 1,
      borderColor: theme.border
    },
    iconButtonPressed: {
      opacity: 0.85
    },
    iconButtonText: {
      color: theme.textPrimary,
      fontSize: 13,
      fontWeight: "600"
    },
    headerTitle: {
      fontSize: 16,
      fontWeight: "600",
      color: theme.textPrimary,
      textAlign: "center"
    },
    contextCard: {
      padding: 16,
      borderRadius: 18,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.card,
      marginBottom: 14
    },
    situationTitle: {
      fontSize: 18,
      fontWeight: "600",
      color: theme.textPrimary
    },
    metaRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginTop: 10
    },
    metaText: {
      fontSize: 12,
      color: theme.textSecondary
    },
    outcomeCard: {
      padding: 16,
      borderRadius: 18,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.card,
      marginBottom: 14
    },
    outcomeHeader: {
      marginBottom: 10
    },
    outcomeTitle: {
      fontSize: 14,
      fontWeight: "600",
      color: theme.textPrimary
    },
    outcomeSubtitle: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: 4
    },
    outcomeValue: {
      fontSize: 30,
      fontWeight: "700",
      color: theme.textPrimary,
      marginBottom: 10
    },
    outcomeEmotions: {
      borderTopWidth: 1,
      borderTopColor: theme.border,
      paddingTop: 10
    },
    beforeCard: {
      padding: 14,
      borderRadius: 16,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.card,
      marginBottom: 14
    },
    beforeTitle: {
      fontSize: 12,
      color: theme.textSecondary,
      marginBottom: 8,
      textTransform: "uppercase",
      letterSpacing: 0.5
    },
    beforeItem: {
      fontSize: 13,
      color: theme.textPrimary,
      marginBottom: 6
    },
    emptyText: {
      fontSize: 13,
      color: theme.textSecondary,
      paddingVertical: 4
    },
    responseRow: {
      paddingVertical: 10,
      borderBottomWidth: 1,
      borderBottomColor: theme.border,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    responseRowPressed: {
      opacity: 0.85
    },
    responseTextBlock: {
      flex: 1,
      paddingRight: 12
    },
    responseThought: {
      fontSize: 14,
      fontWeight: "600",
      color: theme.textPrimary
    },
    responseMeta: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: 6
    },
    responseRight: {
      flexDirection: "row",
      alignItems: "center"
    },
    responseProgress: {
      fontSize: 12,
      color: theme.textSecondary,
      marginRight: 8
    },
    responseChevron: {
      fontSize: 16,
      color: theme.textSecondary
    },
    actionsSection: {
      marginTop: 8
    },
    modalBackdrop: {
      flex: 1,
      backgroundColor: "rgba(0, 0, 0, 0.6)",
      alignItems: "center",
      justifyContent: "flex-end",
      padding: 16
    },
    modalCard: {
      width: "100%",
      borderRadius: 18,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.card,
      padding: 16
    },
    modalTitle: {
      fontSize: 14,
      fontWeight: "600",
      color: theme.textPrimary,
      marginBottom: 12
    },
    modalRow: {
      paddingVertical: 12,
      borderBottomWidth: 1,
      borderBottomColor: theme.border,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    modalRowPressed: {
      opacity: 0.85
    },
    modalRowText: {
      fontSize: 14,
      color: theme.textPrimary
    },
    modalRowChevron: {
      fontSize: 16,
      color: theme.textSecondary
    },
    modalCancel: {
      marginTop: 12,
      paddingVertical: 12,
      borderRadius: 12,
      borderWidth: 1,
      borderColor: theme.border,
      alignItems: "center"
    },
    modalCancelText: {
      fontSize: 14,
      color: theme.textSecondary
    }
  });
