import { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  ActivityIndicator,
  ScrollView,
  TouchableOpacity,
} from "react-native";
import axios from "axios";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { useRouter } from "expo-router";

export default function AthleteHome() {
  const router = useRouter();
  const [attendance, setAttendance] = useState<any[]>([]);
  const [gearMessage, setGearMessage] = useState("Loading...");
  const [lastThreadMessage, setLastThreadMessage] = useState("Loading...");
  const [paymentStatus, setPaymentStatus] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const getCurrentDueDateKey = () => {
    const today = new Date();
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, "0");
    return `${year}-${month}-01`;
  };

  const getCurrentMonthName = () => {
    const today = new Date();
    return today.toLocaleString("default", { month: "long", year: "numeric" });
  };

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const storedUser = await AsyncStorage.getItem("authUser");
        if (!storedUser) return;
        const user = JSON.parse(storedUser);
        const headers = { Authorization: `Bearer ${user.token}` };

        const attendanceRes = await axios.get(
          `http://192.168.1.8:8000/attendance/athlete/${user.id}/week`,
          { headers }
        );
        setAttendance(attendanceRes.data || []);

        const gearRes = await axios.get(
          `http://192.168.1.8:8000/gear/${user.branch_id}`,
          { headers }
        );
        setGearMessage(gearRes.data?.message || "No recent gear update.");

        const threadsRes = await axios.get(
          `http://192.168.1.8:8000/threads/branch/${user.branch_id}`,
          { headers }
        );
        const threads = threadsRes.data.filter(
          (t: any) => t.title.toLowerCase() !== "gear"
        );
        if (threads.length > 0) {
          const postsRes = await axios.get(
            `http://192.168.1.8:8000/threads/${threads[0].id}/posts`,
            { headers }
          );
          setLastThreadMessage(postsRes.data?.[0]?.message || "No posts yet.");
        } else {
          setLastThreadMessage("No threads available.");
        }

        const payRes = await axios.get(
          `http://192.168.1.8:8000/payments/${user.id}/status`,
          { headers }
        );
        const paymentData = payRes.data || {};
        setPaymentStatus(paymentData[getCurrentDueDateKey()] || "pending");
      } catch (err) {
        console.error("❌ Error fetching home data", err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const getStatusIcon = (status: string | null) => {
    switch (status) {
      case "present": return "✅";
      case "absent": return "❌";
      case "excused": return "🟡";
      default: return "—";
    }
  };

  const getPaymentIcon = (status: string | null) => {
    switch (status) {
      case "paid": return "✅";
      case "late": return "⚠️";
      case "pending": return "⏳";
      case "error": return "❓";
      default: return "❌";
    }
  };

  const getPaymentLabel = (status: string | null) => {
    switch (status) {
      case "paid": return "Paid";
      case "late": return "Late";
      case "pending": return "Pending";
      case "error": return "Error";
      default: return "Unknown";
    }
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <View style={styles.loadingCard}>
          <ActivityIndicator size="large" color="#3399FF" />
          <Text style={styles.loadingText}>Loading...</Text>
        </View>
      </View>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.page}>
      <View style={styles.header}>
        <Text style={styles.welcomeText}>Dashboard</Text>
        <Text style={styles.dateText}>{new Date().toLocaleDateString()}</Text>
      </View>

      {/* Attendance */}
      <View style={[styles.card, { backgroundColor: "#3399FF" }]}>
        <Text style={styles.sectionTitle}>📆 Weekly Attendance</Text>
        {["Day 1", "Day 2", "Day 3"].map((label, i) => {
          const record = attendance.find((d) => d.day_number === i + 1);
          return (
            <View key={i} style={[styles.row, { backgroundColor: "#CCE5FF" }]}>
              <Text style={styles.label}>{label}</Text>
              <Text style={styles.status}>{getStatusIcon(record?.status ?? null)}</Text>
            </View>
          );
        })}
      </View>

      {/* Threads */}
      <TouchableOpacity
        style={[styles.card, { backgroundColor: "#3399FF" }]}
        onPress={() => router.push("/(athlete-tabs)/threads")}
      >
        <Text style={styles.sectionTitle}>💬 Latest Thread</Text>
        <Text style={[styles.threadPreview, { backgroundColor: "#D6ECFF" }]}>{lastThreadMessage}</Text>
      </TouchableOpacity>

      {/* Gear */}
      <TouchableOpacity
        style={[styles.card, { backgroundColor: "#3399FF" }]}
        onPress={() => router.push("/(athlete-tabs)/gear")}
      >
        <Text style={styles.sectionTitle}>🎒 Gear Check</Text>
        <Text style={[styles.threadPreview, { backgroundColor: "#D0F0FF" }]}>{gearMessage}</Text>
      </TouchableOpacity>

      {/* Payment */}
      <View style={[styles.card, { backgroundColor: "#3399FF" }]}>
        <Text style={styles.sectionTitle}>💰 Payment – {getCurrentMonthName()}</Text>
        <View style={[styles.row, { backgroundColor: "#F0F9FF" }]}>
          <Text style={styles.label}>Status</Text>
          <Text style={styles.status}>
            {getPaymentIcon(paymentStatus)} {getPaymentLabel(paymentStatus)}
          </Text>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: {
    flexGrow: 1,
    paddingTop: 60,
    paddingHorizontal: 20,
    paddingBottom: 30,
    backgroundColor: "#f5f5f5",
  },
  header: {
    marginBottom: 32,
    alignItems: "center",
  },
  welcomeText: {
    fontSize: 32,
    fontWeight: "800",
    color: "#00796B",
    textAlign: "center",
  },
  dateText: {
    fontSize: 16,
    color: "#555",
    marginTop: 8,
    fontWeight: "500",
  },
  loadingContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#3399FF",
  },
  loadingCard: {
    backgroundColor: "#ffffff",
    borderRadius: 24,
    padding: 40,
    alignItems: "center",
  },
  loadingText: {
    color: "#00796B",
    fontSize: 16,
    fontWeight: "600",
    marginTop: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: "700",
    marginBottom: 16,
    color: "#ffffff",
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    padding: 16,
    borderRadius: 12,
    marginBottom: 10,
  },
  label: {
    fontSize: 15,
    fontWeight: "600",
    color: "#37474F",
  },
  status: {
    fontSize: 20,
  },
  threadPreview: {
    padding: 16,
    borderRadius: 12,
    fontSize: 15,
    color: "#37474F",
    lineHeight: 22,
    marginTop: 4,
  },
  card: {
    borderRadius: 20,
    padding: 20,
    marginBottom: 20,
    elevation: 4,
  },
});