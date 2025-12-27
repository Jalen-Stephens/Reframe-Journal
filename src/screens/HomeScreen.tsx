import React, { useCallback, useMemo, useState } from "react";
import { View, Text, Button, FlatList, Pressable, StyleSheet } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useFocusEffect } from "@react-navigation/native";
import { RootStackParamList } from "../navigation/AppNavigator";
import { EntryListItem } from "../components/EntryListItem";
import { ThoughtRecord } from "../models/ThoughtRecord";
import { getDraft, listThoughtRecords } from "../storage/thoughtRecordsRepo";
import { useWizard } from "../context/WizardContext";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

export const HomeScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "Home">
> = ({ navigation }) => {
  const [entries, setEntries] = useState<ThoughtRecord[]>([]);
  const [hasDraft, setHasDraft] = useState(false);
  const { clearDraft } = useWizard();
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

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
      <View style={styles.header}>
        <Text style={styles.title}>Reframe Journal</Text>
        <Pressable
          onPress={() => navigation.navigate("Settings")}
          style={styles.settingsButton}
          accessibilityRole="button"
        >
          <Text style={styles.settingsButtonText}>Settings</Text>
        </Pressable>
      </View>
      <Text style={styles.helper}>
        Capture situations, automatic thoughts, emotions, and outcomes in a
        simple step-by-step flow.
      </Text>
      <View style={styles.actions}>
        <Button
          title="New Thought Record"
          color={theme.accent}
          onPress={async () => {
            await clearDraft();
            navigation.navigate("WizardStep1");
          }}
        />
        {hasDraft ? (
          <View style={styles.draftButton}>
            <Button
              title="Continue Draft"
              color={theme.accent}
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

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      flex: 1,
      padding: 16,
      backgroundColor: theme.background
    },
    header: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between"
    },
    title: {
      fontSize: 22,
      color: theme.textPrimary
    },
    settingsButton: {
      paddingHorizontal: 12,
      paddingVertical: 8,
      borderRadius: 16,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.card
    },
    settingsButtonText: {
      fontSize: 12,
      color: theme.textSecondary
    },
    helper: {
      fontSize: 13,
      color: theme.textSecondary,
      marginBottom: 16,
      lineHeight: 18,
      marginTop: 10
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
      color: theme.textSecondary
    },
    empty: {
      color: theme.textSecondary,
      marginTop: 12
    },
    footerNote: {
      marginTop: 24,
      fontSize: 12,
      color: theme.textSecondary
    }
  });
