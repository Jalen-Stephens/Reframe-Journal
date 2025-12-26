import React from "react";
import { View, Text, Button, StyleSheet } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { WizardProgress } from "../components/WizardProgress";
import { LabeledInput } from "../components/LabeledInput";
import { useWizard } from "../context/WizardContext";
import { clampPercent } from "../utils/validation";
import { generateId } from "../utils/uuid";

const PROMPTS = [
  { key: "evidence_for", label: "Evidence for the thought" },
  { key: "evidence_against", label: "Evidence against the thought" },
  { key: "balanced_view", label: "Balanced response" }
];

export const WizardStep6Screen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep6">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();

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

  const updateBelief = (promptKey: string, value: string) => {
    const belief = clampPercent(Number(value));
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
    <View style={styles.container}>
      <WizardProgress step={6} total={7} />
      <Text style={styles.title}>Adaptive Response</Text>

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
            />
            <LabeledInput
              label="Belief in response (0-100)"
              keyboardType="numeric"
              value={(response?.beliefInResponse ?? 0).toString()}
              onChangeText={(value) => updateBelief(prompt.key, value)}
            />
          </View>
        );
      })}

      <View style={styles.actions}>
        <View style={styles.actionButton}>
          <Button
            title="Back"
            onPress={async () => {
              await persistDraft();
              navigation.goBack();
            }}
          />
        </View>
        <View style={styles.actionButton}>
          <Button
            title="Next"
            onPress={async () => {
              await persistDraft();
              navigation.navigate("WizardStep7");
            }}
          />
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: "#FAFAFA"
  },
  title: {
    fontSize: 16,
    marginBottom: 12,
    color: "#4A4A4A"
  },
  promptBlock: {
    marginBottom: 12
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
