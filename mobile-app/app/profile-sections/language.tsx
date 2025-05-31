import React, { useState } from "react";
import { View, Text, Switch, StyleSheet } from "react-native";

export default function LanguageTab() {
  const [isArabic, setIsArabic] = useState(false);

  return (
    <View style={styles.container}>
      <Text style={styles.text}>
        Language: {isArabic ? "Arabic" : "English"}
      </Text>
      <Switch value={isArabic} onValueChange={setIsArabic} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: "center", alignItems: "center" },
  text: { fontSize: 20, marginBottom: 10 },
});