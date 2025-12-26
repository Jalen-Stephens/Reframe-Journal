import React from "react";
import { View, Text, Button, Pressable, StyleSheet } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { WizardProgress } from "../components/WizardProgress";
import { useWizard } from "../context/WizardContext";

const THINKING_STYLES = [
  "All-or-Nothing",
  "Catastrophizing",
  "Mind Reading",
  "Personalization",
  "Should Statements"
];

export const WizardStep5Screen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep5">
> = ({ navigation }) => {
  const { draft, setDraft, persistDraft } = useWizard();

  const toggleStyle = (style: string) => {
    setDraft((current) => {
      const currentStyles = current.thinkingStyles || [];
      const exists = currentStyles.includes(style);
      return {
        ...current,
        thinkingStyles: exists
          ? currentStyles.filter((item) => item !== style)
          : [...currentStyles, style]
      };
    });
  };

  return (
    <View style={styles.container}>
      <WizardProgress step={5} total={7} />
      <Text style={styles.title}>Thinking Styles (optional)</Text>
      {THINKING_STYLES.map((style) => {
        const selected = (draft.thinkingStyles || []).includes(style);
        return (
          <Pressable
            key={style}
            onPress={() => toggleStyle(style)}
            style={[styles.item, selected && styles.itemSelected]}
          >
            <Text style={styles.itemText}>{style}</Text>
          </Pressable>
        );
      })}

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
              navigation.navigate("WizardStep6");
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
  title: {
    fontSize: 16,
    marginBottom: 12,
    color: "#4A4A4A"
  },
  item: {
    padding: 12,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: "#D8D8D8",
    marginBottom: 8
  },
  itemSelected: {
    backgroundColor: "#EAF1EA",
    borderColor: "#B8C4B8"
  },
  itemText: {
    color: "#3A3A3A"
  },
  actions: {
    marginTop: 16
  },
  actionButton: {
    marginBottom: 8
  }
});
