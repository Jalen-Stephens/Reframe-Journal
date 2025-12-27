import React, { useMemo, useState } from "react";
import {
  View,
  Text,
  Button,
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

export const AutomaticThoughtsScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep3">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const [thoughtText, setThoughtText] = useState("");
  const [beliefValue, setBeliefValue] = useState(50);

  const addThought = () => {
    const belief = clampPercent(beliefValue);
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
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <TouchableWithoutFeedback onPress={Keyboard.dismiss} accessible={false}>
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
        >
          <WizardProgress step={3} total={6} />
          <Text style={styles.helper}>
            What thought/s or image/s went through your mind? How much did you
            believe the thought at the time (0-100%)?
          </Text>
          <LabeledInput
            label="Automatic thought"
            placeholder="I'm going to mess this up"
            value={thoughtText}
            onChangeText={setThoughtText}
            returnKeyType="done"
            blurOnSubmit
          />
          <LabeledSlider
            label="Belief (0-100)"
            value={beliefValue}
            onChange={setBeliefValue}
          />
          <Text style={styles.hint}>0 = not at all, 100 = completely</Text>
          <Button title="Add thought" onPress={addThought} color={theme.accent} />

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
                  navigation.navigate("WizardStep4");
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
    hint: {
      fontSize: 12,
      color: theme.textSecondary,
      marginTop: -6,
      marginBottom: 12
    },
    list: {
      marginTop: 16
    },
    listItem: {
      fontSize: 14,
      color: theme.textSecondary,
      marginBottom: 6
    },
    actions: {
      marginTop: 16
    },
    actionButton: {
      marginBottom: 8
    }
  });
