import React, { useMemo, useRef, useState } from "react";
import {
  View,
  Text,
  Alert,
  Animated,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Keyboard,
  Pressable
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

export const AutomaticThoughtsScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep3">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const [thoughtText, setThoughtText] = useState("");
  const [beliefValue, setBeliefValue] = useState(50);
  const [editingId, setEditingId] = useState<string | null>(null);
  const valueScale = useRef(new Animated.Value(1)).current;

  const trimmedThought = thoughtText.trim();
  const isEditing = editingId !== null;
  const canSubmit = trimmedThought.length > 0;
  const canProceed =
    draft.automaticThoughts.length > 0 && (!isEditing || canSubmit);

  const handleBeliefChange = (value: number) => {
    Keyboard.dismiss();
    setBeliefValue(value);
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

  const handleSubmitThought = () => {
    const belief = clampPercent(beliefValue);
    if (!trimmedThought) {
      return;
    }
    Keyboard.dismiss();
    if (editingId) {
      setDraft((current) => ({
        ...current,
        automaticThoughts: current.automaticThoughts.map((thought) =>
          thought.id === editingId
            ? {
                ...thought,
                text: trimmedThought,
                beliefBefore: belief
              }
            : thought
        )
      }));
    } else {
      setDraft((current) => ({
        ...current,
        automaticThoughts: [
          ...current.automaticThoughts,
          { id: generateId(), text: trimmedThought, beliefBefore: belief }
        ]
      }));
    }
    setThoughtText("");
    setBeliefValue(50);
    setEditingId(null);
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <View style={styles.container}>
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
          keyboardDismissMode={Platform.OS === "ios" ? "interactive" : "on-drag"}
        >
            <WizardProgress step={3} total={6} />
            <Text style={styles.helper}>
              What thought/s or image/s went through your mind? How much did you
              believe the thought at the time (0-100%)?
            </Text>
            <LabeledInput
              label="Automatic thought"
              placeholder={`e.g. "I'm going to mess this up"`}
              value={thoughtText}
              onChangeText={setThoughtText}
              returnKeyType="done"
              blurOnSubmit
            />

            <View style={styles.sliderSection}>
              <Animated.View
                style={[styles.beliefHero, { transform: [{ scale: valueScale }] }]}
              >
                <Text style={styles.beliefValue}>{beliefValue}%</Text>
              </Animated.View>
              <Text style={styles.sliderLabel}>
                How strongly did you believe this?
              </Text>
              <Slider
                minimumValue={0}
                maximumValue={100}
                step={1}
                value={beliefValue}
                onValueChange={handleBeliefChange}
                minimumTrackTintColor={theme.accent}
                maximumTrackTintColor={theme.muted}
                thumbTintColor={theme.accent}
              />
              <Text style={styles.hint}>0 = not at all, 100 = completely</Text>
            </View>

            <View style={styles.addSection}>
              <PrimaryButton
                label={isEditing ? "Save changes" : "Add thought"}
                onPress={handleSubmitThought}
                disabled={!canSubmit}
              />
              {isEditing ? (
                <Pressable
                  onPress={() => {
                    setEditingId(null);
                    setThoughtText("");
                    setBeliefValue(50);
                  }}
                  hitSlop={8}
                >
                  <Text style={styles.cancelText}>Cancel</Text>
                </Pressable>
              ) : null}
            </View>

            <View style={styles.list}>
              {draft.automaticThoughts.map((thought) => (
                <ThoughtCard
                  key={thought.id}
                  text={thought.text}
                  belief={thought.beliefBefore}
                  onEdit={() => {
                    setEditingId(thought.id);
                    setThoughtText(thought.text);
                    setBeliefValue(thought.beliefBefore);
                  }}
                  onRemove={() => {
                    Alert.alert(
                      "Remove thought?",
                      "This will delete it from your list.",
                      [
                        { text: "Cancel", style: "cancel" },
                        {
                          text: "Remove",
                          style: "destructive",
                          onPress: () =>
                            setDraft((current) => ({
                              ...current,
                              automaticThoughts: current.automaticThoughts.filter(
                                (item) => item.id !== thought.id
                              )
                            }))
                        }
                      ]
                    );
                  }}
                />
              ))}
            </View>
        </ScrollView>

        <SafeAreaView edges={["bottom"]} style={styles.bottomBar}>
          <PrimaryButton
            label="Next"
            onPress={async () => {
              await persistDraft();
              navigation.navigate("WizardStep4");
            }}
            disabled={!canProceed}
          />
        </SafeAreaView>
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
    hint: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: 6,
      marginBottom: 6
    },
    sliderSection: {
      marginBottom: 18
    },
    beliefHero: {
      alignItems: "center",
      marginBottom: 6
    },
    beliefValue: {
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
    cancelText: {
      textAlign: "center",
      color: theme.textSecondary,
      fontSize: 13,
      marginTop: 10
    },
    list: {
      marginTop: 20
    },
    bottomBar: {
      padding: 16,
      borderTopWidth: 1,
      borderTopColor: theme.border,
      backgroundColor: theme.background
    }
  });
