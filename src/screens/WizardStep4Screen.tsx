import React, { useState } from "react";
import { View, Text, Button, Pressable, StyleSheet } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { WizardProgress } from "../components/WizardProgress";
import { LabeledInput } from "../components/LabeledInput";
import { LabeledSlider } from "../components/LabeledSlider";
import { useWizard } from "../context/WizardContext";
import { clampPercent } from "../utils/validation";
import { generateId } from "../utils/uuid";

const COMMON_EMOTIONS = [
  "Anxious",
  "Sad",
  "Angry",
  "Frustrated",
  "Shame",
  "Guilty",
  "Lonely",
  "Overwhelmed",
  "Embarrassed",
  "Hopeless"
];

export const WizardStep4Screen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep4">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();
  const [emotionLabel, setEmotionLabel] = useState("");
  const [customEmotion, setCustomEmotion] = useState("");
  const [intensityValue, setIntensityValue] = useState(50);
  const [showDropdown, setShowDropdown] = useState(false);

  const addEmotion = () => {
    const intensity = clampPercent(intensityValue);
    const label =
      emotionLabel === "Custom"
        ? customEmotion.trim()
        : emotionLabel.trim();
    if (!label) {
      return;
    }
    setDraft((current) => ({
      ...current,
      emotions: [
        ...current.emotions,
        {
          id: generateId(),
          label,
          intensityBefore: intensity
        }
      ]
    }));
    setEmotionLabel("");
    setCustomEmotion("");
    setIntensityValue(50);
  };

  return (
    <View style={styles.container}>
      <WizardProgress step={4} total={7} />
      <Text style={styles.label}>Emotion</Text>
      <Pressable
        style={styles.dropdownTrigger}
        onPress={() => setShowDropdown((current) => !current)}
      >
        <Text style={styles.dropdownText}>
          {emotionLabel || "Select an emotion"}
        </Text>
      </Pressable>
      {showDropdown ? (
        <View style={styles.dropdownList}>
          {COMMON_EMOTIONS.map((emotion) => (
            <Pressable
              key={emotion}
              style={styles.dropdownItem}
              onPress={() => {
                setEmotionLabel(emotion);
                setShowDropdown(false);
              }}
            >
              <Text style={styles.dropdownText}>{emotion}</Text>
            </Pressable>
          ))}
          <Pressable
            style={styles.dropdownItem}
            onPress={() => {
              setEmotionLabel("Custom");
              setShowDropdown(false);
            }}
          >
            <Text style={styles.dropdownText}>Custom...</Text>
          </Pressable>
        </View>
      ) : null}
      {emotionLabel === "Custom" ? (
        <LabeledInput
          label="Custom emotion"
          placeholder="Describe your emotion"
          value={customEmotion}
          onChangeText={setCustomEmotion}
        />
      ) : null}
      <LabeledSlider
        label="Intensity (0-100)"
        value={intensityValue}
        onChange={setIntensityValue}
      />
      <Button title="Add emotion" onPress={addEmotion} />

      <View style={styles.list}>
        {draft.emotions.map((emotion) => (
          <View key={emotion.id} style={styles.listRow}>
            <Text style={styles.listItem}>
              {emotion.label} ({emotion.intensityBefore}%)
            </Text>
            <Pressable
              onPress={() =>
                setDraft((current) => ({
                  ...current,
                  emotions: current.emotions.filter((item) => item.id !== emotion.id)
                }))
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
  label: {
    fontSize: 14,
    color: "#4A4A4A",
    marginBottom: 6
  },
  dropdownTrigger: {
    borderWidth: 1,
    borderColor: "#D8D8D8",
    padding: 10,
    borderRadius: 6,
    backgroundColor: "#FFFFFF",
    marginBottom: 12
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
  list: {
    marginTop: 16
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
  actions: {
    marginTop: 16
  },
  actionButton: {
    marginBottom: 8
  }
});
