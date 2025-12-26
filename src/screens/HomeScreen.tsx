import React, { useCallback, useState } from "react";
import { View, Text, Button, FlatList, StyleSheet } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useFocusEffect } from "@react-navigation/native";
import { RootStackParamList } from "../navigation/AppNavigator";
import { EntryListItem } from "../components/EntryListItem";
import { ThoughtRecord } from "../models/ThoughtRecord";
import { getDraft, listThoughtRecords } from "../storage/thoughtRecordsRepo";
import { useWizard } from "../context/WizardContext";

export const HomeScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "Home">
> = ({ navigation }) => {
  const [entries, setEntries] = useState<ThoughtRecord[]>([]);
  const [hasDraft, setHasDraft] = useState(false);
  const { clearDraft } = useWizard();

  const refresh = useCallback(() => {
    listThoughtRecords().then(setEntries);
    getDraft().then((draft) => setHasDraft(Boolean(draft)));
  }, []);

  useFocusEffect(
    useCallback(() => {
      refresh();
    }, [refresh])
  );

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Reframe Journal</Text>
      <View style={styles.actions}>
        <Button
          title="New Thought Record"
          onPress={async () => {
            await clearDraft();
            navigation.navigate("WizardStep1");
          }}
        />
        {hasDraft ? (
          <View style={styles.draftButton}>
            <Button
              title="Continue Draft"
              onPress={() => navigation.navigate("WizardStep1")}
            />
          </View>
        ) : null}
      </View>

      <Text style={styles.section}>Recent Entries</Text>
      <FlatList
        data={entries}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <EntryListItem
            item={item}
            onPress={() => navigation.navigate("EntryDetail", { id: item.id })}
          />
        )}
        ListEmptyComponent={<Text style={styles.empty}>No entries yet.</Text>}
      />

      <Text style={styles.footerNote}>
        Pattern dashboard and insights will live here in a future update.
      </Text>
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
    fontSize: 22,
    marginBottom: 12,
    color: "#2F2F2F"
  },
  actions: {
    marginBottom: 16
  },
  draftButton: {
    marginTop: 8
  },
  section: {
    fontSize: 16,
    marginTop: 8,
    marginBottom: 8,
    color: "#4A4A4A"
  },
  empty: {
    color: "#8A8A8A",
    marginTop: 12
  },
  footerNote: {
    marginTop: 24,
    fontSize: 12,
    color: "#9A9A9A"
  }
});
