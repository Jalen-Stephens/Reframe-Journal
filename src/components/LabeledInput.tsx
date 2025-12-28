import React, { useMemo } from "react";
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  TextInputProps
} from "react-native";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

export const LabeledInput = React.forwardRef<TextInput, { label: string } & TextInputProps>(
  ({ label, style, placeholderTextColor, ...props }, ref) => {
    const { theme } = useTheme();
    const styles = useMemo(() => createStyles(theme), [theme]);

    return (
      <View style={styles.container}>
        <Text style={styles.label}>{label}</Text>
        <TextInput
          ref={ref}
          style={[styles.input, style]}
          placeholderTextColor={placeholderTextColor ?? theme.placeholder}
          {...props}
        />
      </View>
    );
  }
);

LabeledInput.displayName = "LabeledInput";

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
    input: {
      borderWidth: 1,
      borderColor: theme.border,
      padding: 10,
      borderRadius: 6,
      backgroundColor: theme.card,
      color: theme.textPrimary
    }
  });
