import React, { useState } from "react";
import { View, Text, Button, StyleSheet } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { WizardProgress } from "../components/WizardProgress";
import { LabeledInput } from "../components/LabeledInput";
import { useWizard } from "../context/WizardContext";
import { clampPercent } from "../utils/validation";
import { generateId } from "../utils/uuid";

export const WizardStep3Screen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep3">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();
  const [thoughtText, setThoughtText] = useState("");
  const [beliefText, setBeliefText] = useState("50");

  const addThought = () => {
    const belief = clampPercent(Number(beliefText));
    if (!thoughtText.trim()) {
      return;
    }
    setDraft((current) => ({
      ...current,
      automaticThoughts: [
        ...current.automaticThoughts,
        { id: generateId(), text: thoughtText.trim(), beliefBefore: belief }
      ]
    }));
    setThoughtText("");
  };

  return (
    <View style={styles.container}>
      <WizardProgress step={3} total={7} />
      <LabeledInput
        label="Automatic thought"
        placeholder="I'm going to mess this up"
        value={thoughtText}
        onChangeText={setThoughtText}
      />
      <LabeledInput
        label="Belief (0-100)"
        keyboardType="numeric"
        value={beliefText}
        onChangeText={setBeliefText}
      />
      <Button title="Add thought" onPress={addThought} />

      <View style={styles.list}>
        {draft.automaticThoughts.map((thought) => (
          <Text key={thought.id} style={styles.listItem}>
            {thought.text} ({thought.beliefBefore}%)
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
              navigation.navigate("WizardStep4");
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
