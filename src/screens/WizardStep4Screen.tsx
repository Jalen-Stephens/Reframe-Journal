import React, { useState } from "react";
import { View, Text, Button, StyleSheet } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { WizardProgress } from "../components/WizardProgress";
import { LabeledInput } from "../components/LabeledInput";
import { useWizard } from "../context/WizardContext";
import { clampPercent } from "../utils/validation";
import { generateId } from "../utils/uuid";

export const WizardStep4Screen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep4">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();
  const [emotionLabel, setEmotionLabel] = useState("");
  const [intensityText, setIntensityText] = useState("50");

  const addEmotion = () => {
    const intensity = clampPercent(Number(intensityText));
    if (!emotionLabel.trim()) {
      return;
    }
    setDraft((current) => ({
      ...current,
      emotions: [
        ...current.emotions,
        {
          id: generateId(),
          label: emotionLabel.trim(),
          intensityBefore: intensity
        }
      ]
    }));
    setEmotionLabel("");
  };

  return (
    <View style={styles.container}>
      <WizardProgress step={4} total={7} />
      <LabeledInput
        label="Emotion"
        placeholder="Anxious"
        value={emotionLabel}
        onChangeText={setEmotionLabel}
      />
      <LabeledInput
        label="Intensity (0-100)"
        keyboardType="numeric"
        value={intensityText}
        onChangeText={setIntensityText}
      />
      <Button title="Add emotion" onPress={addEmotion} />

      <View style={styles.list}>
        {draft.emotions.map((emotion) => (
          <Text key={emotion.id} style={styles.listItem}>
            {emotion.label} ({emotion.intensityBefore}%)
          </Text>
        ))}
      </View>

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
              navigation.navigate("WizardStep5");
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
  list: {
    marginTop: 16
  },
  listItem: {
    fontSize: 14,
    color: "#4A4A4A",
    marginBottom: 6
  },
  actions: {
    marginTop: 16
  },
  actionButton: {
    marginBottom: 8
  }
});
