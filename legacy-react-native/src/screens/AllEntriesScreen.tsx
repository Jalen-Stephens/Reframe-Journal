import React, { useCallback, useMemo, useState } from "react";
import {
  View,
  Text,
  SectionList,
  StyleSheet,
  Pressable
} from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useFocusEffect } from "@react-navigation/native";
import { RootStackParamList } from "../navigation/AppNavigator";
import { ThoughtRecord } from "../models/ThoughtRecord";
import { listAllThoughtRecords } from "../storage/thoughtRecordsRepo";
import { EntryListItem } from "../components/EntryListItem";
import { formatRelativeDate } from "../utils/date";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

type SectionData = {
  title: string;
  data: ThoughtRecord[];
};

export const AllEntriesScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "AllEntries">
> = ({ navigation }) => {
  const [entries, setEntries] = useState<ThoughtRecord[]>([]);
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const refresh = useCallback(() => {
    listAllThoughtRecords().then(setEntries);
  }, []);

  useFocusEffect(
    useCallback(() => {
      refresh();
    }, [refresh])
  );

  const sections = useMemo<SectionData[]>(() => {
    const buckets: Record<string, ThoughtRecord[]> = {
      Today: [],
      Yesterday: [],
      Older: []
    };

    entries.forEach((entry) => {
      const label = formatRelativeDate(entry.createdAt);
      if (label === "Today") {
        buckets.Today.push(entry);
      } else if (label === "Yesterday") {
        buckets.Yesterday.push(entry);
      } else {
        buckets.Older.push(entry);
      }
    });

    return Object.entries(buckets)
      .filter(([, data]) => data.length > 0)
      .map(([title, data]) => ({ title, data }));
  }, [entries]);

  return (
    <View style={styles.container}>
      <SectionList
        sections={sections}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <EntryListItem
            item={item}
            onPress={() => navigation.navigate("EntryDetail", { id: item.id })}
          />
        )}
        renderSectionHeader={({ section }) => (
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>{section.title}</Text>
          </View>
        )}
        contentContainerStyle={styles.listContent}
        ListEmptyComponent={
          <View style={styles.emptyState}>
            <Text style={styles.emptyTitle}>No entries yet.</Text>
            <Text style={styles.emptyCopy}>
              Your journal entries will appear here after you finish one.
            </Text>
            <Pressable
              accessibilityRole="button"
              onPress={() => navigation.navigate("Home")}
              style={({ pressed }) => [
                styles.emptyAction,
                pressed && styles.emptyActionPressed
              ]}
            >
              <Text style={styles.emptyActionText}>Back to Home</Text>
            </Pressable>
          </View>
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
    listContent: {
      paddingBottom: 20
    },
    sectionHeader: {
      marginTop: 12,
      marginBottom: 8
    },
    sectionTitle: {
      fontSize: 14,
      color: theme.textSecondary
    },
    emptyState: {
      marginTop: 48,
      alignItems: "center",
      paddingHorizontal: 24
    },
    emptyTitle: {
      fontSize: 16,
      color: theme.textPrimary,
      marginBottom: 6
    },
    emptyCopy: {
      fontSize: 13,
      color: theme.textSecondary,
      textAlign: "center",
      lineHeight: 18
    },
    emptyAction: {
      marginTop: 16,
      paddingHorizontal: 16,
      paddingVertical: 10,
      borderRadius: 999,
      borderWidth: 1,
      borderColor: theme.border
    },
    emptyActionPressed: {
      opacity: 0.85
    },
    emptyActionText: {
      fontSize: 13,
      color: theme.textSecondary
    }
  });
