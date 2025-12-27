import React, { useState } from "react";
import {
  View,
  Text,
  Button,
  Pressable,
  StyleSheet,
  TextInput,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Keyboard,
  TouchableWithoutFeedback
} from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { LabeledInput } from "../components/LabeledInput";
import { WizardProgress } from "../components/WizardProgress";
import { useWizard } from "../context/WizardContext";

const COMMON_SENSATIONS = [
  "Tight chest",
  "Racing heart",
  "Sweaty palms",
  "Shallow breathing",
  "Nausea",
  "Headache",
  "Tense shoulders",
  "Butterflies",
  "Restlessness",
  "Fatigue"
];

export const WizardStep2Screen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep2">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();
  const [situationText, setSituationText] = useState(draft.situationText);
  const [sensations, setSensations] = useState<string[]>(draft.sensations);
  const [showDropdown, setShowDropdown] = useState(false);
  const [showCustomInput, setShowCustomInput] = useState(false);
  const [customSensation, setCustomSensation] = useState("");

  const addSensation = (value: string) => {
    const trimmed = value.trim();
    if (!trimmed) {
      return;
    }
    setSensations((current) =>
      current.includes(trimmed) ? current : [...current, trimmed]
    );
  };

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
          <WizardProgress step={2} total={6} />
          <Text style={styles.helper}>
            What led to the unpleasant emotion? What distressing physical sensations
            did you have?
          </Text>
          <LabeledInput
            label="Situation"
            placeholder="What happened?"
            multiline
            value={situationText}
            onChangeText={setSituationText}
            style={styles.multiline}
          />
          <Text style={styles.label}>Physical sensations</Text>
          <Pressable
            style={styles.dropdownTrigger}
            onPress={() => setShowDropdown((current) => !current)}
          >
            <Text style={styles.dropdownText}>Select common sensations</Text>
            <Text style={styles.dropdownChevron}>{showDropdown ? "▲" : "▼"}</Text>
          </Pressable>
          {showDropdown ? (
            <View style={styles.dropdownList}>
              {COMMON_SENSATIONS.map((sensation) => (
                <Pressable
                  key={sensation}
                  style={styles.dropdownItem}
                  onPress={() => {
                    addSensation(sensation);
                    setShowDropdown(false);
                    setShowCustomInput(false);
                  }}
                >
                  <Text style={styles.dropdownText}>{sensation}</Text>
                </Pressable>
              ))}
              <Pressable
                style={styles.dropdownItem}
                onPress={() => setShowCustomInput((current) => !current)}
              >
                <Text style={styles.dropdownText}>Custom...</Text>
              </Pressable>
              {showCustomInput ? (
                <View style={styles.customRow}>
                  <TextInput
                    style={styles.customInput}
                    placeholder="Type a sensation"
                    value={customSensation}
                    onChangeText={setCustomSensation}
                    onSubmitEditing={() => {
                      addSensation(customSensation);
                      setCustomSensation("");
                      setShowDropdown(false);
                      setShowCustomInput(false);
                    }}
                    returnKeyType="done"
                    blurOnSubmit
                  />
                  <Button
                    title="Add"
                    onPress={() => {
                      addSensation(customSensation);
                      setCustomSensation("");
                      setShowDropdown(false);
                      setShowCustomInput(false);
                    }}
                  />
                </View>
              ) : null}
            </View>
          ) : null}
          <View style={styles.list}>
            {sensations.map((item) => (
              <View key={item} style={styles.listRow}>
                <Text style={styles.listItem}>{item}</Text>
                <Pressable
                  onPress={() =>
                    setSensations((current) =>
                      current.filter((value) => value !== item)
                    )
                  }
                >
                  <Text style={styles.removeText}>Remove</Text>
                </Pressable>
              </View>
            ))}
          </View>

          <View style={styles.actions}>
            <View style={styles.actionButton}>
              <Button
                title="Back"
                onPress={async () => {
                  const nextDraft = {
                    ...draft,
                    situationText,
                    sensations
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
                    sensations
                  };
                  setDraft(nextDraft);
                  await persistDraft(nextDraft);
                  navigation.navigate("WizardStep3");
                }}
              />
            </View>
          </View>
        </ScrollView>
      </TouchableWithoutFeedback>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: "#FAFAFA"
  },
  scrollContent: {
    paddingBottom: 24
  },
  label: {
    fontSize: 14,
    color: "#4A4A4A",
    marginBottom: 6
  },
  helper: {
    fontSize: 13,
    color: "#6B6B6B",
    marginBottom: 12,
    lineHeight: 18
  },
  dropdownTrigger: {
    borderWidth: 1,
    borderColor: "#D8D8D8",
    padding: 10,
    borderRadius: 6,
    backgroundColor: "#FFFFFF",
    marginBottom: 12,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between"
  },
  dropdownList: {
    borderWidth: 1,
    borderColor: "#D8D8D8",
    borderRadius: 6,
    backgroundColor: "#FFFFFF",
    marginBottom: 12
  },
  dropdownItem: {
    padding: 10,
    borderBottomWidth: 1,
    borderBottomColor: "#EFEFEF"
  },
  dropdownText: {
    color: "#2F2F2F"
  },
  dropdownChevron: {
    color: "#8A8A8A",
    fontSize: 12,
    marginLeft: 8
  },
  customRow: {
    padding: 10,
    borderTopWidth: 1,
    borderTopColor: "#EFEFEF"
  },
  customInput: {
    borderWidth: 1,
    borderColor: "#D8D8D8",
    padding: 10,
    borderRadius: 6,
    backgroundColor: "#FFFFFF",
    marginBottom: 8
  },
  list: {
    marginTop: 8
  },
  listRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 6
  },
  listItem: {
    fontSize: 14,
    color: "#4A4A4A",
    flex: 1
  },
  removeText: {
    fontSize: 12,
    color: "#8A8A8A",
    marginLeft: 12
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
