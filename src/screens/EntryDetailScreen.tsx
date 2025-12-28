import React, {
  useEffect,
  useLayoutEffect,
  useMemo,
  useState
} from "react";
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  Pressable,
  LayoutAnimation,
  Platform,
  UIManager
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { ThoughtRecord } from "../models/ThoughtRecord";
import { getThoughtRecordById } from "../storage/thoughtRecordsRepo";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";
import { formatRelativeDateTime } from "../utils/date";
import { PrimaryButton } from "../components/PrimaryButton";

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

type NormalizedPrompt = {
  key: string;
  questionLabel: string;
  responseText: string;
  beliefInResponse: number;
};

type NormalizedAdaptiveGroup = {
  thoughtId: string;
  thoughtText: string;
  originalBelief: number;
  prompts: NormalizedPrompt[];
};

type ChangeSummary = {
  beliefLabel?: string;
  emotionLabels: string[];
};

const PROMPTS = [
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

const formatCountLabel = (count: number, noun: string) => {
  if (count === 1) {
    return `1 ${noun}`;
  }
  return `${count} ${noun}s`;
};

const getStatusLabel = (record: ThoughtRecord) => {
  const hasThoughts = record.automaticThoughts.length > 0;
  const isComplete =
    hasThoughts &&
    record.automaticThoughts.every(
      (thought) => record.outcomesByThought?.[thought.id]?.isComplete
    );
  return {
    hasThoughts,
    isComplete,
    label: isComplete ? "Complete" : "Incomplete"
  };
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

const normalizeAdaptiveResponses = (
  record: ThoughtRecord
): NormalizedAdaptiveGroup[] =>
  record.automaticThoughts.map((thought) => {
    const responses = record.adaptiveResponses?.[thought.id];
    const prompts = PROMPTS.map((prompt) => {
      const responseText =
        (responses?.[prompt.textKey] as string | undefined) ?? "";
      const beliefInResponse =
        (responses?.[prompt.beliefKey] as number | undefined) ?? 0;
      return {
        key: prompt.key,
        questionLabel: prompt.label,
        responseText,
        beliefInResponse
      };
    });
    return {
      thoughtId: thought.id,
      thoughtText: thought.text.trim() || "Untitled thought",
      originalBelief: thought.beliefBefore ?? 0,
      prompts
    };
  });

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

const computeChangeSummary = (
  thoughts: NormalizedThought[],
  emotionsBefore: NormalizedEmotion[],
  beliefAfter?: number,
  emotionsAfter: NormalizedEmotion[] = []
): ChangeSummary => {
  const summary: ChangeSummary = { emotionLabels: [] };
  if (thoughts[0]?.belief !== undefined && beliefAfter !== undefined) {
    const before = thoughts[0].belief;
    const direction =
      beliefAfter === before ? "from" : beliefAfter < before ? "down from" : "up from";
    summary.beliefLabel = `Belief ${direction} ${before}% to ${beliefAfter}%`;
  }

  if (emotionsAfter.length === 0) {
    return summary;
  }

  const deltas = emotionsAfter
    .map((emotion) => {
      const before = emotionsBefore.find((item) => item.id === emotion.id);
      if (!before) {
        return null;
      }
      const diff = emotion.intensity - before.intensity;
      if (diff === 0) {
        return null;
      }
      return {
        label: emotion.label,
        before: before.intensity,
        after: emotion.intensity,
        diff
      };
    })
    .filter(
      (item): item is { label: string; before: number; after: number; diff: number } =>
        Boolean(item)
    )
    .sort((a, b) => Math.abs(b.diff) - Math.abs(a.diff))
    .slice(0, 2);

  summary.emotionLabels = deltas.map((delta) => {
    const direction = delta.diff < 0 ? "down" : "up";
    return `${delta.label} ${direction} from ${delta.before}% to ${delta.after}%`;
  });

  return summary;
};

export const EntryDetailScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "EntryDetail">
> = ({ route, navigation }) => {
  const [record, setRecord] = useState<ThoughtRecord | null>(null);
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const [expandedResponseId, setExpandedResponseId] = useState<string | null>(
    null
  );

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

  useEffect(() => {
    setExpandedResponseId(null);
  }, [record?.id]);

  if (!record) {
    return (
      <View style={styles.container}>
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  const situationTitle = record.situationText.trim() || "Untitled situation";
  const timeLabel = formatRelativeDateTime(record.createdAt);
  const status = getStatusLabel(record);
  const thoughts = normalizeThoughts(record);
  const emotionsBefore = normalizeEmotionsBefore(record);
  const adaptiveGroups = normalizeAdaptiveResponses(record);
  const mainThought = thoughts[0];
  const outcomeByThought = mainThought
    ? record.outcomesByThought?.[mainThought.id]
    : undefined;
  const beliefAfter =
    record.beliefAfterMainThought ?? outcomeByThought?.beliefAfter;
  const emotionsAfter = normalizeEmotionsAfter(record, mainThought?.id);
  const changeSummary = computeChangeSummary(
    thoughts,
    emotionsBefore,
    beliefAfter,
    emotionsAfter
  );

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
              styles.backButton,
              pressed && styles.backButtonPressed
            ]}
          >
            <Text style={styles.backButtonText}>Back</Text>
          </Pressable>
          <Text style={styles.headerTitle}>Entry</Text>
          <View style={styles.headerSpacer} />
        </View>

        <View style={styles.metaCard}>
          <Text style={styles.situationTitle} numberOfLines={1}>
            {situationTitle}
          </Text>
          <View style={styles.metaRow}>
            <Text style={styles.metaText}>{timeLabel}</Text>
            <StatusChip label={status.label} isComplete={status.isComplete} />
          </View>
        </View>

        <SectionCard title="Situation" collapsible={false}>
          <Text style={styles.sectionBodyText}>
            {record.situationText.trim().length > 0
              ? record.situationText
              : "No situation saved."}
          </Text>
        </SectionCard>

        <SectionCard
          title="Automatic Thoughts (Before)"
          subtitle={formatCountLabel(thoughts.length, "thought")}
          expandedByDefault
        >
          {thoughts.length === 0 ? (
            <Text style={styles.emptyText}>No automatic thoughts saved.</Text>
          ) : (
            thoughts.map((thought) => (
              <ThoughtChipCard key={thought.id} thought={thought} />
            ))
          )}
        </SectionCard>

        <SectionCard
          title="Emotions (Before)"
          subtitle={formatCountLabel(emotionsBefore.length, "emotion")}
          expandedByDefault
        >
          {emotionsBefore.length === 0 ? (
            <Text style={styles.emptyText}>No emotions saved.</Text>
          ) : (
            emotionsBefore.map((emotion) => (
              <EmotionRow key={emotion.id} emotion={emotion} />
            ))
          )}
        </SectionCard>

        <SectionCard
          title="Adaptive Responses"
          subtitle={formatCountLabel(adaptiveGroups.length, "thought")}
          expandedByDefault
        >
          {adaptiveGroups.length === 0 ? (
            <Text style={styles.emptyText}>No adaptive responses saved.</Text>
          ) : (
            adaptiveGroups.map((group) => {
              const completedCount = group.prompts.reduce((count, prompt) => {
                return count + (prompt.responseText.trim().length > 0 ? 1 : 0);
              }, 0);
              const isExpanded = expandedResponseId === group.thoughtId;
              const completionLabel = `${completedCount}/${
                group.prompts.length
              } completed`;
              return (
                <AccordionRow
                  key={group.thoughtId}
                  title={group.thoughtText}
                  subtitle={`Original ${group.originalBelief}%`}
                  meta={completionLabel}
                  isExpanded={isExpanded}
                  onToggle={() => {
                    LayoutAnimation.configureNext(
                      LayoutAnimation.Presets.easeInEaseOut
                    );
                    setExpandedResponseId((current) =>
                      current === group.thoughtId ? null : group.thoughtId
                    );
                  }}
                >
                  {group.prompts.map((prompt) => (
                    <View key={prompt.key} style={styles.promptBlock}>
                      <Text style={styles.promptLabel}>
                        {prompt.questionLabel}
                      </Text>
                      <View style={styles.responseCard}>
                        <Text style={styles.responseText}>
                          {prompt.responseText.trim().length > 0
                            ? prompt.responseText.trim()
                            : "No response saved."}
                        </Text>
                      </View>
                      <View style={styles.responseMetaRow}>
                        <Text style={styles.responseBeliefLabel}>
                          Belief in response
                        </Text>
                        <Text style={styles.responseBeliefValue}>
                          {prompt.beliefInResponse}%
                        </Text>
                      </View>
                      <ReadOnlyPercentBar value={prompt.beliefInResponse} />
                    </View>
                  ))}
                </AccordionRow>
              );
            })
          )}
        </SectionCard>

        <SectionCard title="Outcome (After)" expandedByDefault>
          <View style={styles.outcomeBlock}>
            <Text style={styles.outcomeLabel}>
              Belief in main thought (after)
            </Text>
            <Text style={styles.outcomeValue}>
              {beliefAfter !== undefined ? `${beliefAfter}%` : "Not recorded"}
            </Text>
            <ReadOnlyPercentBar value={beliefAfter ?? 0} />
          </View>

          <Text style={styles.subsectionTitle}>Emotions (After)</Text>
          {emotionsAfter.length === 0 ? (
            <Text style={styles.emptyText}>No emotions recorded.</Text>
          ) : (
            emotionsAfter.map((emotion) => (
              <EmotionRow key={emotion.id} emotion={emotion} />
            ))
          )}

          {changeSummary.beliefLabel ||
          changeSummary.emotionLabels.length > 0 ? (
            <View style={styles.changeSummaryCard}>
              <Text style={styles.changeSummaryTitle}>Change summary</Text>
              {changeSummary.beliefLabel ? (
                <Text style={styles.changeSummaryText}>
                  {changeSummary.beliefLabel}
                </Text>
              ) : null}
              {changeSummary.emotionLabels.map((label) => (
                <Text key={label} style={styles.changeSummaryText}>
                  {label}
                </Text>
              ))}
            </View>
          ) : null}
        </SectionCard>

        <View style={styles.actionsSection}>
          <PrimaryButton
            label="Done"
            accessibilityLabel="Done"
            onPress={() => navigation.goBack()}
          />
          <View style={styles.actionSpacer}>
            <PrimaryButton
              label="Edit (coming soon)"
              accessibilityLabel="Edit coming soon"
              onPress={() => {}}
              disabled
            />
          </View>
          <View style={styles.actionSpacer}>
            <PrimaryButton
              label="Export (coming soon)"
              accessibilityLabel="Export coming soon"
              onPress={() => {}}
              disabled
            />
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

type SectionCardProps = {
  title: string;
  subtitle?: string;
  collapsible?: boolean;
  expandedByDefault?: boolean;
  children: React.ReactNode;
};

const SectionCard: React.FC<SectionCardProps> = ({
  title,
  subtitle,
  collapsible = true,
  expandedByDefault = false,
  children
}) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const [expanded, setExpanded] = useState(expandedByDefault || !collapsible);

  useEffect(() => {
    if (!collapsible) {
      setExpanded(true);
    }
  }, [collapsible]);

  const toggle = () => {
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    setExpanded((current) => !current);
  };

  const headerContent = (
    <>
      <View style={styles.sectionHeaderText}>
        <Text style={styles.sectionTitle}>{title}</Text>
        {subtitle ? (
          <Text style={styles.sectionSubtitle}>{subtitle}</Text>
        ) : null}
      </View>
      {collapsible ? (
        <Text
          style={[
            styles.sectionChevron,
            expanded && styles.sectionChevronExpanded
          ]}
        >
          {">"}
        </Text>
      ) : null}
    </>
  );

  return (
    <View style={styles.sectionCard}>
      {collapsible ? (
        <Pressable
          accessibilityRole="button"
          accessibilityState={{ expanded }}
          accessibilityLabel={`${title} section`}
          onPress={toggle}
          style={({ pressed }) => [
            styles.sectionHeader,
            pressed && styles.sectionHeaderPressed
          ]}
        >
          {headerContent}
        </Pressable>
      ) : (
        <View style={styles.sectionHeader}>{headerContent}</View>
      )}
      {expanded ? <View style={styles.sectionBody}>{children}</View> : null}
    </View>
  );
};

type ThoughtChipCardProps = {
  thought: NormalizedThought;
  showBar?: boolean;
};

const ThoughtChipCard: React.FC<ThoughtChipCardProps> = ({
  thought,
  showBar = true
}) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  return (
    <View style={styles.thoughtCard}>
      <Text style={styles.thoughtQuote}>"{thought.text}"</Text>
      <View style={styles.thoughtMetaRow}>
        <Text style={styles.thoughtMetaLabel}>Belief</Text>
        <Text style={styles.thoughtMetaValue}>{thought.belief}%</Text>
      </View>
      {showBar ? <ReadOnlyPercentBar value={thought.belief} /> : null}
    </View>
  );
};

type EmotionRowProps = {
  emotion: NormalizedEmotion;
};

const EmotionRow: React.FC<EmotionRowProps> = ({ emotion }) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  return (
    <View style={styles.emotionRow}>
      <Text style={styles.emotionLabel} numberOfLines={1}>
        {emotion.label}
      </Text>
      <View style={styles.emotionBarWrap}>
        <ReadOnlyPercentBar value={emotion.intensity} />
      </View>
      <Text style={styles.emotionValue}>{emotion.intensity}%</Text>
    </View>
  );
};

type ReadOnlyPercentBarProps = {
  value: number;
};

const ReadOnlyPercentBar: React.FC<ReadOnlyPercentBarProps> = ({ value }) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const clamped = Math.max(0, Math.min(100, value));

  return (
    <View style={styles.percentBarTrack}>
      <View style={[styles.percentBarFill, { width: `${clamped}%` }]} />
    </View>
  );
};

type StatusChipProps = {
  label: string;
  isComplete: boolean;
};

const StatusChip: React.FC<StatusChipProps> = ({ label, isComplete }) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  return (
    <View
      style={[
        styles.statusChip,
        isComplete ? styles.statusChipComplete : styles.statusChipIncomplete
      ]}
    >
      <Text
        style={[
          styles.statusChipText,
          isComplete && styles.statusChipTextComplete
        ]}
      >
        {label}
      </Text>
    </View>
  );
};

type AccordionRowProps = {
  title: string;
  subtitle?: string;
  meta?: string;
  isExpanded: boolean;
  onToggle: () => void;
  children: React.ReactNode;
};

const AccordionRow: React.FC<AccordionRowProps> = ({
  title,
  subtitle,
  meta,
  isExpanded,
  onToggle,
  children
}) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  return (
    <View style={styles.accordionCard}>
      <Pressable
        accessibilityRole="button"
        accessibilityState={{ expanded: isExpanded }}
        accessibilityLabel={`${title} adaptive responses`}
        onPress={onToggle}
        style={({ pressed }) => [
          styles.accordionHeader,
          pressed && styles.accordionHeaderPressed
        ]}
      >
        <View style={styles.accordionHeaderText}>
          <Text style={styles.accordionTitle} numberOfLines={1}>
            {title}
          </Text>
          <View style={styles.accordionMetaRow}>
            {subtitle ? (
              <Text style={styles.accordionSubtitle}>{subtitle}</Text>
            ) : null}
            {meta ? <Text style={styles.accordionMeta}>{meta}</Text> : null}
          </View>
        </View>
        <Text
          style={[
            styles.accordionChevron,
            isExpanded && styles.accordionChevronExpanded
          ]}
        >
          {">"}
        </Text>
      </Pressable>
      {isExpanded ? <View style={styles.accordionBody}>{children}</View> : null}
    </View>
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
    backButton: {
      paddingVertical: 6,
      paddingHorizontal: 8,
      borderRadius: 8,
      backgroundColor: theme.card,
      borderWidth: 1,
      borderColor: theme.border
    },
    backButtonPressed: {
      opacity: 0.85
    },
    backButtonText: {
      color: theme.textPrimary,
      fontSize: 14,
      fontWeight: "600"
    },
    headerTitle: {
      fontSize: 16,
      fontWeight: "600",
      color: theme.textPrimary,
      textAlign: "center"
    },
    headerSpacer: {
      width: 58
    },
    metaCard: {
      padding: 14,
      borderRadius: 14,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.card,
      marginBottom: 16
    },
    situationTitle: {
      fontSize: 18,
      fontWeight: "600",
      color: theme.textPrimary,
      marginBottom: 6
    },
    metaRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    metaText: {
      fontSize: 12,
      color: theme.textSecondary
    },
    statusChip: {
      paddingHorizontal: 10,
      paddingVertical: 4,
      borderRadius: 999
    },
    statusChipComplete: {
      backgroundColor: theme.accent
    },
    statusChipIncomplete: {
      backgroundColor: theme.muted
    },
    statusChipText: {
      fontSize: 11,
      color: theme.textSecondary
    },
    statusChipTextComplete: {
      color: theme.onAccent,
      fontWeight: "600"
    },
    sectionCard: {
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.card,
      borderRadius: 14,
      marginBottom: 14,
      overflow: "hidden"
    },
    sectionHeader: {
      paddingHorizontal: 14,
      paddingTop: 14,
      paddingBottom: 12,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    sectionHeaderPressed: {
      opacity: 0.85
    },
    sectionHeaderText: {
      flex: 1,
      paddingRight: 12
    },
    sectionTitle: {
      fontSize: 15,
      fontWeight: "600",
      color: theme.textPrimary
    },
    sectionSubtitle: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: 4
    },
    sectionChevron: {
      fontSize: 16,
      color: theme.textSecondary,
      transform: [{ rotate: "0deg" }]
    },
    sectionChevronExpanded: {
      transform: [{ rotate: "90deg" }]
    },
    sectionBody: {
      paddingHorizontal: 14,
      paddingBottom: 14,
      borderTopWidth: 1,
      borderTopColor: theme.border
    },
    sectionBodyText: {
      fontSize: 14,
      color: theme.textPrimary,
      lineHeight: 20
    },
    emptyText: {
      fontSize: 13,
      color: theme.textSecondary,
      paddingVertical: 4
    },
    thoughtCard: {
      padding: 12,
      borderRadius: 12,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.background,
      marginBottom: 10
    },
    thoughtQuote: {
      fontSize: 14,
      fontStyle: "italic",
      color: theme.textPrimary,
      marginBottom: 8
    },
    thoughtMetaRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      marginBottom: 6
    },
    thoughtMetaLabel: {
      fontSize: 12,
      color: theme.textSecondary
    },
    thoughtMetaValue: {
      fontSize: 12,
      color: theme.textPrimary,
      fontWeight: "600"
    },
    emotionRow: {
      flexDirection: "row",
      alignItems: "center",
      marginBottom: 8
    },
    emotionLabel: {
      flex: 1,
      fontSize: 13,
      color: theme.textPrimary
    },
    emotionBarWrap: {
      flex: 2,
      marginHorizontal: 10
    },
    emotionValue: {
      width: 42,
      fontSize: 12,
      color: theme.textSecondary,
      textAlign: "right"
    },
    percentBarTrack: {
      height: 6,
      borderRadius: 999,
      backgroundColor: theme.muted,
      overflow: "hidden"
    },
    percentBarFill: {
      height: "100%",
      borderRadius: 999,
      backgroundColor: theme.accent
    },
    accordionCard: {
      borderWidth: 1,
      borderColor: theme.border,
      borderRadius: 12,
      backgroundColor: theme.background,
      marginBottom: 12,
      overflow: "hidden"
    },
    accordionHeader: {
      padding: 12,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    accordionHeaderPressed: {
      opacity: 0.85
    },
    accordionHeaderText: {
      flex: 1,
      paddingRight: 12
    },
    accordionTitle: {
      fontSize: 14,
      color: theme.textPrimary,
      fontWeight: "600"
    },
    accordionMetaRow: {
      flexDirection: "row",
      alignItems: "center",
      marginTop: 6
    },
    accordionSubtitle: {
      fontSize: 11,
      color: theme.textSecondary,
      marginRight: 8
    },
    accordionMeta: {
      fontSize: 11,
      color: theme.placeholder
    },
    accordionChevron: {
      fontSize: 16,
      color: theme.textSecondary,
      transform: [{ rotate: "0deg" }]
    },
    accordionChevronExpanded: {
      transform: [{ rotate: "90deg" }]
    },
    accordionBody: {
      paddingHorizontal: 12,
      paddingBottom: 12,
      borderTopWidth: 1,
      borderTopColor: theme.border
    },
    promptBlock: {
      marginTop: 12
    },
    promptLabel: {
      fontSize: 12,
      color: theme.textSecondary,
      marginBottom: 6
    },
    responseCard: {
      padding: 10,
      borderRadius: 10,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.card
    },
    responseText: {
      fontSize: 13,
      color: theme.textPrimary,
      lineHeight: 18
    },
    responseMetaRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      marginTop: 8,
      marginBottom: 6
    },
    responseBeliefLabel: {
      fontSize: 11,
      color: theme.textSecondary
    },
    responseBeliefValue: {
      fontSize: 11,
      color: theme.textPrimary,
      fontWeight: "600"
    },
    outcomeBlock: {
      marginBottom: 12
    },
    outcomeLabel: {
      fontSize: 13,
      color: theme.textSecondary,
      marginBottom: 6
    },
    outcomeValue: {
      fontSize: 24,
      fontWeight: "700",
      color: theme.textPrimary,
      marginBottom: 8
    },
    subsectionTitle: {
      fontSize: 13,
      color: theme.textSecondary,
      marginTop: 6,
      marginBottom: 8
    },
    changeSummaryCard: {
      marginTop: 12,
      padding: 12,
      borderRadius: 12,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.background
    },
    changeSummaryTitle: {
      fontSize: 12,
      color: theme.textSecondary,
      marginBottom: 6,
      textTransform: "uppercase"
    },
    changeSummaryText: {
      fontSize: 12,
      color: theme.textPrimary,
      marginBottom: 4
    },
    actionsSection: {
      marginTop: 8
    },
    actionSpacer: {
      marginTop: 10
    }
  });
