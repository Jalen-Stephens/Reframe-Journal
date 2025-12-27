import React, { useMemo, useState } from "react";
import {
  View,
  Text,
  Button,
  Pressable,
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

export const EmotionsScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep4">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
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
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <TouchableWithoutFeedback onPress={Keyboard.dismiss} accessible={false}>
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
        >
          <WizardProgress step={4} total={6} />
          <Text style={styles.helper}>
            What emotion/s did you feel at the time? How intense was the emotion
            (0-100%)?
          </Text>
          <Text style={styles.label}>Emotion</Text>
          <Pressable
            style={styles.dropdownTrigger}
            onPress={() => setShowDropdown((current) => !current)}
          >
            <Text style={styles.dropdownText}>
              {emotionLabel || "Select an emotion"}
            </Text>
            <Text style={styles.dropdownChevron}>{showDropdown ? "▲" : "▼"}</Text>
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
              returnKeyType="done"
              blurOnSubmit
            />
          ) : null}
          <LabeledSlider
            label="Intensity (0-100)"
            value={intensityValue}
            onChange={setIntensityValue}
          />
          <Text style={styles.hint}>0 = not at all, 100 = most intense</Text>
          <Button title="Add emotion" onPress={addEmotion} color={theme.accent} />

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
                  navigation.navigate("WizardStep6");
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
    helper: {
      fontSize: 13,
      color: theme.textSecondary,
      marginBottom: 12,
      lineHeight: 18
    },
    label: {
      fontSize: 14,
      color: theme.textSecondary,
      marginBottom: 6
    },
    hint: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: -6,
      marginBottom: 12
    },
    dropdownTrigger: {
      borderWidth: 1,
      borderColor: theme.border,
      padding: 10,
      borderRadius: 6,
      backgroundColor: theme.card,
      marginBottom: 12,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    dropdownList: {
      borderWidth: 1,
      borderColor: theme.border,
      borderRadius: 6,
      backgroundColor: theme.card,
      marginBottom: 12
    },
    dropdownItem: {
      padding: 10,
      borderBottomWidth: 1,
      borderBottomColor: theme.muted
    },
    dropdownText: {
      color: theme.textPrimary
    },
    dropdownChevron: {
      color: theme.textSecondary,
      fontSize: 12,
      marginLeft: 8
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
      color: theme.textSecondary,
      flex: 1
    },
    removeText: {
      fontSize: 12,
      color: theme.textSecondary,
      marginLeft: 12
    },
    actions: {
      marginTop: 16
    },
    actionButton: {
      marginBottom: 8
    }
  });
