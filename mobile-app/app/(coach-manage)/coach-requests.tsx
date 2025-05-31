// FILE: app/(coach-tabs)/coach-requests.tsx
import { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  Button,
  ScrollView,
  ActivityIndicator,
  Alert,
} from "react-native";
import api from "../../utils/api";

export default function CoachRequests() {
  const [requests, setRequests] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchRequests = async () => {
    try {
      const res = await api.get("/users/requests");
      setRequests(res.data);
    } catch (err: any) {
      Alert.alert("Error", err.response?.data?.detail || "Failed to load requests");
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (email: string) => {
    try {
      await api.post("/users/approve", { email });
      Alert.alert("Approved", `${email} has been approved.`);
      fetchRequests();
    } catch (err: any) {
      Alert.alert("Error", err.response?.data?.detail || "Approval failed");
    }
  };

  useEffect(() => {
    fetchRequests();
  }, []);

  if (loading) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.page}>
      <Text style={styles.title}>📝 Pending Registration Requests</Text>
      {requests.length === 0 ? (
        <Text>No pending requests.</Text>
      ) : (
        requests.map((req, idx) => (
          <View key={idx} style={styles.card}>
            <Text style={styles.label}>📧 {req.email}</Text>
            <Text style={styles.label}>📱 {req.phone}</Text>
            <Text style={styles.label}>🧍 {req.athlete_name}</Text>
            <Button title="Approve" onPress={() => handleApprove(req.email)} />
          </View>
        ))
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: { padding: 20, paddingTop: 60 },
  title: { fontSize: 20, fontWeight: "bold", marginBottom: 20 },
  card: {
    backgroundColor: "#fff",
    padding: 16,
    borderRadius: 10,
    marginBottom: 16,
    elevation: 2,
  },
  label: { marginBottom: 6, fontSize: 14 },
  loading: { flex: 1, justifyContent: "center", alignItems: "center" },
});