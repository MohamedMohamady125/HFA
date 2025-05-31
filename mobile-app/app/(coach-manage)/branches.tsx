import { useEffect, useState } from "react";
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  TextInput,
  Alert,
} from "react-native";
import axios from "axios";
import AsyncStorage from "@react-native-async-storage/async-storage";

export default function ManageBranches() {
  const [branches, setBranches] = useState<any[]>([]);
  const [coachEmail, setCoachEmail] = useState("");
  const [loading, setLoading] = useState(true);

  const fetchBranches = async () => {
    try {
      const storedUser = await AsyncStorage.getItem("authUser");
      const token = storedUser ? JSON.parse(storedUser).token : null;
      const headers = { Authorization: `Bearer ${token}` };

      const res = await axios.get("http://localhost:8000/branches", { headers });
      setBranches(res.data);
    } catch (err) {
      console.error("Error fetching branches", err);
    } finally {
      setLoading(false);
    }
  };

  const assignCoach = async (branchId: number) => {
    try {
      const storedUser = await AsyncStorage.getItem("authUser");
      const token = storedUser ? JSON.parse(storedUser).token : null;
      const headers = { Authorization: `Bearer ${token}` };

      await axios.post(
        `http://localhost:8000/users/assign-coach`,
        { email: coachEmail, branch_id: branchId },
        { headers }
      );

      Alert.alert("Success", `Assigned ${coachEmail} to branch`);
      setCoachEmail("");
    } catch (err) {
      console.error("Error assigning coach", err);
      Alert.alert("Error", "Failed to assign coach");
    }
  };

  useEffect(() => {
    fetchBranches();
  }, []);

  if (loading) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>🏢 Manage Branches</Text>
      <FlatList
        data={branches}
        keyExtractor={(item) => item.id.toString()}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <Text style={styles.branchName}>{item.name}</Text>
            <Text>{item.address || "No address listed"}</Text>

            <TextInput
              value={coachEmail}
              onChangeText={setCoachEmail}
              placeholder="Coach Email to Assign"
              style={styles.input}
            />

            <TouchableOpacity
              style={styles.button}
              onPress={() => assignCoach(item.id)}
            >
              <Text style={styles.buttonText}>Assign Coach</Text>
            </TouchableOpacity>
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingTop: 60, paddingHorizontal: 20 },
  title: { fontSize: 22, fontWeight: "bold", marginBottom: 20 },
  card: {
    backgroundColor: "#fff",
    padding: 16,
    borderRadius: 12,
    marginBottom: 16,
    elevation: 2,
  },
  branchName: {
    fontSize: 16,
    fontWeight: "bold",
    marginBottom: 4,
  },
  input: {
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 8,
    padding: 8,
    marginVertical: 10,
  },
  button: {
    backgroundColor: "#007AFF",
    padding: 10,
    borderRadius: 8,
    alignItems: "center",
  },
  buttonText: { color: "#fff", fontWeight: "bold" },
  loading: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
});