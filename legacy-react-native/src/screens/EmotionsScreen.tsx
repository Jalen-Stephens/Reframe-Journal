import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  View,
  Text,
  Alert,
  Pressable,
  Animated,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Keyboard,
  Modal
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import Slider from "@react-native-community/slider";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { WizardProgress } from "../components/WizardProgress";
import { LabeledInput } from "../components/LabeledInput";
import { useWizard } from "../context/WizardContext";
import { clampPercent } from "../utils/validation";
import { generateId } from "../utils/uuid";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";
import { PrimaryButton } from "../components/PrimaryButton";
import { ThoughtCard } from "../components/ThoughtCard";

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
const CUSTOM_OPTION = "Custom...";

export const EmotionsScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep4">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const scrollRef = useRef<ScrollView | null>(null);
  const [emotionLabel, setEmotionLabel] = useState("");
  const [customEmotion, setCustomEmotion] = useState("");
  const [intensityValue, setIntensityValue] = useState(50);
  const valueScale = useRef(new Animated.Value(1)).current;
  const [showPicker, setShowPicker] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [shouldScrollToEnd, setShouldScrollToEnd] = useState(false);

  const isCustomSelected = emotionLabel === CUSTOM_OPTION;
  const trimmedCustom = customEmotion.trim();
  const resolvedLabel = isCustomSelected
    ? trimmedCustom
    : emotionLabel.trim();
  const canSubmit = resolvedLabel.length > 0;
  const canProceed = draft.emotions.length > 0;
  const usedEmotionLabels = draft.emotions
    .map((emotion) => emotion.label)
    .filter((label) => label.length > 0);
  const availableEmotions = COMMON_EMOTIONS.filter((emotion) => {
    if (editId && emotionLabel === emotion) {
      return true;
    }
    return !usedEmotionLabels.includes(emotion);
  });

  useEffect(() => {
    if (!shouldScrollToEnd) {
      return;
    }
    const timer = setTimeout(() => {
      scrollRef.current?.scrollToEnd({ animated: true });
      setShouldScrollToEnd(false);
    }, 120);
    return () => clearTimeout(timer);
  }, [shouldScrollToEnd, draft.emotions.length]);

  const resetInputs = () => {
    setEmotionLabel("");
    setCustomEmotion("");
    setIntensityValue(50);
    setEditId(null);
  };

  const handleIntensityChange = (value: number) => {
    Keyboard.dismiss();
    setIntensityValue(value);
    Animated.sequence([
      Animated.timing(valueScale, {
        toValue: 1.06,
        duration: 120,
        useNativeDriver: true
      }),
      Animated.timing(valueScale, {
        toValue: 1,
        duration: 120,
        useNativeDriver: true
      })
    ]).start();
  };

  const handleSelectEmotion = (label: string) => {
    setEmotionLabel(label);
    if (label !== CUSTOM_OPTION) {
      setCustomEmotion("");
    }
    setShowPicker(false);
  };

  const handleSubmitEmotion = () => {
    const intensity = clampPercent(intensityValue);
    if (!canSubmit) {
      return;
    }
    Keyboard.dismiss();
    if (editId) {
      setDraft((current) => ({
        ...current,
        emotions: current.emotions.map((emotion) =>
          emotion.id === editId
            ? { ...emotion, label: resolvedLabel, intensityBefore: intensity }
            : emotion
        )
      }));
    } else {
      setDraft((current) => ({
        ...current,
        emotions: [
          ...current.emotions,
          {
            id: generateId(),
            label: resolvedLabel,
            intensityBefore: intensity
          }
        ]
      }));
      setShouldScrollToEnd(true);
    }
    resetInputs();
  };

  const handleStartEdit = (id: string) => {
    const emotion = draft.emotions.find((item) => item.id === id);
    if (!emotion) {
      return;
    }
    setEditId(id);
    setIntensityValue(emotion.intensityBefore);
    if (COMMON_EMOTIONS.includes(emotion.label)) {
      setEmotionLabel(emotion.label);
      setCustomEmotion("");
    } else {
      setEmotionLabel(CUSTOM_OPTION);
      setCustomEmotion(emotion.label);
    }
    scrollRef.current?.scrollTo({ y: 0, animated: true });
  };

  const handleCancelEdit = () => {
    resetInputs();
  };

  const handleRemoveEmotion = (id: string) => {
    Alert.alert("Remove emotion?", "This will delete it from your list.", [
      { text: "Cancel", style: "cancel" },
      {
        text: "Remove",
        style: "destructive",
        onPress: () =>
          setDraft((current) => ({
            ...current,
            emotions: current.emotions.filter((item) => item.id !== id)
          }))
      }
    ]);
  };

  const displayLabel = isCustomSelected
    ? trimmedCustom || CUSTOM_OPTION
    : emotionLabel || "Select an emotion";

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <View style={styles.container}>
        <ScrollView
          ref={scrollRef}
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
          keyboardDismissMode={Platform.OS === "ios" ? "interactive" : "on-drag"}
        >
          <WizardProgress step={4} total={6} />
          <Text style={styles.helper}>
            What emotion/s did you feel at the time? How intense was the emotion
            (0-100%)?
          </Text>
          <Text style={styles.label}>Emotion</Text>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Select an emotion"
            style={styles.selectorRow}
            onPress={() => setShowPicker(true)}
          >
            <Text
              style={[
                styles.selectorText,
                !emotionLabel && styles.selectorPlaceholder
              ]}
            >
              {displayLabel}
            </Text>
            <Text style={styles.selectorChevron}>▼</Text>
          </Pressable>
          {isCustomSelected ? (
            <LabeledInput
              label="Custom emotion"
              placeholder="Describe your emotion"
              value={customEmotion}
              onChangeText={setCustomEmotion}
              autoFocus
              returnKeyType="done"
              blurOnSubmit
            />
          ) : null}

          {editId ? (
            <View style={styles.editRow}>
              <Text style={styles.editLabel}>Editing emotion</Text>
              <Pressable onPress={handleCancelEdit} hitSlop={8}>
                <Text style={styles.cancelEdit}>Cancel edit</Text>
              </Pressable>
            </View>
          ) : null}

          <View style={styles.sliderSection}>
            <Animated.View
              style={[styles.intensityHero, { transform: [{ scale: valueScale }] }]}
            >
              <Text style={styles.intensityValue}>{intensityValue}%</Text>
            </Animated.View>
            <Text style={styles.sliderLabel}>How intense was this emotion?</Text>
            <Slider
              minimumValue={0}
              maximumValue={100}
              step={1}
              value={intensityValue}
              onValueChange={handleIntensityChange}
              minimumTrackTintColor={theme.accent}
              maximumTrackTintColor={theme.muted}
              thumbTintColor={theme.accent}
              accessibilityLabel="Emotion intensity"
              accessibilityValue={{ text: `${intensityValue}%` }}
            />
            <Text style={styles.hint}>0 = not at all, 100 = most intense</Text>
          </View>

          <View style={styles.addSection}>
            <PrimaryButton
              label={editId ? "Save changes" : "Add emotion"}
              onPress={handleSubmitEmotion}
              disabled={!canSubmit}
            />
            {!canProceed ? (
              <Text style={styles.continueHint}>
                Add at least one emotion to continue.
              </Text>
            ) : null}
          </View>

          <View style={styles.list}>
            {draft.emotions.map((emotion) => (
              <ThoughtCard
                key={emotion.id}
                text={emotion.label}
                belief={emotion.intensityBefore}
                badgeLabel="Intensity"
                onEdit={() => handleStartEdit(emotion.id)}
                onRemove={() => handleRemoveEmotion(emotion.id)}
              />
            ))}
          </View>
        </ScrollView>

        <SafeAreaView edges={["bottom"]} style={styles.bottomBar}>
          <PrimaryButton
            label="Next"
            onPress={async () => {
              await persistDraft();
              navigation.navigate("WizardStep6");
            }}
            disabled={!canProceed}
          />
        </SafeAreaView>

        <Modal
          visible={showPicker}
          transparent
          animationType="slide"
          onRequestClose={() => setShowPicker(false)}
        >
          <Pressable
            style={styles.modalBackdrop}
            onPress={() => setShowPicker(false)}
          >
            <Pressable style={styles.pickerCard} onPress={() => {}}>
              <Text style={styles.modalTitle}>Select an emotion</Text>
              <ScrollView style={styles.pickerList}>
                {availableEmotions.map((emotion) => {
                  const isSelected = emotionLabel === emotion;
                  return (
                    <Pressable
                      key={emotion}
                      style={styles.pickerItem}
                      onPress={() => handleSelectEmotion(emotion)}
                    >
                      <Text
                        style={[
                          styles.pickerText,
                          isSelected && styles.pickerTextSelected
                        ]}
                      >
                        {emotion}
                      </Text>
                    </Pressable>
                  );
                })}
                <Pressable
                  style={styles.pickerItem}
                  onPress={() => handleSelectEmotion(CUSTOM_OPTION)}
                >
                  <Text
                    style={[
                      styles.pickerText,
                      isCustomSelected && styles.pickerTextSelected
                    ]}
                  >
                    {CUSTOM_OPTION}
                  </Text>
                </Pressable>
              </ScrollView>
            </Pressable>
          </Pressable>
        </Modal>
      </View>
    </KeyboardAvoidingView>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.background
    },
    scrollContent: {
      padding: 16,
      paddingBottom: 140
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
      marginTop: 6,
      marginBottom: 6
    },
    selectorRow: {
      borderWidth: 1,
      borderColor: theme.border,
      padding: 10,
      borderRadius: 6,
      backgroundColor: theme.card,
      marginBottom: 16,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    selectorText: {
      color: theme.textPrimary,
      fontSize: 15
    },
    selectorPlaceholder: {
      color: theme.placeholder
    },
    selectorChevron: {
      color: theme.textSecondary,
      fontSize: 12,
      marginLeft: 8
    },
    editRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 12
    },
    editLabel: {
      fontSize: 13,
      color: theme.textSecondary
    },
    cancelEdit: {
      fontSize: 13,
      color: theme.accent
    },
    sliderSection: {
      marginBottom: 18
    },
    intensityHero: {
      alignItems: "center",
      marginBottom: 6
    },
    intensityValue: {
      fontSize: 32,
      fontWeight: "600",
      color: theme.textPrimary
    },
    sliderLabel: {
      fontSize: 14,
      color: theme.textSecondary,
      marginBottom: 10,
      textAlign: "center"
    },
    addSection: {
      marginTop: 8
    },
    continueHint: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: 8,
      textAlign: "center"
    },
    list: {
      marginTop: 20
    },
    bottomBar: {
      padding: 16,
      borderTopWidth: 1,
      borderTopColor: theme.border,
      backgroundColor: theme.background
    },
    modalBackdrop: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.35)",
      justifyContent: "flex-end"
    },
    pickerCard: {
      backgroundColor: theme.card,
      padding: 16,
      borderTopLeftRadius: 16,
      borderTopRightRadius: 16
    },
    modalTitle: {
      fontSize: 16,
      color: theme.textPrimary,
      marginBottom: 12
    },
    pickerList: {
      maxHeight: 320
    },
    pickerItem: {
      paddingVertical: 10
    },
    pickerText: {
      fontSize: 15,
      color: theme.textPrimary
    },
    pickerTextSelected: {
      color: theme.accent,
      fontWeight: "600"
    }
  });
