import React, { useMemo, useState } from "react";
import { View, Text, Button, StyleSheet, Alert } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { WizardProgress } from "../components/WizardProgress";
import { LabeledSlider } from "../components/LabeledSlider";
import { useWizard } from "../context/WizardContext";
import { clampPercent, isRequiredTextValid } from "../utils/validation";
import { createThoughtRecord } from "../storage/thoughtRecordsRepo";
import { nowIso } from "../utils/date";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

export const WizardStep7Screen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep7">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft, clearDraft } = useWizard();
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
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
      <WizardProgress step={6} total={6} />
      <Text style={styles.title}>Outcome</Text>
      <Text style={styles.helper}>
        How much do you now believe your ATs (0-100%)? What emotion/s do you now
        feel? At what intensity?
      </Text>

      <LabeledSlider
        label="Belief in main thought after (0-100)"
        value={beliefAfterValue}
        onChange={setBeliefAfterValue}
      />
      <Text style={styles.hint}>0 = not at all, 100 = completely</Text>

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
            color={theme.accent}
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
          <Button title="Save" onPress={handleSave} color={theme.accent} />
        </View>
      </View>
    </View>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      flex: 1,
      padding: 16,
      backgroundColor: theme.background
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
    subTitle: {
      fontSize: 14,
      marginBottom: 8,
      color: theme.textPrimary
    },
    hint: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: -6,
      marginBottom: 12
    },
    actions: {
      marginTop: 12
    },
    actionButton: {
      marginBottom: 8
    }
  });
