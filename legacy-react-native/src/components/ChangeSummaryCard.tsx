import React, { useMemo } from "react";
import { StyleSheet, Text, View } from "react-native";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

type ChangeSummaryCardProps = {
  title: string;
  items: string[];
  emptyState?: string;
};

export const ChangeSummaryCard: React.FC<ChangeSummaryCardProps> = ({
  title,
  items,
  emptyState
}) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const content = items.length > 0 ? items : emptyState ? [emptyState] : [];
  if (content.length === 0) {
    return null;
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>{title}</Text>
      {content.map((item) => (
        <Text key={item} style={styles.item}>
          {item}
        </Text>
      ))}
    </View>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      borderWidth: 1,
      borderColor: theme.border,
      borderRadius: 16,
      padding: 14,
      backgroundColor: theme.card,
      marginBottom: 14
    },
    title: {
      fontSize: 12,
      color: theme.textSecondary,
      marginBottom: 8,
      textTransform: "uppercase",
      letterSpacing: 0.6
    },
    item: {
      fontSize: 13,
      color: theme.textPrimary,
      marginBottom: 6
    }
  });
