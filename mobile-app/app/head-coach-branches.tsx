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
import axios from "axios";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { useRouter } from "expo-router";

const BASE_URL = "http://192.168.1.8:8000";

// Predefined credentials for your branches coaches
const COACH_CREDENTIALS: Record<number, { email: string; password: string }> = {
  2: { email: "hadayek@gmail.com", password: "1234" }, // Hadayek
  3: { email: "maadi@gmail.com", password: "1234" },    // Maadi
  4: { email: "nasrcity@gmail.com", password: "1234" }, // Nasr City
  5: { email: "newcairo@gmail.com", password: "1234" }, // New Cairo
  // Add more as needed
};

interface Branch {
  id: number;
  name: string;
  address: string;
  phone: string;
}

export default function HeadCoachBranchesList() {
  const [branches, setBranches] = useState<Branch[]>([]);
  const [loading, setLoading] = useState(true);
  const [loggingIn, setLoggingIn] = useState(false);
  const router = useRouter();

  useEffect(() => {
    const fetchBranches = async () => {
      try {
        const storedUser = await AsyncStorage.getItem("authUser");
        if (!storedUser) {
          Alert.alert("Error", "No user data found. Please login again.");
          router.replace("/"); // back to guest home or login
          return;
        }
        const { token } = JSON.parse(storedUser);
        const headers = { Authorization: `Bearer ${token}` };

        const res = await axios.get(`${BASE_URL}/branches`, { headers });
        setBranches(res.data);
      } catch (error: any) {
        const message = error.response?.data?.detail || error.message || "Failed to load branches";
        Alert.alert("Error", message);
      } finally {
        setLoading(false);
      }
    };

    fetchBranches();
  }, []);

  const loginAsCoachForBranch = async (branch: Branch) => {
    const creds = COACH_CREDENTIALS[branch.id];
    if (!creds) {
      Alert.alert("Error", `No login credentials configured for branch: ${branch.name}`);
      return;
    }

    setLoggingIn(true);

    try {
      const res = await axios.post(`${BASE_URL}/auth/login`, {
        email: creds.email,
        password: creds.password,
      });

      const { token, user } = res.data;

      if (!["coach", "head_coach"].includes(user.role)) {
        Alert.alert("Error", "Logged in user is not a coach");
        setLoggingIn(false);
        return;
      }

      // Save user info + token + branch info (override branch to selected branch)
      await AsyncStorage.setItem(
        "authUser",
        JSON.stringify({
          ...user,
          token,
          branch_id: branch.id,
          branch_name: branch.name,
        })
      );

      // Remove headCoachMode flag so app treats user as normal coach
      await AsyncStorage.removeItem("headCoachMode");

      // Small delay so user sees activity, can be removed if you want instant
      setTimeout(() => {
        router.replace("/(coach-tabs)/home");
      }, 1000);
    } catch (error: any) {
      const msg = error.response?.data?.detail || error.message || "Login failed";
      Alert.alert("Login Failed", msg);
    } finally {
      setLoggingIn(false);
    }
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={styles.loadingText}>Loading branches...</Text>
      </View>
    );
  }

  if (loggingIn) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={styles.loadingText}>Logging in...</Text>
      </View>
    );
  }

  if (branches.length === 0) {
    return (
      <View style={styles.emptyContainer}>
        <Text style={styles.emptyText}>No branches available.</Text>
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>Select Branch to Manage</Text>
      <FlatList
        data={branches}
        keyExtractor={(item) => item.id.toString()}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.branchCard}
            onPress={() => loginAsCoachForBranch(item)}
          >
            <Text style={styles.branchName}>{item.name}</Text>
            <Text style={styles.branchAddress}>{item.address}</Text>
            <Text style={styles.branchPhone}>📞 {item.phone}</Text>
          </TouchableOpacity>
        )}
        contentContainerStyle={{ paddingBottom: 20 }}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: "#F9FAFB",
  },
  loadingContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: "#007AFF",
  },
  emptyContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  emptyText: {
    fontSize: 18,
    color: "#555",
  },
  title: {
    fontSize: 22,
    fontWeight: "700",
    marginBottom: 16,
    textAlign: "center",
    color: "#007AFF",
  },
  branchCard: {
    backgroundColor: "#fff",
    padding: 18,
    borderRadius: 12,
    marginBottom: 12,
    elevation: 3,
    shadowColor: "#000",
    shadowOpacity: 0.1,
    shadowOffset: { width: 0, height: 2 },
    shadowRadius: 4,
  },
  branchName: {
    fontSize: 18,
    fontWeight: "600",
    marginBottom: 6,
    color: "#111",
  },
  branchAddress: {
    fontSize: 14,
    color: "#555",
    marginBottom: 4,
  },
  branchPhone: {
    fontSize: 14,
    color: "#007AFF",
  },
});