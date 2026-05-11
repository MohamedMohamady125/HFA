import { useEffect, useState } from "react";
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from "react-native";
import { useAuth } from "../../context/auth";
import { useRouter } from "expo-router";
import axios from "axios";

export default function CoachProfile() {
  const { user, refreshUser } = useAuth();
  const router = useRouter();
  const [branchName, setBranchName] = useState("");

  useEffect(() => {
    async function fetchUserDetails() {
      try {
        if (!user?.token) return;

        const res = await axios.get("http://192.168.1.8:8000/users/me", {
          headers: { Authorization: `Bearer ${user.token}` },
        });
        setBranchName(res.data.branch_name || "");
        // Also refresh context user data to keep in sync with storage/backend
        refreshUser();
      } catch (e) {
        console.error("Failed to fetch user details", e);
      }
    }
    fetchUserDetails();
  }, [user?.branch_id]); // fetch again when branch changes

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>👤 Coach Profile</Text>

      <View style={styles.profileCard}>
        <Text style={styles.name}>{user?.name || "Coach Name"}</Text>
        <Text style={styles.info}>📍 {branchName || "Branch Name"}</Text>
        <Text style={styles.info}>{user?.email || "coach@email.com"}</Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>⚡ Quick Actions</Text>
        <TouchableOpacity
          style={styles.button}
          onPress={() => router.push("/edit-profile")}
        >
          <Text style={styles.buttonText}>Edit Profile</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.button}
          onPress={() => router.push("/change-password")}
        >
          <Text style={styles.buttonText}>Change Password</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>📊 Attendance</Text>
        <TouchableOpacity
          style={styles.button}
          onPress={() => router.push("/(coach-manage)/attendance")}
        >
          <Text style={styles.buttonText}>Branch Attendance Summary</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingTop: 60, paddingHorizontal: 20 },
  title: { fontSize: 24, fontWeight: "bold", marginBottom: 20, textAlign: "center" },
  profileCard: {
    backgroundColor: "#fff",
    padding: 20,
    borderRadius: 12,
    marginBottom: 20,
    shadowColor: "#000",
    shadowOpacity: 0.05,
    shadowOffset: { width: 0, height: 1 },
    elevation: 3,
    alignItems: "center",
  },
  name: { fontSize: 20, fontWeight: "bold", marginBottom: 4 },
  info: { fontSize: 14, color: "#555" },
  section: { marginBottom: 25 },
  sectionTitle: { fontSize: 16, fontWeight: "bold", marginBottom: 10 },
  button: {
    backgroundColor: "#007AFF",
    padding: 12,
    borderRadius: 10,
    marginBottom: 10,
    alignItems: "center",
  },
  buttonText: { color: "white", fontWeight: "600" },
});