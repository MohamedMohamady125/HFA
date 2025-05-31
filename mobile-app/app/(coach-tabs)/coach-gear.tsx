import { useEffect, useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
  StyleSheet,
  ScrollView,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import api from "../../utils/api";
import { useRouter } from "expo-router";

export default function CoachGear() {
  const [branch, setBranch] = useState<{ id: number; name: string } | null>(null);
  const [gearText, setGearText] = useState("");
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    const fetchGear = async () => {
      try {
        const userRes = await api.get("/users/me");
        const branchId = userRes.data.branch_id;
        const branchRes = await api.get(`/branches/${branchId}`);
        setBranch({ id: branchId, name: branchRes.data.name });

        const gearRes = await api.get(`/gear/${branchId}`);
        if (gearRes.data.message) setGearText(gearRes.data.message);
      } catch (err) {
        Alert.alert("Error", "Failed to load gear info.");
      } finally {
        setLoading(false);
      }
    };

    fetchGear();
  }, []);

  const handleUpdateGear = async () => {
    try {
      await api.post(`/gear/${branch?.id}`, { content: gearText });
      Alert.alert("Success", "Gear info updated.");
    } catch (err: any) {
      Alert.alert("Error", err.response?.data?.detail || "Failed to update gear.");
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
      <TouchableOpacity style={styles.backButton} onPress={() => router.push("/(coach-tabs)/home")}>
        <Ionicons name="arrow-back" size={26} color="#007AFF" />
      </TouchableOpacity>

      <Text style={styles.title}>🎒 Gear Poster</Text>
      <Text style={styles.branch}>Branch: {branch?.name}</Text>

      <View style={styles.poster}>
        <Text style={styles.posterTitle}>Current Gear Info</Text>
        <Text style={styles.posterContent}>{gearText || "No gear info posted yet."}</Text>
      </View>

      <Text style={styles.editLabel}>✏️ Edit Gear Info</Text>
      <TextInput
        placeholder="Update gear instructions..."
        value={gearText}
        onChangeText={setGearText}
        multiline
        style={styles.input}
      />

      <TouchableOpacity style={styles.button} onPress={handleUpdateGear}>
        <Text style={styles.buttonText}>Update Poster</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: {
    paddingTop: 60,
    paddingHorizontal: 20,
    backgroundColor: "#f9f9f9",
    flexGrow: 1,
  },
  backButton: { marginBottom: 20 },
  title: {
    fontSize: 26,
    fontWeight: "700",
    marginBottom: 6,
    textAlign: "center",
    color: "#1a1a1a",
  },
  branch: {
    fontSize: 16,
    color: "#555",
    textAlign: "center",
    marginBottom: 20,
  },
  poster: {
    backgroundColor: "#fff",
    borderRadius: 16,
    padding: 20,
    marginBottom: 30,
    shadowColor: "#000",
    shadowOpacity: 0.08,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 3 },
    elevation: 4,
  },
  posterTitle: {
    fontSize: 18,
    fontWeight: "600",
    marginBottom: 12,
    color: "#007AFF",
  },
  posterContent: {
    fontSize: 16,
    lineHeight: 24,
    color: "#333",
  },
  editLabel: {
    fontSize: 16,
    fontWeight: "600",
    marginBottom: 10,
    color: "#444",
  },
  input: {
    backgroundColor: "#fff",
    borderRadius: 12,
    borderColor: "#ccc",
    borderWidth: 1,
    padding: 15,
    fontSize: 15,
    minHeight: 100,
    textAlignVertical: "top",
    marginBottom: 20,
  },
  button: {
    backgroundColor: "#007AFF",
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: "center",
  },
  buttonText: {
    color: "#fff",
    fontWeight: "600",
    fontSize: 16,
  },
  loading: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
});