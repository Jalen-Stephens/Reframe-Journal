import React, { useMemo } from "react";
import { View, Text, Pressable, StyleSheet } from "react-native";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

type ThoughtCardProps = {
  text: string;
  belief: number;
  badgeLabel?: string;
  onEdit: () => void;
  onRemove: () => void;
};

export const ThoughtCard: React.FC<ThoughtCardProps> = ({
  text,
  belief,
  badgeLabel,
  onEdit,
  onRemove
}) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const label = badgeLabel ?? "Belief";

  return (
    <View style={styles.card}>
      <Text style={styles.text}>{text}</Text>
      <View style={styles.row}>
        <View style={styles.pill}>
          <Text style={styles.pillText}>
            {label} {belief}%
          </Text>
        </View>
        <View style={styles.actions}>
          <Pressable onPress={onEdit} hitSlop={8}>
            <Text style={styles.actionText}>Edit</Text>
          </Pressable>
          <Pressable onPress={onRemove} hitSlop={8} style={styles.actionSpacing}>
            <Text style={[styles.actionText, styles.removeText]}>Remove</Text>
          </Pressable>
        </View>
      </View>
    </View>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    card: {
      backgroundColor: theme.card,
      borderWidth: 1,
      borderColor: theme.border,
      borderRadius: 12,
      padding: 12,
      marginBottom: 12
    },
    text: {
      fontSize: 15,
      color: theme.textPrimary,
      marginBottom: 10
    },
    row: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    pill: {
      backgroundColor: theme.muted,
      borderRadius: 999,
      paddingVertical: 4,
      paddingHorizontal: 10
    },
    pillText: {
      fontSize: 12,
      color: theme.textSecondary
    },
    actions: {
      flexDirection: "row",
      alignItems: "center"
    },
    actionSpacing: {
      marginLeft: 16
    },
    actionText: {
      fontSize: 13,
      color: theme.accent
    },
    removeText: {
      color: theme.textSecondary
    }
  });
