import React, { useMemo } from "react";
import {
  View,
  Text,
  Button,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Keyboard,
  TouchableWithoutFeedback
} from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { WizardProgress } from "../components/WizardProgress";
import { LabeledInput } from "../components/LabeledInput";
import { LabeledSlider } from "../components/LabeledSlider";
import { useWizard } from "../context/WizardContext";
import { clampPercent } from "../utils/validation";
import { generateId } from "../utils/uuid";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

const PROMPTS = [
  {
    key: "evidence",
    label: "What is the evidence that the thought is true? Not true?"
  },
  { key: "alternative", label: "Is there an alternative explanation?" },
  {
    key: "outcomes",
    label:
      "What's the worst that could happen? What's the best that could happen? What's the most realistic outcome?"
  },
  {
    key: "friend_advice",
    label:
      "If a friend were in this situation and had this thought, what would I tell him/her?"
  }
];

export const AdaptiveResponseScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep6">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const updateResponse = (promptKey: string, responseText: string) => {
    setDraft((current) => {
      const existing = current.adaptiveResponses.find(
        (item) => item.promptKey === promptKey
      );
      const updated = existing
        ? current.adaptiveResponses.map((item) =>
            item.promptKey === promptKey
              ? { ...item, responseText }
              : item
          )
        : [
            ...current.adaptiveResponses,
            {
              id: generateId(),
              promptKey,
              responseText,
              beliefInResponse: 0
            }
          ];
      return { ...current, adaptiveResponses: updated };
    });
  };

  const updateBelief = (promptKey: string, value: number) => {
    const belief = clampPercent(value);
    setDraft((current) => {
      const existing = current.adaptiveResponses.find(
        (item) => item.promptKey === promptKey
      );
      const updated = existing
        ? current.adaptiveResponses.map((item) =>
            item.promptKey === promptKey
              ? { ...item, beliefInResponse: belief }
              : item
          )
        : [
            ...current.adaptiveResponses,
            {
              id: generateId(),
              promptKey,
              responseText: "",
              beliefInResponse: belief
            }
          ];
      return { ...current, adaptiveResponses: updated };
    });
  };

  const getResponse = (promptKey: string) =>
    draft.adaptiveResponses.find((item) => item.promptKey === promptKey);

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <TouchableWithoutFeedback onPress={Keyboard.dismiss} accessible={false}>
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
        >
          <WizardProgress step={5} total={6} />
          <Text style={styles.title}>Adaptive Response</Text>
          <Text style={styles.helper}>
            Use questions below to respond to the automatic thoughts/s. How much
            do you believe each response (0-100%)?
          </Text>

          {PROMPTS.map((prompt) => {
            const response = getResponse(prompt.key);
            return (
              <View key={prompt.key} style={styles.promptBlock}>
                <LabeledInput
                  label={prompt.label}
                  placeholder="Write a grounded response"
                  value={response?.responseText || ""}
                  onChangeText={(value) => updateResponse(prompt.key, value)}
                  multiline
                  style={styles.multiline}
                  returnKeyType="done"
                  blurOnSubmit
                />
                <LabeledSlider
                  label="Belief in response (0-100)"
                  value={response?.beliefInResponse ?? 0}
                  onChange={(value) => updateBelief(prompt.key, value)}
                />
                <Text style={styles.hint}>0 = not at all, 100 = strongly</Text>
              </View>
            );
          })}

          <View style={styles.actions}>
            <View style={styles.actionButton}>
              <Button
                title="Back"
                color={theme.accent}
                onPress={async () => {
                  await persistDraft();
                  navigation.goBack();
                }}
              />
            </View>
            <View style={styles.actionButton}>
              <Button
                title="Next"
                color={theme.accent}
                onPress={async () => {
                  await persistDraft();
                  navigation.navigate("WizardStep7");
                }}
              />
            </View>
          </View>
        </ScrollView>
      </TouchableWithoutFeedback>
    </KeyboardAvoidingView>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      flex: 1,
      padding: 16,
      backgroundColor: theme.background
    },
    scrollContent: {
      paddingBottom: 24
    },
    title: {
      fontSize: 16,
      marginBottom: 12,
      color: theme.textPrimary
    },
    helper: {
      fontSize: 13,
      color: theme.textSecondary,
      marginBottom: 12,
      lineHeight: 18
    },
    promptBlock: {
      marginBottom: 12
    },
    hint: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: -6,
      marginBottom: 8
    },
    multiline: {
      minHeight: 90,
      textAlignVertical: "top"
    },
    actions: {
      marginTop: 8
    },
    actionButton: {
      marginBottom: 8
    }
  });
