import React, { useState } from "react";
import { View, Text, TextInput, StyleSheet, Button, Alert } from "react-native";

export default function MeasurementsTab() {
  const [form, setForm] = useState({
    height: "",
    weight: "",
    armLength: "",
    legLength: "",
    fatPercentage: "",
    musclePercentage: "",
  });

  const handleChange = (field: string, value: string) => {
    setForm(prev => ({ ...prev, [field]: value }));
  };

  const handleSubmit = () => {
    Alert.alert("✅ Measurements saved!", JSON.stringify(form, null, 2));
    // TODO: Send to backend
  };

  const fields = [
    { key: "height", label: "Height (cm)", example: "e.g. 180" },
    { key: "weight", label: "Weight (kg)", example: "e.g. 80" },
    { key: "armLength", label: "Arm Length (cm)", example: "e.g. 60" },
    { key: "legLength", label: "Leg Length (cm)", example: "e.g. 90" },
    { key: "fatPercentage", label: "Body Fat %", example: "e.g. 15" },
    { key: "musclePercentage", label: "Muscle %", example: "e.g. 45" },
  ];

  return (
    <View style={styles.container}>
      {fields.map(({ key, label, example }) => (
        <View key={key} style={styles.inputWrapper}>
          <Text style={styles.label}>{label}</Text>
          <TextInput
            placeholder={example}
            value={form[key as keyof typeof form]}
            onChangeText={(value) => handleChange(key, value)}
            style={styles.input}
            keyboardType="numeric"
          />
        </View>
      ))}
      <Button title="Save" onPress={handleSubmit} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { padding: 20 },
  inputWrapper: { marginBottom: 15 },
  label: { fontWeight: "600", marginBottom: 4 },
  input: {
    borderBottomWidth: 1,
    borderColor: "#ccc",
    paddingVertical: 6,
    fontSize: 16,
  },
});