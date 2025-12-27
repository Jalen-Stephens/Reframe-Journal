import React, { useMemo } from "react";
import { View, Text, StyleSheet } from "react-native";
import Slider from "@react-native-community/slider";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

export const LabeledSlider: React.FC<{
  label: string;
  value: number;
  onChange: (value: number) => void;
}> = ({ label, value, onChange }) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  return (
    <View style={styles.container}>
      <Text style={styles.label}>{label}</Text>
      <Slider
        minimumValue={0}
        maximumValue={100}
        step={1}
        value={value}
        onValueChange={onChange}
        minimumTrackTintColor={theme.accent}
        maximumTrackTintColor={theme.muted}
        thumbTintColor={theme.accent}
      />
      <Text style={styles.value}>{value}</Text>
    </View>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      marginBottom: 16
    },
    label: {
      fontSize: 14,
      color: theme.textSecondary,
      marginBottom: 6
    },
    value: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: 6
    }
  });
