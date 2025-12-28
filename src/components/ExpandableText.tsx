import React, { useMemo, useState } from "react";
import {
  Pressable,
  StyleSheet,
  Text,
  TextStyle,
  View
} from "react-native";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

type ExpandableTextProps = {
  text: string;
  numberOfLines?: number;
  placeholder?: string;
  textStyle?: TextStyle;
  accessibilityLabel?: string;
};

export const ExpandableText: React.FC<ExpandableTextProps> = ({
  text,
  numberOfLines = 2,
  placeholder = "No details saved.",
  textStyle,
  accessibilityLabel
}) => {
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const [expanded, setExpanded] = useState(false);
  const [isTruncated, setIsTruncated] = useState(false);
  const content = text.trim().length > 0 ? text.trim() : placeholder;

  return (
    <View>
      <Text
        style={[styles.text, textStyle]}
        numberOfLines={expanded ? undefined : numberOfLines}
        onTextLayout={(event) => {
          if (
            event.nativeEvent.lines.length > numberOfLines &&
            !isTruncated
          ) {
            setIsTruncated(true);
          }
        }}
        accessibilityLabel={accessibilityLabel}
      >
        {content}
      </Text>
      {isTruncated ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={expanded ? "Show less" : "Show more"}
          onPress={() => setExpanded((current) => !current)}
          style={({ pressed }) => [
            styles.moreButton,
            pressed && styles.moreButtonPressed
          ]}
        >
          <Text style={styles.moreText}>{expanded ? "Show less" : "Show more"}</Text>
        </Pressable>
      ) : null}
    </View>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    text: {
      color: theme.textPrimary,
      fontSize: 14,
      lineHeight: 20
    },
    moreButton: {
      alignSelf: "flex-start",
      marginTop: 6,
      paddingVertical: 4,
      paddingHorizontal: 6,
      borderRadius: 6,
      backgroundColor: theme.muted
    },
    moreButtonPressed: {
      opacity: 0.85
    },
    moreText: {
      fontSize: 12,
      color: theme.textSecondary
    }
  });
