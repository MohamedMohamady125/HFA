import { useEffect, useState } from "react";
import {
  View,
  Text,
  TextInput,
  Button,
  StyleSheet,
  Alert,
  ActivityIndicator,
  ScrollView,
  TouchableOpacity,
} from "react-native";
import api from "../../utils/api";
import { useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";

export default function CoachGear() {
  const [branchId, setBranchId] = useState<number | null>(null);
  const [branchName, setBranchName] = useState<string>("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  const router = useRouter();

  useEffect(() => {
    const loadData = async () => {
      try {
        // Get user info with assigned branch_id
        const userRes = await api.get("/users/me");
        const branch_id = userRes.data.branch_id;  // Use branch_id directly

        setBranchId(branch_id);

        // Fetch branch details
        const branchRes = await api.get(`/branches/${branch_id}`);
        setBranchName(branchRes.data.name);

        // Fetch latest gear post for branch
        const gearRes = await api.get(`/gear/${branch_id}`);
        if (gearRes.data?.message) {
          setMessage(gearRes.data.message);
        }
      } catch (err) {
        Alert.alert("Error", "Failed to load gear or branch info.");
      } finally {
        setLoading(false);
      }
    };

    loadData();
  }, []);

  const handlePostGear = async () => {
    if (!message || !branchId) return;

    try {
      setSubmitting(true);
      await api.post(`/gear/${branchId}`, { content: message });
      Alert.alert("✅ Gear Updated", "Gear info has been saved.");
    } catch (err: any) {
      Alert.alert("Error", err.response?.data?.detail || "Failed to post gear.");
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.page}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Ionicons name="arrow-back" size={24} color="#007AFF" />
        </TouchableOpacity>
        <Text style={styles.title}>🧢 Weekly Gear Update</Text>
      </View>
      <Text style={styles.subtitle}>
        Branch: <Text style={{ fontWeight: "bold" }}>{branchName}</Text>
      </Text>

      <TextInput
        placeholder="Enter or edit gear info..."
        value={message}
        onChangeText={setMessage}
        multiline
        numberOfLines={6}
        style={styles.input}
      />

      <Button
        title={submitting ? "Saving..." : "Save Gear Info"}
        onPress={handlePostGear}
        disabled={submitting || !message}
      />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: {
    padding: 20,
    paddingTop: 60,
    backgroundColor: "#f9fafb",
    flexGrow: 1,
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 10,
  },
  backBtn: {
    marginRight: 10,
  },
  title: {
    fontSize: 22,
    fontWeight: "700",
    flex: 1,
    textAlign: "center",
  },
  subtitle: {
    fontSize: 14,
    color: "#64748b",
    textAlign: "center",
    marginBottom: 20,
  },
  input: {
    borderWidth: 1,
    borderColor: "#cbd5e1",
    borderRadius: 10,
    padding: 14,
    backgroundColor: "#ffffff",
    minHeight: 120,
    textAlignVertical: "top",
    marginBottom: 20,
    fontSize: 15,
    color: "#1e293b",
  },
  loading: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
});