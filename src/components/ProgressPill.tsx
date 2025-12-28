import React, { useMemo } from "react";
import { StyleSheet, Text, View } from "react-native";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

export type ProgressStatus = "complete" | "in_progress" | "incomplete";

type ProgressPillProps = {
  status: ProgressStatus;
  label?: string;
};

export const ProgressPill: React.FC<ProgressPillProps> = ({ status, label }) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const text =
    label ??
    (status === "complete"
      ? "Complete"
      : status === "in_progress"
      ? "In progress"
      : "Incomplete");

  return (
    <View
      style={[
        styles.container,
        status === "complete" && styles.complete,
        status === "in_progress" && styles.inProgress,
        status === "incomplete" && styles.incomplete
      ]}
    >
      <Text
        style={[
          styles.text,
          status === "complete" && styles.textComplete
        ]}
      >
        {text}
      </Text>
    </View>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      paddingHorizontal: 10,
      paddingVertical: 4,
      borderRadius: 999,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.muted
    },
    complete: {
      backgroundColor: theme.accent,
      borderColor: theme.accent
    },
    inProgress: {
      backgroundColor: theme.card
    },
    incomplete: {
      backgroundColor: theme.muted
    },
    text: {
      fontSize: 11,
      color: theme.textSecondary
    },
    textComplete: {
      color: theme.onAccent,
      fontWeight: "600"
    }
  });
