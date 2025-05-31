import { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  ActivityIndicator,
  ScrollView,
  SafeAreaView,
} from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import axios from "axios";

export default function GearScreen() {
  const [gearMessage, setGearMessage] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchGear = async () => {
      try {
        const storedUser = await AsyncStorage.getItem("authUser");
        if (!storedUser) throw new Error("No stored user");

        const parsedUser = JSON.parse(storedUser);
        const headers = { Authorization: `Bearer ${parsedUser.token}` };

        const branchId = parsedUser.branch_id;
        if (!branchId) throw new Error("Branch ID missing");

        const res = await axios.get(`http://192.168.1.8:8000/gear/${branchId}`, { headers });

        if (res.data?.message && res.data?.thread_title?.toLowerCase() === "gear") {
          setGearMessage(res.data.message);
        } else {
          setGearMessage("No gear updates yet.");
        }

      } catch (err) {
        console.error("❌ Error loading gear", err);
        setGearMessage("Error loading gear information.");
      } finally {
        setLoading(false);
      }
    };

    fetchGear();
  }, []);

  if (loading) {
    return (
      <SafeAreaView style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#3399FF" />
        <Text style={styles.loadingText}>Loading gear info...</Text>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: "#E6F2FF" }}>
      <ScrollView contentContainerStyle={styles.page}>
        <View style={styles.card}>
          <Text style={styles.title}>🎒 Gear Update</Text>
          <View style={styles.widgetBox}>
            <Text style={styles.message}>{gearMessage}</Text>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  page: {
    flexGrow: 1,
    padding: 24,
  },
  card: {
    backgroundColor: "#3399FF",
    borderRadius: 20,
    padding: 20,
    elevation: 4,
  },
  title: {
    fontSize: 22,
    fontWeight: "bold",
    color: "#fff",
    marginBottom: 16,
  },
  widgetBox: {
    backgroundColor: "#D0E7FF",
    padding: 18,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#A4D3FF",
    shadowColor: "#3399FF",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 6,
    elevation: 2,
  },
  message: {
    fontSize: 16,
    color: "#003366",
    lineHeight: 22,
    fontWeight: "500",
  },
  loadingContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#E6F2FF",
  },
  loadingText: {
    marginTop: 10,
    fontSize: 14,
    color: "#1a73e8",
  },
});