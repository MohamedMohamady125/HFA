import { useEffect, useState } from "react";
import {
  ScrollView,
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
} from "react-native";
import { useAuth } from "../../context/auth";
import api from "../../utils/api";
import { useRouter, useLocalSearchParams } from "expo-router";

export default function CoachHome() {
  const { user } = useAuth() as { user: any | null };
  const router = useRouter();
  const { override_branch } = useLocalSearchParams();
  const [name, setName] = useState<string>("");

  const branchId = override_branch || user?.branch_id;

  useEffect(() => {
    async function fetchUser() {
      try {
        const res = await api.get("/users/me");
        setName(res.data.name || "");
      } catch (err) {
        console.error("❌ Error loading user info:", err);
        Alert.alert("Error", "Failed to load user data");
      }
    }
    fetchUser();
  }, []);

  const handlePress = (route: string | null) => {
    if (!route) {
      Alert.alert("Error", "Branch ID not available for this action.");
      return;
    }
    router.push(route);
  };

  const tools = [
    { 
      title: "📝 Registration Requests", 
      route: "/(coach-manage)/register-requests",
    },
    { 
      title: "💳 Payments", 
      route: "/(coach-manage)/payment",
    },
    { 
      title: "📊 Attendance", 
      route: "/(coach-manage)/attendance",
    },
  ];

  if (!name) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>👋 Welcome, Coach {name}</Text>
      <Text style={styles.subtitle}>Your coach dashboard</Text>

      <View style={styles.grid}>
        {tools.map((tool, idx) => (
          <TouchableOpacity
            key={idx}
            style={styles.card}
            onPress={() => handlePress(tool.route)}
            activeOpacity={0.7}
          >
            <Text style={styles.cardText}>{tool.title}</Text>
          </TouchableOpacity>
        ))}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingTop: 60,
    paddingHorizontal: 16,
    paddingBottom: 30,
    backgroundColor: "#f9f9f9",
  },
  title: {
    fontSize: 24,
    fontWeight: "700",
    textAlign: "center",
    marginBottom: 6,
  },
  subtitle: {
    fontSize: 15,
    color: "#666",
    textAlign: "center",
    marginBottom: 25,
  },
  grid: {
    flexDirection: "row",
    flexWrap: "wrap",
    justifyContent: "space-between",
  },
  card: {
    width: "48%",
    backgroundColor: "#fff",
    padding: 20,
    borderRadius: 14,
    marginBottom: 16,
    alignItems: "center",
    justifyContent: "center",
    shadowColor: "#000",
    shadowOpacity: 0.06,
    shadowOffset: { width: 0, height: 2 },
    shadowRadius: 4,
    elevation: 2,
  },
  cardText: {
    fontSize: 15,
    fontWeight: "600",
    textAlign: "center",
    color: "#333",
  },
  loadingContainer: { flex: 1, justifyContent: "center", alignItems: "center" },
});