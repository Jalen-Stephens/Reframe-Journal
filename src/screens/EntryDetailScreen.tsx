import React, { useEffect, useMemo, useState } from "react";
import { View, Text, Button, ScrollView, StyleSheet } from "react-native";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { ThoughtRecord } from "../models/ThoughtRecord";
import { getThoughtRecordById } from "../storage/thoughtRecordsRepo";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

export const EntryDetailScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "EntryDetail">
> = ({ route }) => {
  const [record, setRecord] = useState<ThoughtRecord | null>(null);
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  useEffect(() => {
    getThoughtRecordById(route.params.id).then(setRecord);
  }, [route.params.id]);

  if (!record) {
    return (
      <View style={styles.container}>
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Entry Detail</Text>
      <Text style={styles.label}>Situation</Text>
      <Text style={styles.value}>{record.situationText}</Text>

      <Text style={styles.label}>Automatic Thoughts</Text>
      {record.automaticThoughts.map((thought) => (
        <Text key={thought.id} style={styles.value}>{
          `${thought.text} (${thought.beliefBefore}%)`
        }</Text>
      ))}

      <Text style={styles.label}>Emotions</Text>
      {record.emotions.map((emotion) => (
        <Text key={emotion.id} style={styles.value}>{
          `${emotion.label} (${emotion.intensityBefore}%)`
        }</Text>
      ))}

      <View style={styles.editButton}>
        <Button
          title="Edit (coming soon)"
          onPress={() => {}}
          color={theme.accent}
        />
      </View>

      <Text style={styles.footerNote}>
        AI assist and biometric lock hooks will be added later.
      </Text>
    </ScrollView>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      flex: 1,
      padding: 16,
      backgroundColor: theme.background
    },
    loadingText: {
      color: theme.textSecondary
    },
    title: {
      fontSize: 20,
      marginBottom: 16,
      color: theme.textPrimary
    },
    label: {
      fontSize: 14,
      color: theme.textSecondary,
      marginTop: 12
    },
    value: {
      fontSize: 14,
      color: theme.textPrimary,
      marginTop: 4
    },
    editButton: {
      marginTop: 24
    },
    footerNote: {
      marginTop: 20,
      fontSize: 12,
      color: theme.textSecondary
    }
  });
