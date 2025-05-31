import { View, Text, StyleSheet, Button, Alert } from "react-native";

export default function MassagePage() {
  const handleBook = () => {
    Alert.alert("Booked!", "Your massage session has been requested.");
  };

  return (
    <View style={styles.container}>
      <Text style={styles.header}>💆 Massage Services</Text>

      <View style={styles.card}>
        <Text style={styles.title}>Pre-Meet Massage</Text>
        <Text style={styles.description}>
          Book a massage session 24-48 hours before your next meet to help with muscle recovery and preparation.
        </Text>
        <Button title="Book Session" onPress={handleBook} />
      </View>

      <View style={styles.card}>
        <Text style={styles.title}>💡 What to Expect</Text>
        <Text style={styles.description}>
          Our certified staff provide recovery-focused massage based on swimmer needs and timing before performance.
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20 },
  header: {
    fontSize: 24,
    fontWeight: "bold",
    marginBottom: 20,
    textAlign: "center",
  },
  card: {
    backgroundColor: "#f9f9f9",
    padding: 16,
    borderRadius: 10,
    marginBottom: 20,
    elevation: 2,
  },
  title: {
    fontSize: 18,
    fontWeight: "600",
    marginBottom: 6,
  },
  description: {
    fontSize: 14,
    color: "#555",
    marginBottom: 10,
  },
});