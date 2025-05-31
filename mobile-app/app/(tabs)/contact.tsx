import { View, Text, StyleSheet } from "react-native";

export default function ContactScreen() {
  return (
    <View style={styles.page}>
      <Text style={styles.title}>📞 Contact Us</Text>
      <Text>Email: contact@hfaacademy.com</Text>
      <Text>Phone: 01000000000</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  page: { flex: 1, justifyContent: "center", alignItems: "center", padding: 20 },
  title: { fontSize: 20, fontWeight: "bold", marginBottom: 12 },
});
