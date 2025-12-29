import React, { useMemo } from "react";
import { Text, Pressable, StyleSheet, View } from "react-native";
import { ThoughtRecord } from "../models/ThoughtRecord";
import { formatRelativeDateTime } from "../utils/date";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

export const EntryListItem: React.FC<{
  item: ThoughtRecord;
  onPress: () => void;
}> = ({ item, onPress }) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const situation = item.situationText?.trim() || "Untitled situation";
  const emotionSummary =
    item.emotions.length > 0
      ? item.emotions.map((emotion) => emotion.label).join(" · ")
      : "Emotions not noted";
  const hasThoughts = item.automaticThoughts.length > 0;
  const isComplete =
    hasThoughts &&
    item.automaticThoughts.every(
      (thought) => item.outcomesByThought?.[thought.id]?.isComplete
    );
  const statusLabel = hasThoughts ? (isComplete ? "Complete" : "In progress") : "";
  const beliefBefore = item.automaticThoughts[0]?.beliefBefore;
  const beliefAfter = item.beliefAfterMainThought;
  const beliefDelta =
    isComplete && beliefBefore !== undefined && beliefAfter !== undefined
      ? Math.round(beliefBefore - beliefAfter)
      : null;
  const beliefChangeLabel =
    beliefDelta && beliefDelta > 0 ? `Belief ↓ ${beliefDelta}%` : "";

  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.container,
        pressed && styles.containerPressed
      ]}
    >
      <View style={styles.titleRow}>
        <Text style={styles.title} numberOfLines={1}>
          {situation}
        </Text>
        {statusLabel ? (
          <View style={styles.statusPill}>
            <Text style={styles.statusText}>{statusLabel}</Text>
          </View>
        ) : null}
      </View>
      <Text style={styles.emotion} numberOfLines={1}>
        {emotionSummary}
      </Text>
      <View style={styles.metaRow}>
        <Text style={styles.meta}>{formatRelativeDateTime(item.createdAt)}</Text>
        {beliefChangeLabel ? (
          <Text style={styles.meta}>{beliefChangeLabel}</Text>
        ) : null}
      </View>
    </Pressable>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      paddingVertical: 14,
      paddingHorizontal: 14,
      borderRadius: 14,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.card,
      marginBottom: 12
    },
    containerPressed: {
      opacity: 0.85
    },
    titleRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    title: {
      flex: 1,
      fontSize: 16,
      fontWeight: "600",
      color: theme.textPrimary
    },
    statusPill: {
      paddingHorizontal: 10,
      paddingVertical: 4,
      borderRadius: 999,
      backgroundColor: theme.muted,
      marginLeft: 8
    },
    statusText: {
      fontSize: 11,
      color: theme.textSecondary
    },
    emotion: {
      fontSize: 13,
      color: theme.textSecondary,
      marginTop: 6
    },
    metaRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginTop: 8
    },
    meta: {
      fontSize: 12,
      color: theme.placeholder
    }
  });
