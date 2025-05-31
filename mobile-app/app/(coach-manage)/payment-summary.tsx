import { View, Text, FlatList, StyleSheet, TouchableOpacity } from "react-native";
import { useEffect, useState } from "react";
import { useRouter } from "expo-router";
import api from "../../utils/api";
import { Ionicons } from "@expo/vector-icons";

export default function PaymentSummaryScreen() {
  const [summary, setSummary] = useState<any[]>([]);
  const [dates, setDates] = useState<string[]>([]);
  const router = useRouter();

  useEffect(() => {
    const load = async () => {
      const me = await api.get("/users/me");
      const branchId = me.data.branch_id;
      const res = await api.get(`/payments/summary/${branchId}`);
      setSummary(res.data.records || []);
      setDates(res.data.session_dates || []);
    };

    load();
  }, []);

  return (
    <View style={styles.container}>
      <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
        <Ionicons name="arrow-back" size={24} color="#007AFF" />
      </TouchableOpacity>
      <Text style={styles.title}>📊 Payment Summary</Text>

      <FlatList
        data={summary}
        keyExtractor={(item) => item.athlete_id.toString()}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <Text style={styles.name}>{item.athlete_name}</Text>
            {dates.map(date => (
              <Text key={date} style={styles.detail}>
                {date}: {item.statuses?.[date] || "pending"}
              </Text>
            ))}
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingTop: 60, paddingHorizontal: 20 },
  backButton: { marginBottom: 10 },
  title: { fontSize: 22, fontWeight: "700", marginBottom: 20 },
  card: {
    backgroundColor: "#fff",
    padding: 15,
    borderRadius: 10,
    marginBottom: 15,
  },
  name: { fontWeight: "600", fontSize: 16, marginBottom: 5 },
  detail: { fontSize: 14, color: "#444" },
});