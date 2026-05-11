
// ✅ FILE: app/(coach-manage)/payment.tsx
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
import { useRouter, useLocalSearchParams } from "expo-router";
import api from "../../utils/api";
import { useAuth } from "../../context/auth";

export default function CoachPayments() {
  const [records, setRecords] = useState<any[]>([]);
  const [sessionDates, setSessionDates] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const router = useRouter();
  const { user } = useAuth();
  const { override_branch } = useLocalSearchParams();

  const branchId = override_branch || user?.branch_id;

  const fetchSummary = async () => {
    try {
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
  }, [branchId]);

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
                    {["paid", "pending", "late"].map((status) => (
                      <TouchableOpacity
                        key={status}
                        style={[styles.statusBtn, currentStatus === status && styles.activeStatus]}
                        onPress={() => markPayment(item.athlete_id, date, status)}
                      >
                        <Text style={styles.statusText}>{status[0].toUpperCase()}</Text>
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
  page: { flex: 1, paddingTop: 60, paddingHorizontal: 20 },
  backButton: { marginBottom: 10 },
  title: { fontSize: 22, fontWeight: "bold", marginBottom: 20 },
  search: {
    backgroundColor: "#fff",
    borderRadius: 10,
    borderColor: "#ccc",
    borderWidth: 1,
    padding: 10,
    marginBottom: 15,
  },
  card: {
    backgroundColor: "#fff",
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    elevation: 2,
  },
  name: { fontWeight: "600", fontSize: 16, marginBottom: 8 },
  row: { flexDirection: "row", justifyContent: "space-between", marginBottom: 6 },
  date: { fontSize: 14, color: "#555" },
  statusRow: { flexDirection: "row", gap: 6 },
  statusBtn: {
    backgroundColor: "#eee",
    padding: 8,
    borderRadius: 6,
    minWidth: 40,
    alignItems: "center",
  },
  activeStatus: { backgroundColor: "#007AFF" },
  statusText: { color: "#fff", fontWeight: "bold" },
  empty: { textAlign: "center", marginTop: 20, color: "#999" },
  loading: { flex: 1, justifyContent: "center", alignItems: "center" },
});