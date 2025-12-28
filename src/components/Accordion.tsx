import React, { useMemo } from "react";
import {
  Pressable,
  StyleSheet,
  View,
  ViewStyle
} from "react-native";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

type AccordionProps = {
  header: React.ReactNode;
  isExpanded: boolean;
  onToggle: () => void;
  children: React.ReactNode;
  style?: ViewStyle;
};

export const Accordion: React.FC<AccordionProps> = ({
  header,
  isExpanded,
  onToggle,
  children,
  style
}) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  return (
    <View style={[styles.container, style]}>
      <Pressable
        accessibilityRole="button"
        onPress={onToggle}
        style={({ pressed }) => [
          styles.header,
          pressed && styles.headerPressed
        ]}
      >
        {header}
      </Pressable>
      {isExpanded ? <View style={styles.body}>{children}</View> : null}
    </View>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      borderWidth: 1,
      borderColor: theme.border,
      borderRadius: 12,
      backgroundColor: theme.card,
      overflow: "hidden",
      marginBottom: 12
    },
    header: {
      padding: 14
    },
    headerPressed: {
      opacity: 0.85
    },
    body: {
      paddingHorizontal: 14,
      paddingBottom: 14,
      borderTopWidth: 1,
      borderTopColor: theme.border
    }
  });
