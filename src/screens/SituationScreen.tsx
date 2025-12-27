import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  View,
  Text,
  Pressable,
  StyleSheet,
  TextInput,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Keyboard,
  TouchableWithoutFeedback
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { LabeledInput } from "../components/LabeledInput";
import { WizardProgress } from "../components/WizardProgress";
import { useWizard } from "../context/WizardContext";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

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

export const SituationScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep2">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const [situationText, setSituationText] = useState(draft.situationText);
  const [sensations, setSensations] = useState<string[]>(draft.sensations);
  const [showDropdown, setShowDropdown] = useState(false);
  const [showCustomInput, setShowCustomInput] = useState(false);
  const [customSensation, setCustomSensation] = useState("");
  const customInputRef = useRef<TextInput>(null);

  useEffect(() => {
    const subscription = Keyboard.addListener("keyboardDidShow", () => {
      setShowDropdown(false);
    });

    return () => subscription.remove();
  }, []);

  useEffect(() => {
    if (!showCustomInput) {
      return;
    }

    const timeout = setTimeout(() => {
      customInputRef.current?.focus();
    }, 80);

    return () => clearTimeout(timeout);
  }, [showCustomInput]);

  const addSensation = (value: string) => {
    const trimmed = value.trim();
    if (!trimmed) {
      return;
    }
    setSensations((current) =>
      current.includes(trimmed) ? current : [...current, trimmed]
    );
  };

  const availableSensations = useMemo(
    () => COMMON_SENSATIONS.filter((item) => !sensations.includes(item)),
    [sensations]
  );

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <View style={styles.content}>
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
              returnKeyType="done"
              blurOnSubmit
              onSubmitEditing={() => {
                Keyboard.dismiss();
              }}
              style={styles.multiline}
            />
            <Text style={styles.label}>Physical sensations</Text>
            <Pressable
              style={styles.dropdownTrigger}
              onPress={() => {
                Keyboard.dismiss();
                setShowCustomInput(false);
                setShowDropdown((current) => !current);
              }}
            >
              <Text style={styles.dropdownText}>Select common sensations</Text>
              <Text style={styles.dropdownChevron}>{showDropdown ? "▲" : "▼"}</Text>
            </Pressable>
            {showDropdown ? (
              <View style={styles.dropdownList}>
                {availableSensations.map((sensation) => (
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
                  onPress={() => {
                    setShowDropdown(false);
                    setShowCustomInput(true);
                  }}
                >
                  <Text style={styles.dropdownText}>Custom...</Text>
                </Pressable>
              </View>
            ) : null}
            {showCustomInput ? (
              <View style={styles.customRow}>
                <TextInput
                  ref={customInputRef}
                  style={styles.customInput}
                  placeholder="Describe your sensation (e.g., pressure in throat)"
                  value={customSensation}
                  onChangeText={setCustomSensation}
                  placeholderTextColor={theme.textSecondary}
                  onSubmitEditing={() => {
                    addSensation(customSensation);
                    setCustomSensation("");
                    setShowCustomInput(false);
                    Keyboard.dismiss();
                  }}
                  returnKeyType="done"
                  blurOnSubmit={false}
                />
              </View>
            ) : null}
            <View style={styles.chipGroup}>
              {sensations.map((item) => (
                <Pressable
                  key={item}
                  style={styles.chip}
                  accessibilityRole="button"
                  onPress={() =>
                    setSensations((current) =>
                      current.filter((value) => value !== item)
                    )
                  }
                >
                  <Text style={styles.chipText}>{item}</Text>
                  <Text style={styles.chipRemove}>✕</Text>
                </Pressable>
              ))}
            </View>
          </ScrollView>
        </TouchableWithoutFeedback>
      </View>

      <SafeAreaView edges={["bottom"]} style={styles.bottomBar}>
        <Pressable
          style={styles.primaryButton}
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
        >
          <Text style={styles.primaryButtonText}>Next</Text>
        </Pressable>
      </SafeAreaView>
    </KeyboardAvoidingView>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.background
    },
    content: {
      flex: 1,
      padding: 16
    },
    scrollContent: {
      paddingBottom: 32
    },
    label: {
      fontSize: 14,
      color: theme.textSecondary,
      marginBottom: 6
    },
    helper: {
      fontSize: 13,
      color: theme.textSecondary,
      marginBottom: 12,
      lineHeight: 18
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
    customRow: {
      marginBottom: 12
    },
    customInput: {
      borderWidth: 1,
      borderColor: theme.border,
      padding: 10,
      borderRadius: 10,
      backgroundColor: theme.card,
      color: theme.textPrimary,
      fontSize: 14
    },
    chipGroup: {
      flexDirection: "row",
      flexWrap: "wrap",
      marginTop: 2
    },
    chip: {
      flexDirection: "row",
      alignItems: "center",
      paddingVertical: 6,
      paddingHorizontal: 10,
      borderRadius: 999,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.card,
      marginRight: 8,
      marginBottom: 8
    },
    chipText: {
      fontSize: 13,
      color: theme.textPrimary,
      marginRight: 6
    },
    chipRemove: {
      fontSize: 12,
      color: theme.textSecondary
    },
    multiline: {
      minHeight: 100,
      textAlignVertical: "top"
    },
    bottomBar: {
      padding: 16,
      borderTopWidth: 1,
      borderTopColor: theme.border,
      backgroundColor: theme.background
    },
    primaryButton: {
      backgroundColor: theme.accent,
      borderRadius: 10,
      alignItems: "center",
      paddingVertical: 14
    },
    primaryButtonText: {
      color: theme.onAccent,
      fontSize: 16
    }
  });
