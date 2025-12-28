import React, { useMemo } from "react";
import { StyleSheet, Text, View } from "react-native";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";
import { clampPercent } from "../utils/metrics";

type SlimMeterRowProps = {
  label: string;
  value: number;
  labelLines?: number;
  boldLabel?: boolean;
};

export const SlimMeterRow: React.FC<SlimMeterRowProps> = ({
  label,
  value,
  labelLines = 2,
  boldLabel = false
}) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const clamped = clampPercent(value);

  return (
    <View style={styles.row}>
      <Text
        style={[styles.label, boldLabel && styles.labelBold]}
        numberOfLines={labelLines}
      >
        {label}
      </Text>
      <View style={styles.barWrap}>
        <View style={styles.barTrack}>
          <View style={[styles.barFill, { width: `${clamped}%` }]} />
        </View>
      </View>
      <Text style={styles.value}>{clamped}%</Text>
    </View>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    row: {
      flexDirection: "row",
      alignItems: "center",
      paddingVertical: 6
    },
    label: {
      flex: 1.4,
      fontSize: 13,
      color: theme.textPrimary
    },
    labelBold: {
      fontSize: 14,
      fontWeight: "600"
    },
    barWrap: {
      flex: 1,
      marginHorizontal: 10
    },
    barTrack: {
      height: 7,
      borderRadius: 999,
      backgroundColor: theme.muted,
      overflow: "hidden"
    },
    barFill: {
      height: "100%",
      borderRadius: 999,
      backgroundColor: theme.accent
    },
    value: {
      width: 44,
      fontSize: 12,
      color: theme.textSecondary,
      textAlign: "right"
    }
  });
