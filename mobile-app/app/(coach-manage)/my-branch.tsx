// FILE: app/(coach-tabs)/my-branch.tsx
import { useEffect, useState } from "react";
import { View, Text, StyleSheet, ActivityIndicator, TouchableOpacity } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import api from "../../utils/api";

export default function MyBranch() {
  const [branch, setBranch] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    const loadBranch = async () => {
      try {
        const userRes = await api.get("/users/me");
        const branchId = userRes.data.branch_id;

        const branchRes = await api.get(`/branches/${branchId}`);
        setBranch(branchRes.data);
      } catch (err) {
        console.error("Error loading branch info", err);
      } finally {
        setLoading(false);
      }
    };

    loadBranch();
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
      {/* 🔙 Back Button */}
      <TouchableOpacity onPress={() => router.push("/(coach-tabs)/home")} style={styles.backButton}>
        <Ionicons name="arrow-back" size={24} color="#007AFF" />
      </TouchableOpacity>

      <Text style={styles.title}>🏢 My Branch</Text>
      <Text style={styles.item}>Name: {branch.name}</Text>
      <Text style={styles.item}>Phone: {branch.phone}</Text>
      <Text style={styles.item}>Address: {branch.address}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20, paddingTop: 60 },
  backButton: {
    marginBottom: 10,
    alignSelf: "flex-start",
  },
  title: { fontSize: 22, fontWeight: "bold", marginBottom: 10 },
  item: { fontSize: 16, marginBottom: 5 },
  loading: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
});