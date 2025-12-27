import React, { useMemo } from "react";
import { Text, Pressable, StyleSheet } from "react-native";
import { ThoughtRecord } from "../models/ThoughtRecord";
import { formatDateShort } from "../utils/date";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

export const EntryListItem: React.FC<{
  item: ThoughtRecord;
  onPress: () => void;
}> = ({ item, onPress }) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const topEmotion = item.emotions[0]?.label || "";
  const beliefChange =
    item.automaticThoughts[0] && item.beliefAfterMainThought !== undefined
      ? `${item.automaticThoughts[0].beliefBefore} → ${item.beliefAfterMainThought}`
      : "";

  return (
    <Pressable onPress={onPress} style={styles.container}>
      <Text style={styles.date}>{formatDateShort(item.createdAt)}</Text>
      {topEmotion ? <Text style={styles.meta}>{topEmotion}</Text> : null}
      {beliefChange ? <Text style={styles.meta}>{beliefChange}</Text> : null}
    </Pressable>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      paddingVertical: 12,
      borderBottomWidth: 1,
      borderBottomColor: theme.border
    },
    date: {
      fontSize: 16,
      color: theme.textPrimary
    },
    meta: {
      fontSize: 13,
      color: theme.textSecondary,
      marginTop: 4
    }
  });
