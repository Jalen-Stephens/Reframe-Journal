import React from "react";
import { Text, Pressable, StyleSheet, View } from "react-native";
import { ThoughtRecord } from "../models/ThoughtRecord";
import { formatDateShort } from "../utils/date";

export const EntryListItem: React.FC<{
  item: ThoughtRecord;
  onPress: () => void;
}> = ({ item, onPress }) => {
  const topEmotion = item.emotions[0]?.label || "";
  const beliefChange =
    item.automaticThoughts[0] && item.beliefAfterMainThought !== undefined
      ? `${item.automaticThoughts[0].beliefBefore} → ${item.beliefAfterMainThought}`
      : "";

  return (
    <Pressable onPress={onPress} style={styles.container}>
      <Text style={styles.date}>{formatDateShort(item.createdAt)}</Text>
      {topEmotion ? <Text style={styles.meta}>{topEmotion}</Text> : null}
      {beliefChange ? <Text style={styles.meta}>{beliefChange}</Text> : null}
    </Pressable>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: "#EDEDED"
  },
  date: {
    fontSize: 16,
    color: "#2F2F2F"
  },
  meta: {
    fontSize: 13,
    color: "#6B6B6B",
    marginTop: 4
  }
});
