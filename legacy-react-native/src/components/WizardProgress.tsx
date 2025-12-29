import React, { useMemo } from "react";
import { View, Text, StyleSheet } from "react-native";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

export const WizardProgress: React.FC<{ step: number; total: number }> = ({
  step,
  total
}) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  return (
    <View style={styles.container}>
      <Text style={styles.text}>{`Step ${step} of ${total}`}</Text>
      <View style={styles.track}>
        <View style={[styles.fill, { width: `${(step / total) * 100}%` }]} />
      </View>
    </View>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      marginBottom: 16
    },
    text: {
      fontSize: 14,
      color: theme.textSecondary,
      marginBottom: 8
    },
    track: {
      height: 4,
      backgroundColor: theme.muted,
      borderRadius: 2
    },
    fill: {
      height: 4,
      backgroundColor: theme.accent,
      borderRadius: 2
    }
  });
