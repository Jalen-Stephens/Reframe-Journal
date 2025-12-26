import React, { useState } from "react";
import { View, Text, Button, StyleSheet, Alert } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { WizardProgress } from "../components/WizardProgress";
import { LabeledInput } from "../components/LabeledInput";
import { LabeledSlider } from "../components/LabeledSlider";
import { useWizard } from "../context/WizardContext";
import { clampPercent, isPercentValid, isRequiredTextValid } from "../utils/validation";
import { createThoughtRecord } from "../storage/thoughtRecordsRepo";
import { nowIso } from "../utils/date";

export const WizardStep7Screen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep7">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft, clearDraft } = useWizard();
  const [beliefAfterText, setBeliefAfterText] = useState(
    draft.beliefAfterMainThought?.toString() || ""
  );

  const updateEmotionAfter = (id: string, value: number) => {
    const intensity = clampPercent(value);
    setDraft((current) => ({
      ...current,
      emotions: current.emotions.map((emotion) =>
        emotion.id === id ? { ...emotion, intensityAfter: intensity } : emotion
      )
    }));
  };

  const handleSave = async () => {
    const beliefAfter = beliefAfterText ? Number(beliefAfterText) : undefined;
    if (beliefAfter !== undefined && !isPercentValid(beliefAfter)) {
      Alert.alert("Check belief value", "Belief must be between 0 and 100.");
      return;
    }
    if (!isRequiredTextValid(draft.situationText)) {
      Alert.alert("Missing situation", "Add a situation before saving.");
      return;
    }

    const record = {
      ...draft,
      beliefAfterMainThought: beliefAfter,
      updatedAt: nowIso()
    };

    await createThoughtRecord(record);
    await clearDraft();
    navigation.popToTop();
  };

  return (
    <View style={styles.container}>
      <WizardProgress step={7} total={7} />
      <Text style={styles.title}>Outcome</Text>

      <LabeledInput
        label="Belief in main thought after (0-100)"
        keyboardType="numeric"
        value={beliefAfterText}
        onChangeText={setBeliefAfterText}
      />

      <Text style={styles.subTitle}>Re-rate emotions</Text>
      {draft.emotions.map((emotion) => (
        <LabeledSlider
          key={emotion.id}
          label={`${emotion.label} (after)`}
          value={emotion.intensityAfter ?? emotion.intensityBefore}
          onChange={(value) => updateEmotionAfter(emotion.id, value)}
        />
      ))}

      <View style={styles.actions}>
        <View style={styles.actionButton}>
          <Button
            title="Back"
            onPress={async () => {
              const nextDraft = {
                ...draft,
                beliefAfterMainThought: beliefAfterText
                  ? clampPercent(Number(beliefAfterText))
                  : undefined
              };
              setDraft(nextDraft);
              await persistDraft(nextDraft);
              navigation.goBack();
            }}
          />
        </View>
        <View style={styles.actionButton}>
          <Button title="Save" onPress={handleSave} />
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
  subTitle: {
    fontSize: 14,
    marginBottom: 8,
    color: "#4A4A4A"
  },
  actions: {
    marginTop: 12
  },
  actionButton: {
    marginBottom: 8
  }
});
