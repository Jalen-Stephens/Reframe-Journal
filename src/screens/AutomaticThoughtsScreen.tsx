import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  View,
  Text,
  Animated,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Keyboard,
  Pressable,
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

export const AutomaticThoughtsScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep3">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const scrollRef = useRef<ScrollView | null>(null);
  const [thoughtText, setThoughtText] = useState("");
  const [beliefValue, setBeliefValue] = useState(50);
  const valueScale = useRef(new Animated.Value(1)).current;
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [editText, setEditText] = useState("");
  const [editBelief, setEditBelief] = useState(50);
  const [confirmId, setConfirmId] = useState<string | null>(null);
  const [shouldScrollToEnd, setShouldScrollToEnd] = useState(false);

  const trimmedThought = thoughtText.trim();
  const canSubmit = trimmedThought.length > 0;
  const canProceed = draft.automaticThoughts.length > 0;

  useEffect(() => {
    if (!shouldScrollToEnd) {
      return;
    }
    const timer = setTimeout(() => {
      scrollRef.current?.scrollToEnd({ animated: true });
      setShouldScrollToEnd(false);
    }, 120);
    return () => clearTimeout(timer);
  }, [shouldScrollToEnd, draft.automaticThoughts.length]);

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
    setDraft((current) => ({
      ...current,
      automaticThoughts: [
        ...current.automaticThoughts,
        { id: generateId(), text: trimmedThought, beliefBefore: belief }
      ]
    }));
    setThoughtText("");
    setBeliefValue(50);
    setShouldScrollToEnd(true);
  };

  const handleOpenEdit = (id: string) => {
    const thought = draft.automaticThoughts.find((item) => item.id === id);
    if (!thought) {
      return;
    }
    setEditId(id);
    setEditText(thought.text);
    setEditBelief(thought.beliefBefore);
    setIsEditOpen(true);
  };

  const handleSaveEdit = () => {
    const trimmed = editText.trim();
    if (!editId || !trimmed) {
      return;
    }
    setDraft((current) => ({
      ...current,
      automaticThoughts: current.automaticThoughts.map((thought) =>
        thought.id === editId
          ? { ...thought, text: trimmed, beliefBefore: clampPercent(editBelief) }
          : thought
      )
    }));
    setIsEditOpen(false);
    setEditId(null);
    setEditText("");
    setEditBelief(50);
  };

  const handleConfirmRemove = () => {
    if (!confirmId) {
      return;
    }
    setDraft((current) => ({
      ...current,
      automaticThoughts: current.automaticThoughts.filter(
        (item) => item.id !== confirmId
      )
    }));
    setConfirmId(null);
  };

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
                label="Add thought"
                onPress={handleSubmitThought}
                disabled={!canSubmit}
              />
            </View>

            <View style={styles.list}>
              {draft.automaticThoughts.map((thought) => (
                <ThoughtCard
                  key={thought.id}
                  text={thought.text}
                  belief={thought.beliefBefore}
                  onEdit={() => handleOpenEdit(thought.id)}
                  onRemove={() => setConfirmId(thought.id)}
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

          <Modal
            visible={isEditOpen}
            transparent
            animationType="slide"
            onRequestClose={() => setIsEditOpen(false)}
          >
            <Pressable
              style={styles.modalBackdropCenter}
              onPress={() => setIsEditOpen(false)}
            >
              <Pressable style={styles.modalCard} onPress={() => {}}>
                <Text style={styles.modalTitle}>Edit thought</Text>
                <LabeledInput
                  label="Automatic thought"
                  placeholder={`e.g. "I'm going to mess this up"`}
                  value={editText}
                  onChangeText={setEditText}
                  autoFocus
                  returnKeyType="done"
                  blurOnSubmit
                />
                <View style={styles.sliderSection}>
                  <Text style={styles.sliderLabel}>
                    How strongly did you believe this?
                  </Text>
                  <Slider
                    minimumValue={0}
                    maximumValue={100}
                    step={1}
                    value={editBelief}
                    onValueChange={setEditBelief}
                    minimumTrackTintColor={theme.accent}
                    maximumTrackTintColor={theme.muted}
                    thumbTintColor={theme.accent}
                  />
                  <Text style={styles.hint}>0 = not at all, 100 = completely</Text>
                </View>
                <View style={styles.modalActions}>
                  <Pressable onPress={() => setIsEditOpen(false)} hitSlop={8}>
                    <Text style={styles.modalCancel}>Cancel</Text>
                  </Pressable>
                  <PrimaryButton
                    label="Save"
                    onPress={handleSaveEdit}
                    disabled={!editText.trim()}
                    style={styles.modalSaveButton}
                  />
                </View>
              </Pressable>
            </Pressable>
          </Modal>

          <Modal
            visible={confirmId !== null}
            transparent
            animationType="fade"
            onRequestClose={() => setConfirmId(null)}
          >
            <Pressable
              style={styles.modalBackdropCenter}
              onPress={() => setConfirmId(null)}
            >
              <Pressable style={styles.confirmCard} onPress={() => {}}>
                <Text style={styles.modalTitle}>Remove thought?</Text>
                <Text style={styles.confirmBody}>
                  This will delete it from your list.
                </Text>
                <View style={styles.confirmActions}>
                  <Pressable onPress={() => setConfirmId(null)} hitSlop={8}>
                    <Text style={styles.modalCancel}>Cancel</Text>
                  </Pressable>
                  <Pressable onPress={handleConfirmRemove} hitSlop={8}>
                    <Text style={styles.destructiveText}>Remove</Text>
                  </Pressable>
                </View>
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
    modalBackdropCenter: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.35)",
      justifyContent: "center",
      paddingHorizontal: 16
    },
    modalCard: {
      backgroundColor: theme.card,
      padding: 16,
      borderRadius: 16
    },
    confirmCard: {
      backgroundColor: theme.card,
      padding: 16,
      borderRadius: 14,
      marginHorizontal: 24
    },
    modalTitle: {
      fontSize: 16,
      color: theme.textPrimary,
      marginBottom: 12
    },
    modalActions: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    modalCancel: {
      fontSize: 14,
      color: theme.textSecondary
    },
    modalSaveButton: {
      flex: 1,
      marginLeft: 12
    },
    confirmBody: {
      fontSize: 13,
      color: theme.textSecondary,
      marginBottom: 16,
      lineHeight: 18
    },
    confirmActions: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    destructiveText: {
      fontSize: 14,
      color: "#E24A4A"
    }
  });
