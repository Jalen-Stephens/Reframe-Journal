import React, { useEffect, useLayoutEffect, useMemo, useState } from "react";
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View
} from "react-native";
import Slider from "@react-native-community/slider";
import { SafeAreaView } from "react-native-safe-area-context";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { ThoughtRecord } from "../models/ThoughtRecord";
import { getThoughtRecordById } from "../storage/thoughtRecordsRepo";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";
import { ADAPTIVE_PROMPTS } from "../utils/adaptivePrompts";
import { clampPercent } from "../utils/metrics";
import { ExpandableText } from "../components/ExpandableText";

export const ThoughtResponseDetailScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "ThoughtResponseDetail">
> = ({ route, navigation }) => {
  const { entryId, thoughtId } = route.params;
  const [record, setRecord] = useState<ThoughtRecord | null>(null);
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  useEffect(() => {
    getThoughtRecordById(entryId).then(setRecord);
  }, [entryId]);

  useLayoutEffect(() => {
    navigation.setOptions({ headerShown: false });
  }, [navigation]);

  if (!record) {
    return (
      <View style={styles.container}>
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  const thought = record.automaticThoughts.find((item) => item.id === thoughtId);
  const responses = record.adaptiveResponses?.[thoughtId];

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.header}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Go back"
            onPress={() => navigation.goBack()}
            style={({ pressed }) => [
              styles.iconButton,
              pressed && styles.iconButtonPressed
            ]}
          >
            <Text style={styles.iconButtonText}>Back</Text>
          </Pressable>
          <Text style={styles.headerTitle}>Adaptive responses</Text>
          <View style={styles.headerSpacer} />
        </View>

        <View style={styles.thoughtCard}>
          <Text style={styles.thoughtLabel}>Thought</Text>
          <ExpandableText
            text={thought?.text ?? "Untitled thought"}
            numberOfLines={2}
            textStyle={styles.thoughtText}
          />
          <Text style={styles.thoughtMeta}>
            Original belief: {clampPercent(thought?.beliefBefore ?? 0)}%
          </Text>
        </View>

        {ADAPTIVE_PROMPTS.map((prompt, index) => {
          const responseText =
            (responses?.[prompt.textKey] as string | undefined) ?? "";
          const beliefValue =
            (responses?.[prompt.beliefKey] as number | undefined) ?? 0;
          return (
            <View key={prompt.key} style={styles.stepCard}>
              <View style={styles.stepIndex}>
                <Text style={styles.stepIndexText}>{index + 1}</Text>
              </View>
              <View style={styles.stepBody}>
                <Text style={styles.stepTitle}>{prompt.label}</Text>
                <View style={styles.responseCard}>
                  <ExpandableText
                    text={responseText}
                    numberOfLines={3}
                    placeholder="No response saved."
                    textStyle={styles.responseText}
                  />
                </View>
                <View style={styles.sliderHeader}>
                  <Text style={styles.sliderLabel}>Belief in this response</Text>
                  <Text style={styles.sliderValue}>
                    {clampPercent(beliefValue)}%
                  </Text>
                </View>
                <Slider
                  minimumValue={0}
                  maximumValue={100}
                  step={1}
                  value={clampPercent(beliefValue)}
                  disabled
                  minimumTrackTintColor={theme.accent}
                  maximumTrackTintColor={theme.muted}
                  thumbTintColor={theme.accent}
                />
              </View>
            </View>
          );
        })}
      </ScrollView>
    </SafeAreaView>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.background
    },
    loadingText: {
      color: theme.textSecondary,
      padding: 16
    },
    content: {
      padding: 16,
      paddingBottom: 32
    },
    header: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 12
    },
    iconButton: {
      paddingVertical: 6,
      paddingHorizontal: 10,
      borderRadius: 10,
      backgroundColor: theme.card,
      borderWidth: 1,
      borderColor: theme.border
    },
    iconButtonPressed: {
      opacity: 0.85
    },
    iconButtonText: {
      color: theme.textPrimary,
      fontSize: 13,
      fontWeight: "600"
    },
    headerTitle: {
      fontSize: 16,
      fontWeight: "600",
      color: theme.textPrimary,
      textAlign: "center"
    },
    headerSpacer: {
      width: 58
    },
    thoughtCard: {
      padding: 16,
      borderRadius: 18,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.card,
      marginBottom: 14
    },
    thoughtLabel: {
      fontSize: 12,
      color: theme.textSecondary,
      textTransform: "uppercase",
      letterSpacing: 0.5,
      marginBottom: 8
    },
    thoughtText: {
      fontSize: 16,
      fontWeight: "600",
      color: theme.textPrimary
    },
    thoughtMeta: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: 8
    },
    stepCard: {
      flexDirection: "row",
      borderWidth: 1,
      borderColor: theme.border,
      borderRadius: 16,
      backgroundColor: theme.card,
      padding: 14,
      marginBottom: 12
    },
    stepIndex: {
      width: 28,
      height: 28,
      borderRadius: 14,
      backgroundColor: theme.muted,
      alignItems: "center",
      justifyContent: "center",
      marginRight: 12
    },
    stepIndexText: {
      fontSize: 12,
      color: theme.textSecondary,
      fontWeight: "600"
    },
    stepBody: {
      flex: 1
    },
    stepTitle: {
      fontSize: 13,
      fontWeight: "600",
      color: theme.textPrimary,
      marginBottom: 8
    },
    responseCard: {
      padding: 10,
      borderRadius: 12,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.background,
      marginBottom: 10
    },
    responseText: {
      fontSize: 13,
      color: theme.textPrimary,
      lineHeight: 18
    },
    sliderHeader: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 6
    },
    sliderLabel: {
      fontSize: 12,
      color: theme.textSecondary
    },
    sliderValue: {
      fontSize: 12,
      color: theme.textPrimary,
      fontWeight: "600"
    }
  });
