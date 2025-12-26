import React, { useState } from "react";
import { View, Button, StyleSheet } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { LabeledInput } from "../components/LabeledInput";
import { WizardProgress } from "../components/WizardProgress";
import { useWizard } from "../context/WizardContext";

export const WizardStep2Screen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep2">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();
  const [situationText, setSituationText] = useState(draft.situationText);
  const [sensationsText, setSensationsText] = useState(
    draft.sensations.join(", ")
  );

  return (
    <View style={styles.container}>
      <WizardProgress step={2} total={7} />
      <LabeledInput
        label="Situation"
        placeholder="What happened?"
        multiline
        value={situationText}
        onChangeText={setSituationText}
        style={styles.multiline}
      />
      <LabeledInput
        label="Physical sensations (comma separated)"
        placeholder="Tight chest, jittery"
        value={sensationsText}
        onChangeText={setSensationsText}
      />

      <View style={styles.actions}>
        <View style={styles.actionButton}>
          <Button
            title="Back"
            onPress={async () => {
              const nextDraft = {
                ...draft,
                situationText,
                sensations: sensationsText
                  .split(",")
                  .map((item) => item.trim())
                  .filter(Boolean)
              };
              setDraft(nextDraft);
              await persistDraft(nextDraft);
              navigation.goBack();
            }}
          />
        </View>
        <View style={styles.actionButton}>
          <Button
            title="Next"
            onPress={async () => {
              const nextDraft = {
                ...draft,
                situationText,
                sensations: sensationsText
                  .split(",")
                  .map((item) => item.trim())
                  .filter(Boolean)
              };
              setDraft(nextDraft);
              await persistDraft(nextDraft);
              navigation.navigate("WizardStep3");
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
  multiline: {
    minHeight: 100,
    textAlignVertical: "top"
  },
  actions: {
    marginTop: 16
  },
  actionButton: {
    marginBottom: 8
  }
});
