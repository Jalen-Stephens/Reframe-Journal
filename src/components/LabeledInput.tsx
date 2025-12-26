import React from "react";
import { View, Text, TextInput, StyleSheet, TextInputProps } from "react-native";

export const LabeledInput: React.FC<
  { label: string } & TextInputProps
> = ({ label, style, ...props }) => {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>{label}</Text>
      <TextInput style={[styles.input, style]} {...props} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    marginBottom: 16
  },
  label: {
    fontSize: 14,
    color: "#4A4A4A",
    marginBottom: 6
  },
  input: {
    borderWidth: 1,
    borderColor: "#D8D8D8",
    padding: 10,
    borderRadius: 6,
    backgroundColor: "#FFFFFF"
  }
});
