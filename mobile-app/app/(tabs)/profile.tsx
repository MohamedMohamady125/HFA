import { View, Text, StyleSheet, FlatList } from "react-native";
import { Ionicons, FontAwesome5 } from "@expo/vector-icons";

const mockUser = {
  name: "Mohamed",
  branch: "Downtown Branch",
  practiceTime: "Mon, Wed, Fri — 4:00 PM to 6:00 PM",
  attendanceThisWeek: [
    { day: "Mon", present: true },
    { day: "Wed", present: false },
    { day: "Fri", present: true },
  ],
  paymentStatus: "✅ Paid for May 2025",
  gear: "🎒 Speedo gear available at Elite Swim Shop (10% off!)",
  lastThreadMessage: "Coach: Don’t forget your water bottle and fins on Friday!",
};

export default function DashboardScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.greeting}>🎉 Welcome back, {mockUser.name}!</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>🏆 Attendance Tracker</Text>
        <View style={styles.attendanceRow}>
          {mockUser.attendanceThisWeek.map((item) => (
            <View key={item.day} style={styles.attendanceBox}>
              <Text style={styles.attendanceDay}>{item.day}</Text>
              <Ionicons
                name={item.present ? "checkmark-circle" : "close-circle"}
                size={32}
                color={item.present ? "green" : "red"}
              />
              <Text style={{ color: item.present ? "green" : "red", fontWeight: "600" }}>
                {item.present ? "Present" : "Absent"}
              </Text>
            </View>
          ))}
        </View>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>🕑 Practice Schedule</Text>
        <Text style={styles.highlightText}>{mockUser.practiceTime}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>🎒 Gear Perks</Text>
        <Text style={styles.highlightText}>{mockUser.gear}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>💬 Latest From Your Coach</Text>
        <View style={styles.chatBubble}>
          <Text>{mockUser.lastThreadMessage}</Text>
        </View>
      </View>

      <View style={[styles.card, styles.paymentCard]}>
        <Text style={styles.cardTitle}>💳 Payment Status</Text>
        <Text style={styles.paid}>{mockUser.paymentStatus}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingTop: 60, paddingHorizontal: 20 },
  greeting: { fontSize: 22, fontWeight: "bold", marginBottom: 20 },
  card: {
    backgroundColor: "#fff",
    padding: 15,
    borderRadius: 12,
    marginBottom: 15,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 2,
  },
  cardTitle: { fontSize: 16, fontWeight: "bold", marginBottom: 8 },
  attendanceRow: { flexDirection: "row", justifyContent: "space-around" },
  attendanceBox: { alignItems: "center", gap: 5 },
  attendanceDay: { fontWeight: "bold", marginBottom: 2 },
  highlightText: { fontWeight: "600", fontSize: 15, color: "#007AFF" },
  chatBubble: {
    backgroundColor: "#f1f1f1",
    padding: 12,
    borderRadius: 10,
    borderLeftColor: "#007AFF",
    borderLeftWidth: 4,
  },
  paymentCard: { marginTop: 30 },
  paid: { fontWeight: "600", fontSize: 16, color: "green" },
});
