import React, { useState } from "react";
import { View, Text, Button, StyleSheet, Alert } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { WizardProgress } from "../components/WizardProgress";
import { LabeledSlider } from "../components/LabeledSlider";
import { useWizard } from "../context/WizardContext";
import { clampPercent, isRequiredTextValid } from "../utils/validation";
import { createThoughtRecord } from "../storage/thoughtRecordsRepo";
import { nowIso } from "../utils/date";

export const WizardStep7Screen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep7">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft, clearDraft } = useWizard();
  const [beliefAfterValue, setBeliefAfterValue] = useState(
    draft.beliefAfterMainThought ?? 0
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
    if (!isRequiredTextValid(draft.situationText)) {
      Alert.alert("Missing situation", "Add a situation before saving.");
      return;
    }

    const record = {
      ...draft,
      beliefAfterMainThought: clampPercent(beliefAfterValue),
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

      <LabeledSlider
        label="Belief in main thought after (0-100)"
        value={beliefAfterValue}
        onChange={setBeliefAfterValue}
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
                beliefAfterMainThought: clampPercent(beliefAfterValue)
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
