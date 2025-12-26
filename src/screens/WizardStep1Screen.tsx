import React from "react";
import { View, Text, Button, StyleSheet } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { useWizard } from "../context/WizardContext";
import { WizardProgress } from "../components/WizardProgress";

export const WizardStep1Screen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep1">
> = ({ navigation }) => {
  const { draft, persistDraft } = useWizard();

  return (
    <View style={styles.container}>
      <WizardProgress step={1} total={7} />
      <Text style={styles.title}>Date & Time</Text>
      <Text style={styles.value}>{draft.createdAt}</Text>

      <View style={styles.actions}>
        <Button
          title="Next"
          onPress={async () => {
            await persistDraft();
            navigation.navigate("WizardStep2");
          }}
        />
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
    fontSize: 18,
    marginBottom: 12,
    color: "#2F2F2F"
  },
  value: {
    fontSize: 14,
    color: "#4A4A4A"
  },
  actions: {
    marginTop: 24
  }
});
