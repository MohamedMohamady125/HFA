import { useEffect, useState } from "react";
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
  SafeAreaView,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import api from "../../utils/api";

export default function RegisterRequestsScreen() {
  const [requests, setRequests] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  const fetchRequests = async () => {
    try {
      const res = await api.get("/users/requests");
      setRequests(res.data);
    } catch (err: any) {
      console.error("❌ Failed to fetch registration requests:", err);
      if (err.response) {
        console.error("📡 Axios response error:", err.response.status, err.response.data);
      }
      Alert.alert("Error", "Failed to fetch registration requests");
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (requestId: number) => {
    try {
      await api.post(`/users/approve/${requestId}`);
      Alert.alert("✅ Approved", "Athlete has been successfully approved.");
      fetchRequests();
    } catch (err) {
      console.error("❌ Failed to approve athlete:", err);
      Alert.alert("Error", "Failed to approve athlete");
    }
  };

  const handleReject = async (requestId: number) => {
    Alert.alert(
      "Are you sure?",
      "This will permanently reject the registration request.",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Reject",
          style: "destructive",
          onPress: async () => {
            try {
              await api.post(`/users/reject/${requestId}`);
              Alert.alert("❌ Rejected", "The request was successfully rejected.");
              fetchRequests();
            } catch (err) {
              console.error("❌ Failed to reject request:", err);
              Alert.alert("Error", "Failed to reject the request.");
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
    <SafeAreaView style={{ flex: 1, backgroundColor: "#f8f9fb" }}>
      <View style={styles.container}>
        <TouchableOpacity onPress={() => router.push("/(coach-tabs)/home")} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color="#007AFF" />
        </TouchableOpacity>

        <Text style={styles.title}>Athlete Requests</Text>

        <FlatList
          data={requests}
          keyExtractor={(item) => item.id.toString()}
          ListEmptyComponent={<Text style={styles.empty}>No pending requests.</Text>}
          renderItem={({ item }) => (
            <View style={styles.card}>
              <Text style={styles.name}>{item.athlete_name}</Text>
              <Text style={styles.detail}>📞 {item.phone}</Text>
              <Text style={styles.detail}>📧 {item.email}</Text>

              <View style={{ flexDirection: "row", gap: 10, marginTop: 16 }}>
                <TouchableOpacity
                  style={styles.approveBtn}
                  onPress={() => handleApprove(item.id)}
                >
                  <Text style={styles.btnText}>Approve</Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={styles.rejectBtn}
                  onPress={() => handleReject(item.id)}
                >
                  <Text style={styles.btnText}>Reject</Text>
                </TouchableOpacity>
              </View>
            </View>
          )}
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 40,
    paddingHorizontal: 20,
  },
  backButton: {
    padding: 8,
    borderRadius: 10,
    backgroundColor: "#eef3f9",
    alignSelf: "flex-start",
    marginBottom: 15,
  },
  title: {
    fontSize: 24,
    fontWeight: "700",
    marginBottom: 20,
    color: "#1e1e2d",
  },
  card: {
    backgroundColor: "#fff",
    borderRadius: 16,
    padding: 20,
    marginBottom: 20,
    shadowColor: "#000",
    shadowOpacity: 0.06,
    shadowOffset: { width: 0, height: 4 },
    shadowRadius: 8,
    elevation: 4,
  },
  name: {
    fontSize: 18,
    fontWeight: "600",
    marginBottom: 6,
    color: "#333",
  },
  detail: {
    fontSize: 15,
    color: "#555",
    marginBottom: 2,
  },
  approveBtn: {
    flex: 1,
    backgroundColor: "#4CAF50",
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: "center",
  },
  rejectBtn: {
    flex: 1,
    backgroundColor: "#D32F2F",
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: "center",
  },
  btnText: {
    color: "#fff",
    fontWeight: "700",
    fontSize: 15,
  },
  empty: {
    marginTop: 40,
    textAlign: "center",
    fontSize: 16,
    color: "#777",
  },
  loading: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
});