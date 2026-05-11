import { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  Button,
  ScrollView,
  ActivityIndicator,
  Alert,
  TouchableOpacity,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import api from "../../utils/api";
import { useRouter } from "expo-router";

export default function CoachRequests() {
  const [requests, setRequests] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

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

  const handleApprove = async (requestId: number) => {
    try {
      await api.post(`/users/approve/${requestId}`);
      Alert.alert("Approved", "Athlete has been approved.");
      fetchRequests();
    } catch {
      Alert.alert("Error", "Failed to approve athlete");
    }
  };

  const handleReject = async (requestId: number) => {
    Alert.alert(
      "Confirm Reject",
      "This will permanently reject the registration request.",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Reject",
          style: "destructive",
          onPress: async () => {
            try {
              await api.post(`/users/reject/${requestId}`);
              Alert.alert("Rejected", "The request was rejected.");
              fetchRequests();
            } catch {
              Alert.alert("Error", "Failed to reject the request");
            }
          },
        },
      ]
    );
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
      <TouchableOpacity onPress={() => router.push("/(coach-tabs)/home")} style={styles.backButton}>
        <Ionicons name="arrow-back" size={24} color="#007AFF" />
      </TouchableOpacity>

      <Text style={styles.title}>📝 Pending Registration Requests</Text>
      {requests.length === 0 ? (
        <Text>No pending requests.</Text>
      ) : (
        requests.map((req, idx) => (
          <View key={idx} style={styles.card}>
            <Text style={styles.label}>📧 {req.email}</Text>
            <Text style={styles.label}>📱 {req.phone}</Text>
            <Text style={styles.label}>🧍 {req.athlete_name}</Text>
            <Button title="Approve" onPress={() => handleApprove(req.id)} />
            <Button title="Reject" onPress={() => handleReject(req.id)} color="red" />
          </View>
        ))
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: { padding: 20, paddingTop: 60 },
  backButton: { marginBottom: 10 },
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