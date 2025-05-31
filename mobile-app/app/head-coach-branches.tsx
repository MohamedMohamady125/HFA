import { useEffect, useState } from "react";
import { View, Text, ScrollView, TouchableOpacity, StyleSheet, Alert } from "react-native";
import { useRouter } from "expo-router";
import api from "../utils/api";
import { useAuth } from "../context/auth";

export default function HeadCoachBranchSelector() {
  const [branches, setBranches] = useState<any[]>([]);
  const router = useRouter();
  const { user } = useAuth();

  useEffect(() => {
    const fetchBranches = async () => {
      try {
        const res = await api.get("/headcoach/branches", {
          headers: { Authorization: `Bearer ${user.token}` },
        });
        setBranches(res.data);
      } catch (err) {
        console.error("❌ Failed to fetch branches", err);
        Alert.alert("Error", "Could not load branches");
      }
    };

    if (user?.role === "head_coach") {
      fetchBranches();
    }
  }, [user]);

  const handleSelectBranch = (branchId: number) => {
    console.log("🔁 Switching to branch:", branchId);
    router.replace(`/(coach-tabs)/home?override_branch=${branchId}`);
  };

  return (
    <ScrollView contentContainerStyle={styles.page}>
      <Text style={styles.title}>🏢 Select a Branch</Text>
      {branches.map((branch) => (
        <TouchableOpacity
          key={branch.id}
          style={styles.branchCard}
          onPress={() => handleSelectBranch(branch.id)}
        >
          <Text style={styles.branchName}>{branch.name}</Text>
        </TouchableOpacity>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: { flex: 1, paddingTop: 60, paddingHorizontal: 20 },
  title: { fontSize: 22, fontWeight: "bold", marginBottom: 20, textAlign: "center" },
  branchCard: {
    backgroundColor: "#fff",
    padding: 18,
    borderRadius: 10,
    marginBottom: 12,
    elevation: 2,
  },
  branchName: { fontSize: 16, fontWeight: "600" },
});