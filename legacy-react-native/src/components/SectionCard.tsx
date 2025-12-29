import React, { useMemo, useState } from "react";
import {
  LayoutAnimation,
  Pressable,
  StyleSheet,
  Text,
  View
} from "react-native";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

type SectionCardProps = {
  title: string;
  subtitle?: string;
  collapsible?: boolean;
  defaultExpanded?: boolean;
  rightAction?: React.ReactNode;
  children: React.ReactNode;
};

export const SectionCard: React.FC<SectionCardProps> = ({
  title,
  subtitle,
  collapsible = true,
  defaultExpanded = false,
  rightAction,
  children
}) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const [expanded, setExpanded] = useState(defaultExpanded || !collapsible);

  const toggle = () => {
    if (!collapsible) {
      return;
    }
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    setExpanded((current) => !current);
  };

  return (
    <View style={styles.container}>
      <Pressable
        accessibilityRole={collapsible ? "button" : undefined}
        accessibilityState={collapsible ? { expanded } : undefined}
        accessibilityLabel={`${title} section`}
        onPress={toggle}
        style={({ pressed }) => [
          styles.header,
          pressed && collapsible && styles.headerPressed
        ]}
      >
        <View style={styles.headerText}>
          <Text style={styles.title}>{title}</Text>
          {subtitle ? <Text style={styles.subtitle}>{subtitle}</Text> : null}
        </View>
        <View style={styles.headerActions}>
          {rightAction ? (
            <View style={styles.rightAction}>{rightAction}</View>
          ) : null}
          {collapsible ? (
            <Text style={[styles.chevron, expanded && styles.chevronExpanded]}>
              {">"}
            </Text>
          ) : null}
        </View>
      </Pressable>
      {expanded ? <View style={styles.body}>{children}</View> : null}
    </View>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.card,
      borderRadius: 16,
      marginBottom: 14,
      overflow: "hidden"
    },
    header: {
      paddingHorizontal: 16,
      paddingVertical: 14,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    headerPressed: {
      opacity: 0.85
    },
    headerText: {
      flex: 1,
      paddingRight: 12
    },
    title: {
      fontSize: 15,
      fontWeight: "600",
      color: theme.textPrimary
    },
    subtitle: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: 4
    },
    headerActions: {
      flexDirection: "row",
      alignItems: "center"
    },
    rightAction: {
      marginRight: 8
    },
    chevron: {
      fontSize: 16,
      color: theme.textSecondary,
      transform: [{ rotate: "0deg" }]
    },
    chevronExpanded: {
      transform: [{ rotate: "90deg" }]
    },
    body: {
      paddingHorizontal: 16,
      paddingBottom: 14,
      borderTopWidth: 1,
      borderTopColor: theme.border
    }
  });
