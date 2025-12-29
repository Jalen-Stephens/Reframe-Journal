import React, { useMemo } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useTheme } from "../context/ThemeProvider";
import { ThemePreference, ThemeTokens } from "../theme/theme";

const OPTIONS: Array<{
  label: string;
  value: ThemePreference;
  helper?: string;
}> = [
  {
    label: "System (Default)",
    value: "system",
    helper: "Matches your device setting"
  },
  { label: "Light", value: "light" },
  { label: "Dark", value: "dark" }
];

export const SettingsScreen = () => {
  const { theme, themePreference, setThemePreference } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Appearance</Text>
        <View style={styles.card}>
          {OPTIONS.map((option, index) => {
            const isSelected = themePreference === option.value;
            const showDivider = index < OPTIONS.length - 1;

            return (
              <Pressable
                key={option.value}
                style={[styles.optionRow, showDivider && styles.optionDivider]}
                onPress={() => setThemePreference(option.value)}
                accessibilityRole="radio"
                accessibilityState={{ selected: isSelected }}
                accessibilityLabel={option.label}
              >
                <View style={styles.optionContent}>
                  <View style={styles.optionText}>
                    <Text style={styles.optionLabel}>{option.label}</Text>
                    {option.helper ? (
                      <Text style={styles.optionHelper}>{option.helper}</Text>
                    ) : null}
                  </View>
                  <View
                    style={[
                      styles.radioOuter,
                      isSelected && styles.radioOuterSelected
                    ]}
                  >
                    {isSelected ? <View style={styles.radioInner} /> : null}
                  </View>
                </View>
              </Pressable>
            );
          })}
        </View>
      </View>
    </SafeAreaView>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.background
    },
    section: {
      padding: 16
    },
    sectionTitle: {
      fontSize: 14,
      color: theme.textSecondary,
      marginBottom: 10,
      letterSpacing: 0.3
    },
    card: {
      backgroundColor: theme.card,
      borderRadius: 12,
      borderWidth: 1,
      borderColor: theme.border,
      overflow: "hidden"
    },
    optionRow: {
      paddingVertical: 14,
      paddingHorizontal: 16
    },
    optionDivider: {
      borderBottomWidth: 1,
      borderBottomColor: theme.muted
    },
    optionContent: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    optionText: {
      flex: 1,
      paddingRight: 12
    },
    optionLabel: {
      fontSize: 15,
      color: theme.textPrimary
    },
    optionHelper: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: 4
    },
    radioOuter: {
      width: 22,
      height: 22,
      borderRadius: 11,
      borderWidth: 2,
      borderColor: theme.border,
      alignItems: "center",
      justifyContent: "center"
    },
    radioOuterSelected: {
      borderColor: theme.accent
    },
    radioInner: {
      width: 10,
      height: 10,
      borderRadius: 5,
      backgroundColor: theme.accent
    }
  });
