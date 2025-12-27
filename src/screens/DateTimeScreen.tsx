import React, { useMemo, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  Platform,
  Pressable,
  Modal
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
  const { theme, resolvedTheme } = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const [selectedDate, setSelectedDate] = useState(() => new Date());
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);

  const handleDateChange = (event: unknown, date?: Date) => {
    if (Platform.OS === "android") {
      setShowDatePicker(false);
    }
    if (date) {
      const next = new Date(selectedDate);
      next.setFullYear(date.getFullYear(), date.getMonth(), date.getDate());
      setSelectedDate(next);
    }
  };

  const handleTimeChange = (event: unknown, date?: Date) => {
    if (Platform.OS === "android") {
      setShowTimePicker(false);
    }
    if (date) {
      const next = new Date(selectedDate);
      next.setHours(date.getHours(), date.getMinutes(), 0, 0);
      setSelectedDate(next);
    }
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
    <View style={styles.container}>
      <View style={styles.content}>
        <WizardProgress step={1} total={6} />
        <Text style={styles.title}>Date & Time</Text>
        <Text style={styles.subTitle}>
          When you noticed your mood change. If unsure, leave it as now.
        </Text>

        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <Text style={styles.cardTitle}>Selected</Text>
            <Pressable
              accessibilityRole="button"
              hitSlop={8}
              onPress={() => setSelectedDate(new Date())}
            >
              <Text style={styles.resetText}>Reset to now</Text>
            </Pressable>
          </View>

          <Pressable
            style={styles.row}
            accessibilityRole="button"
            accessibilityLabel="Select date"
            onPress={() => setShowDatePicker(true)}
          >
            <View style={styles.rowText}>
              <Text style={styles.rowLabel}>Date</Text>
              <Text style={styles.rowValue}>{formattedDate}</Text>
            </View>
            <Text style={styles.chevron}>{">"}</Text>
          </Pressable>

          <Pressable
            style={styles.row}
            accessibilityRole="button"
            accessibilityLabel="Select time"
            onPress={() => setShowTimePicker(true)}
          >
            <View style={styles.rowText}>
              <Text style={styles.rowLabel}>Time</Text>
              <Text style={styles.rowValue}>{formattedTime}</Text>
            </View>
            <Text style={styles.chevron}>{">"}</Text>
          </Pressable>
        </View>

        {Platform.OS === "ios" ? (
          <>
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
                {/* iOS inline calendar is low-contrast in light mode; use spinner in a modal card. */}
                <Pressable style={styles.modalSheet}>
                  <SafeAreaView edges={["bottom"]}>
                    <Text style={styles.modalTitle}>Select date</Text>
                  <DateTimePicker
                    mode="date"
                    value={selectedDate}
                    onChange={handleDateChange}
                    display="inline"
                    textColor={theme.textPrimary}
                    themeVariant={resolvedTheme}
                  />
                    <Pressable
                      accessibilityRole="button"
                      style={styles.modalDone}
                      onPress={() => setShowDatePicker(false)}
                    >
                      <Text style={styles.modalDoneText}>Done</Text>
                    </Pressable>
                  </SafeAreaView>
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
                  <SafeAreaView edges={["bottom"]}>
                    <Text style={styles.modalTitle}>Select time</Text>
                  <DateTimePicker
                    mode="time"
                    value={selectedDate}
                    onChange={handleTimeChange}
                    display="spinner"
                    textColor={theme.textPrimary}
                    themeVariant={resolvedTheme}
                  />
                    <Pressable
                      accessibilityRole="button"
                      style={styles.modalDone}
                      onPress={() => setShowTimePicker(false)}
                    >
                      <Text style={styles.modalDoneText}>Done</Text>
                    </Pressable>
                  </SafeAreaView>
                </Pressable>
              </Pressable>
            </Modal>
          </>
        ) : (
          <>
            {showDatePicker ? (
              <DateTimePicker
                mode="date"
                value={selectedDate}
                onChange={handleDateChange}
                display="default"
              />
            ) : null}
            {showTimePicker ? (
              <DateTimePicker
                mode="time"
                value={selectedDate}
                onChange={handleTimeChange}
                display="default"
              />
            ) : null}
          </>
        )}
      </View>

      <SafeAreaView edges={["bottom"]} style={styles.bottomBar}>
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
      </SafeAreaView>
    </View>
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
      fontSize: 16,
      marginBottom: 12,
      color: theme.textPrimary
    },
    subTitle: {
      fontSize: 13,
      color: theme.textSecondary,
      marginBottom: 12,
      lineHeight: 18
    },
    card: {
      backgroundColor: theme.card,
      borderRadius: 12,
      borderWidth: 1,
      borderColor: theme.border,
      padding: 10
    },
    cardHeader: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingBottom: 8
    },
    cardTitle: {
      fontSize: 13,
      color: theme.textSecondary
    },
    resetText: {
      fontSize: 13,
      color: theme.accent
    },
    row: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingVertical: 12,
      borderBottomWidth: 1,
      borderBottomColor: theme.muted
    },
    rowText: {
      flex: 1
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
    chevron: {
      marginLeft: 12,
      fontSize: 18,
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
    modalTitle: {
      fontSize: 14,
      color: theme.textPrimary,
      marginBottom: 8
    },
    modalDone: {
      alignSelf: "flex-end",
      paddingVertical: 8,
      paddingHorizontal: 6
    },
    modalDoneText: {
      fontSize: 14,
      color: theme.accent
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
