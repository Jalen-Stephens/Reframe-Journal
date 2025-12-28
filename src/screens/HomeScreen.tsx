import React, { useCallback, useMemo, useState } from "react";
import { View, Text, FlatList, Pressable, StyleSheet } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useFocusEffect } from "@react-navigation/native";
import { RootStackParamList } from "../navigation/AppNavigator";
import { EntryListItem } from "../components/EntryListItem";
import { ThoughtRecord } from "../models/ThoughtRecord";
import { getDraft, listThoughtRecords } from "../storage/thoughtRecordsRepo";
import { useWizard } from "../context/WizardContext";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";
import { formatRelativeDate } from "../utils/date";

export const HomeScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "Home">
> = ({ navigation }) => {
  const [entries, setEntries] = useState<ThoughtRecord[]>([]);
  const [hasDraft, setHasDraft] = useState(false);
  const { clearDraft } = useWizard();
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const latestEntry = entries[0];
  const latestSituation =
    latestEntry?.situationText?.trim() || "Untitled situation";

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
        Ground yourself and gently work through a moment, step by step.
      </Text>
      {latestEntry ? (
        <Text style={styles.lastWorked}>
          Last worked on: {latestSituation} ·{" "}
          {formatRelativeDate(latestEntry.createdAt)}
        </Text>
      ) : null}
      <View style={styles.actions}>
        <Pressable
          onPress={async () => {
            await clearDraft();
            navigation.navigate("WizardStep1");
          }}
          accessibilityRole="button"
          style={({ pressed }) => [
            styles.primaryCard,
            pressed && styles.primaryCardPressed
          ]}
        >
          <Text style={styles.primaryCardTitle}>New thought record</Text>
          <Text style={styles.primaryCardCopy}>
            Work through a difficult moment step by step.
          </Text>
        </Pressable>
        {hasDraft ? (
          <Pressable
            onPress={() => navigation.navigate("WizardStep1")}
            accessibilityRole="button"
            style={({ pressed }) => [
              styles.secondaryCard,
              pressed && styles.secondaryCardPressed
            ]}
          >
            <Text style={styles.secondaryCardTitle}>Continue draft</Text>
            <Text style={styles.secondaryCardCopy}>
              Pick up where you left off.
            </Text>
          </Pressable>
        ) : null}
      </View>

      <Text style={styles.section}>Recent entries</Text>
      <FlatList
        data={entries}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <EntryListItem
            item={item}
            onPress={() => navigation.navigate("EntryDetail", { id: item.id })}
          />
        )}
        contentContainerStyle={styles.listContent}
        ListEmptyComponent={
          <Text style={styles.empty}>
            No entries yet. Start a new thought record above.
          </Text>
        }
      />
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
    lastWorked: {
      fontSize: 13,
      color: theme.textSecondary,
      marginBottom: 16
    },
    actions: {
      marginBottom: 20
    },
    primaryCard: {
      backgroundColor: theme.accent,
      borderRadius: 16,
      paddingVertical: 16,
      paddingHorizontal: 16
    },
    primaryCardPressed: {
      opacity: 0.9
    },
    primaryCardTitle: {
      fontSize: 16,
      fontWeight: "600",
      color: theme.onAccent
    },
    primaryCardCopy: {
      marginTop: 6,
      fontSize: 13,
      color: theme.onAccent,
      opacity: 0.9
    },
    secondaryCard: {
      marginTop: 12,
      borderRadius: 14,
      paddingVertical: 12,
      paddingHorizontal: 14,
      borderWidth: 1,
      borderColor: theme.border,
      backgroundColor: theme.card
    },
    secondaryCardPressed: {
      opacity: 0.85
    },
    secondaryCardTitle: {
      fontSize: 14,
      fontWeight: "600",
      color: theme.textPrimary
    },
    secondaryCardCopy: {
      marginTop: 4,
      fontSize: 12,
      color: theme.textSecondary
    },
    section: {
      fontSize: 16,
      marginTop: 8,
      marginBottom: 8,
      color: theme.textSecondary
    },
    listContent: {
      paddingBottom: 20
    },
    empty: {
      color: theme.textSecondary,
      marginTop: 12
    }
  });
