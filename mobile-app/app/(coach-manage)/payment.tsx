import { useEffect, useState } from "react";
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
  StyleSheet,
  TextInput,
  SafeAreaView,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import api from "../../utils/api";

export default function CoachPayments() {
  const [records, setRecords] = useState<any[]>([]);
  const [sessionDates, setSessionDates] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const router = useRouter();

  const fetchSummary = async () => {
    try {
      const me = await api.get("/users/me");
      const branchId = me.data.branch_id;
      const res = await api.get(`/payments/summary/${branchId}`);
      setRecords(res.data.records ?? []);
      setSessionDates(res.data.session_dates ?? []);
    } catch (err) {
      console.error("Error loading payment summary", err);
      Alert.alert("Error", "Could not load payment summary.");
    } finally {
      setLoading(false);
    }
  };

  const markPayment = async (athleteId: number, date: string, status: string) => {
    try {
      await api.post(`/payments/mark`, {
        athlete_id: athleteId,
        session_date: date,
        status,
      });
      fetchSummary();
    } catch (err) {
      console.error("Failed to update payment", err);
      Alert.alert("Error", "Could not update payment status.");
    }
  };

  useEffect(() => {
    fetchSummary();
  }, []);

  const sorted = records.sort((a, b) => a.athlete_name.localeCompare(b.athlete_name));

  if (loading) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.page}>
      <TouchableOpacity onPress={() => router.push("/(coach-tabs)/home")} style={styles.backButton}>
        <Ionicons name="arrow-back" size={26} color="#007AFF" />
      </TouchableOpacity>

      <Text style={styles.title}>💵 Payment Tracking</Text>

      <TouchableOpacity
        style={styles.summaryButton}
        onPress={() => router.push("/(coach-manage)/payment-summary")}
      >
        <Text style={styles.summaryButtonText}>📊 View Payment Summary</Text>
      </TouchableOpacity>

      <TextInput
        placeholder="Search athlete..."
        value={search}
        onChangeText={setSearch}
        style={styles.search}
      />

      <FlatList
        data={sorted.filter((item: any) =>
          item.athlete_name.toLowerCase().includes(search.toLowerCase())
        )}
        keyExtractor={(item) => item.athlete_id.toString()}
        ListEmptyComponent={<Text style={styles.empty}>No athletes found.</Text>}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <Text style={styles.name}>{item.athlete_name}</Text>
            {sessionDates.map((date) => {
              const currentStatus = item.statuses?.[date] ?? "pending";
              return (
                <View key={date} style={styles.row}>
                  <Text style={styles.date}>{date}</Text>
                  <View style={styles.statusRow}>
                    {[
                      { status: "paid", icon: "✅" },
                      { status: "pending", icon: "❌" },
                      { status: "late", icon: "⚠️" },
                    ].map(({ status, icon }) => (
                      <TouchableOpacity
                        key={status}
                        style={[
                          styles.statusBtn,
                          currentStatus === status && styles.activeStatus,
                        ]}
                        onPress={() => markPayment(item.athlete_id, date, status)}
                      >
                        <Text style={styles.statusText}>{icon}</Text>
                      </TouchableOpacity>
                    ))}
                  </View>
                </View>
              );
            })}
          </View>
        )}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  page: {
    flex: 1,
    backgroundColor: "#f5f9ff",
    paddingTop: 60,
    paddingHorizontal: 20,
  },
  backButton: {
    marginBottom: 10,
    alignSelf: "flex-start",
  },
  title: {
    fontSize: 24,
    fontWeight: "700",
    marginBottom: 15,
    color: "#1a1a1a",
    textAlign: "center",
  },
  summaryButton: {
    backgroundColor: "#FFD700",
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: "center",
    marginBottom: 20,
  },
  summaryButtonText: {
    color: "#333",
    fontWeight: "600",
    fontSize: 16,
  },
  search: {
    backgroundColor: "#fff",
    padding: 10,
    borderRadius: 10,
    borderColor: "#ccc",
    borderWidth: 1,
    marginBottom: 15,
  },
  card: {
    backgroundColor: "#fff",
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    elevation: 2,
    shadowColor: "#000",
    shadowOpacity: 0.08,
    shadowOffset: { width: 0, height: 2 },
  },
  name: {
    fontWeight: "600",
    fontSize: 16,
    marginBottom: 8,
  },
  row: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 8,
  },
  date: {
    fontSize: 14,
    color: "#555",
  },
  statusRow: {
    flexDirection: "row",
    gap: 8,
  },
  statusBtn: {
    backgroundColor: "#eee",
    paddingVertical: 6,
    paddingHorizontal: 10,
    borderRadius: 8,
    alignItems: "center",
    justifyContent: "center",
    minWidth: 40,
  },
  activeStatus: {
    backgroundColor: "#007AFF",
  },
  statusText: {
    fontSize: 18,
    color: "#fff",
  },
  empty: {
    textAlign: "center",
    color: "#999",
    fontSize: 16,
    marginTop: 20,
  },
  loading: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
});