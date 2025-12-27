import React, { useMemo } from "react";
import { Pressable, StyleSheet, Text, ViewStyle, TextStyle } from "react-native";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

type PrimaryButtonProps = {
  label: string;
  onPress: () => void;
  disabled?: boolean;
  style?: ViewStyle;
  textStyle?: TextStyle;
};

export const PrimaryButton: React.FC<PrimaryButtonProps> = ({
  label,
  onPress,
  disabled,
  style,
  textStyle
}) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => [
        styles.button,
        disabled && styles.buttonDisabled,
        pressed && !disabled && styles.buttonPressed,
        style
      ]}
    >
      <Text style={[styles.text, disabled && styles.textDisabled, textStyle]}>
        {label}
      </Text>
    </Pressable>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    button: {
      backgroundColor: theme.accent,
      borderRadius: 10,
      alignItems: "center",
      paddingVertical: 14,
      width: "100%"
    },
    buttonPressed: {
      opacity: 0.9
    },
    buttonDisabled: {
      backgroundColor: theme.muted
    },
    text: {
      color: theme.onAccent,
      fontSize: 16
    },
    textDisabled: {
      color: theme.textSecondary
    }
  });
