import React, { useEffect, useMemo, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  Platform,
  Pressable,
  Modal,
  Switch
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import DateTimePicker from "@react-native-community/datetimepicker";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { RootStackParamList } from "../navigation/AppNavigator";
import { useWizard } from "../context/WizardContext";
import { WizardProgress } from "../components/WizardProgress";
import { useTheme } from "../context/ThemeProvider";
import { ThemeTokens } from "../theme/theme";

export const DateTimeScreen: React.FC<
  NativeStackScreenProps<RootStackParamList, "WizardStep1">
> = ({ navigation }) => {
  const { draft, persistDraft } = useWizard();
  const { theme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const [selectedDate, setSelectedDate] = useState(new Date(draft.createdAt));
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [useCurrent, setUseCurrent] = useState(true);

  useEffect(() => {
    setSelectedDate(new Date(draft.createdAt));
  }, [draft.createdAt]);

  useEffect(() => {
    if (useCurrent) {
      setSelectedDate(new Date());
    }
  }, [useCurrent]);

  const handleDateChange = (event: unknown, date?: Date) => {
    if (date) {
      const next = new Date(selectedDate);
      next.setFullYear(date.getFullYear(), date.getMonth(), date.getDate());
      setSelectedDate(next);
    }
    setShowDatePicker(false);
  };

  const handleTimeChange = (event: unknown, date?: Date) => {
    if (date) {
      const next = new Date(selectedDate);
      next.setHours(date.getHours(), date.getMinutes(), 0, 0);
      setSelectedDate(next);
    }
    setShowTimePicker(false);
  };

  const formattedDate = selectedDate.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric"
  });
  const formattedTime = selectedDate.toLocaleTimeString(undefined, {
    hour: "numeric",
    minute: "2-digit"
  });

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <WizardProgress step={1} total={6} />
        <Text style={styles.title}>Date & Time</Text>
        <Text style={styles.subTitle}>
          When you noticed your mood change. If unsure, leave it as now.
        </Text>

        <View style={styles.card}>
          <View style={styles.toggleRow}>
            <Text style={styles.toggleLabel}>Use current date & time</Text>
            <Switch value={useCurrent} onValueChange={setUseCurrent} />
          </View>

          <Pressable
            style={styles.row}
            onPress={() => {
              if (!useCurrent) {
                setShowDatePicker(true);
              }
            }}
          >
            <View style={styles.iconBubble}>
              <Text style={styles.iconText}>D</Text>
            </View>
            <View style={styles.rowText}>
              <Text style={styles.rowLabel}>Date</Text>
              <Text style={styles.rowValue}>{formattedDate}</Text>
            </View>
          </Pressable>

          <Pressable
            style={styles.row}
            onPress={() => {
              if (!useCurrent) {
                setShowTimePicker(true);
              }
            }}
          >
            <View style={styles.iconBubble}>
              <Text style={styles.iconText}>T</Text>
            </View>
            <View style={styles.rowText}>
              <Text style={styles.rowLabel}>Time</Text>
              <Text style={styles.rowValue}>{formattedTime}</Text>
            </View>
          </Pressable>
        </View>

        <Modal
          visible={showDatePicker}
          transparent
          animationType="slide"
          onRequestClose={() => setShowDatePicker(false)}
        >
          <Pressable
            style={styles.modalBackdrop}
            onPress={() => setShowDatePicker(false)}
          >
            <Pressable style={styles.modalSheet}>
              <DateTimePicker
                mode="date"
                value={selectedDate}
                onChange={handleDateChange}
                display={Platform.OS === "ios" ? "inline" : "default"}
              />
            </Pressable>
          </Pressable>
        </Modal>

        <Modal
          visible={showTimePicker}
          transparent
          animationType="slide"
          onRequestClose={() => setShowTimePicker(false)}
        >
          <Pressable
            style={styles.modalBackdrop}
            onPress={() => setShowTimePicker(false)}
          >
            <Pressable style={styles.modalSheet}>
              <DateTimePicker
                mode="time"
                value={selectedDate}
                onChange={handleTimeChange}
                display={Platform.OS === "ios" ? "spinner" : "default"}
              />
            </Pressable>
          </Pressable>
        </Modal>
      </View>

      <View style={styles.bottomBar}>
        <Pressable
          style={styles.primaryButton}
          onPress={async () => {
            await persistDraft({
              ...draft,
              createdAt: selectedDate.toISOString()
            });
            navigation.navigate("WizardStep2");
          }}
        >
          <Text style={styles.primaryButtonText}>Next</Text>
        </Pressable>
      </View>
    </SafeAreaView>
  );
};

const createStyles = (theme: ThemeTokens) =>
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.background
    },
    content: {
      flex: 1,
      padding: 16
    },
    title: {
      fontSize: 20,
      marginBottom: 6,
      color: theme.textPrimary
    },
    subTitle: {
      fontSize: 13,
      color: theme.textSecondary,
      marginBottom: 16,
      lineHeight: 18
    },
    card: {
      backgroundColor: theme.card,
      borderRadius: 12,
      borderWidth: 1,
      borderColor: theme.border,
      padding: 12
    },
    toggleRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingBottom: 12,
      borderBottomWidth: 1,
      borderBottomColor: theme.muted
    },
    toggleLabel: {
      fontSize: 14,
      color: theme.textPrimary
    },
    row: {
      flexDirection: "row",
      alignItems: "center",
      paddingVertical: 14,
      borderBottomWidth: 1,
      borderBottomColor: theme.muted
    },
    rowText: {
      marginLeft: 12
    },
    rowLabel: {
      fontSize: 12,
      color: theme.textSecondary
    },
    rowValue: {
      fontSize: 16,
      color: theme.textPrimary,
      marginTop: 2
    },
    iconBubble: {
      width: 28,
      height: 28,
      borderRadius: 14,
      backgroundColor: theme.muted,
      alignItems: "center",
      justifyContent: "center"
    },
    iconText: {
      fontSize: 12,
      color: theme.textSecondary
    },
    modalBackdrop: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.25)",
      justifyContent: "flex-end"
    },
    modalSheet: {
      backgroundColor: theme.card,
      padding: 16,
      borderTopLeftRadius: 16,
      borderTopRightRadius: 16
    },
    bottomBar: {
      padding: 16,
      borderTopWidth: 1,
      borderTopColor: theme.border,
      backgroundColor: theme.background
    },
    primaryButton: {
      backgroundColor: theme.accent,
      borderRadius: 10,
      alignItems: "center",
      paddingVertical: 14
    },
    primaryButtonText: {
      color: theme.onAccent,
      fontSize: 16
    }
  });
