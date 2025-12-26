import React from "react";
import { View, Text, StyleSheet } from "react-native";

export const WizardProgress: React.FC<{ step: number; total: number }> = ({
  step,
  total
}) => {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>{`Step ${step} of ${total}`}</Text>
      <View style={styles.track}>
        <View style={[styles.fill, { width: `${(step / total) * 100}%` }]} />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    marginBottom: 16
  },
  text: {
    fontSize: 14,
    color: "#4A4A4A",
    marginBottom: 8
  },
  track: {
    height: 4,
    backgroundColor: "#E0E0E0",
    borderRadius: 2
  },
  fill: {
    height: 4,
    backgroundColor: "#B8C4B8",
    borderRadius: 2
  }
});
