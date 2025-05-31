import { useEffect, useState } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  ScrollView,
  Alert,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import api from "../../utils/api";
import { useAuth } from "../../context/auth";
import { useRouter, useLocalSearchParams } from "expo-router";

const DAYS = ["Day 1", "Day 2", "Day 3"] as const;
type DayType = typeof DAYS[number];

export default function WeeklyAttendance() {
  const { user } = useAuth();
  const router = useRouter();
  const { override_branch } = useLocalSearchParams();
  const [selectedDay, setSelectedDay] = useState<DayType>("Day 1");
  const [loading, setLoading] = useState(true);
  const [attendance, setAttendance] = useState<any[]>([]);
  const [sessionDates, setSessionDates] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);

  const branchId = override_branch || user?.branch_id;

  const fetchSessionDates = async () => {
    try {
      const res = await api.get(`/attendance/branch/${branchId}/session-dates`);
      setSessionDates(res.data);
    } catch (err) {
      console.error("❌ Failed to load session dates", err);
      setError("Failed to load session dates");
    }
  };

  const getDateForSelectedDay = (): string => {
    const index = DAYS.indexOf(selectedDay);
    return sessionDates[index] || "";
  };

  const fetchAttendance = async () => {
    try {
      setLoading(true);
      setError(null);

      if (!branchId) throw new Error("No branch assigned");
      const date = getDateForSelectedDay();
      if (!date) throw new Error("Session date not available for selected day");

      const res = await api.get(`/attendance/branch/${branchId}/day/${date}`);
      console.log("📦 Attendance API Response:", res.data);
      setAttendance(res.data);
    } catch (err: any) {
      const message = err.response?.data?.detail || err.message || "Fetch error";
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  const markAttendance = async (athlete_id: number, status: string) => {
    try {
      const date = getDateForSelectedDay();
      await api.post("/attendance/mark", {
        athlete_id,
        session_date: date,
        status,
      });
      await fetchAttendance();
    } catch (err) {
      Alert.alert("Error", "Failed to update attendance");
    }
  };

  useEffect(() => {
    if (branchId) {
      fetchSessionDates();
    }
  }, [branchId]);

  useEffect(() => {
    if (sessionDates.length === 3) {
      fetchAttendance();
    }
  }, [selectedDay, sessionDates]);

  if (!branchId) {
    return (
      <View style={styles.container}>
        <Text style={styles.errorText}>No branch assigned to your account</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Ionicons name="chevron-back" size={24} color="#007AFF" />
        </TouchableOpacity>
        <Text style={[styles.title, { flex: 1, textAlign: "center" }]}>
          🏊 Weekly Attendance
        </Text>
        <TouchableOpacity onPress={() => router.push("/summary")}>
          <Ionicons name="list" size={24} color="#007AFF" />
        </TouchableOpacity>
      </View>

      <View style={styles.tabs}>
        {DAYS.map((day) => (
          <TouchableOpacity
            key={day}
            style={[styles.tab, selectedDay === day && styles.activeTab]}
            onPress={() => setSelectedDay(day)}
          >
            <Text
              style={[
                styles.tabText,
                selectedDay === day && styles.activeTabText,
              ]}
            >
              {day}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {error && <Text style={styles.errorText}>{error}</Text>}

      {loading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#007AFF" />
          <Text style={styles.loadingText}>Loading attendance...</Text>
        </View>
      ) : (
        <ScrollView contentContainerStyle={styles.scrollContainer}>
          {attendance.map((item) => (
            <View
              key={`${item.athlete_id}-${item.session_date}`}
              style={styles.card}
            >
              <Text style={styles.name}>{item.athlete_name}</Text>
              <View style={styles.actions}>
                <TouchableOpacity
                  style={[
                    styles.statusBtn,
                    item.status === "present" && styles.presentActive,
                  ]}
                  onPress={() => markAttendance(item.athlete_id, "present")}
                >
                  <Text style={styles.statusText}>✅</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[
                    styles.statusBtn,
                    item.status === "absent" && styles.absentActive,
                  ]}
                  onPress={() => markAttendance(item.athlete_id, "absent")}
                >
                  <Text style={styles.statusText}>❌</Text>
                </TouchableOpacity>
              </View>
            </View>
          ))}
        </ScrollView>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingTop: 40, paddingHorizontal: 20 },
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 20,
  },
  title: { fontSize: 22, fontWeight: "bold" },
  tabs: { flexDirection: "row", justifyContent: "space-between", marginBottom: 20 },
  tab: {
    flex: 1,
    padding: 12,
    borderBottomWidth: 2,
    borderBottomColor: "transparent",
    alignItems: "center",
    backgroundColor: "#f8f9fa",
    borderRadius: 8,
    marginHorizontal: 4,
  },
  activeTab: {
    borderBottomColor: "#007AFF",
    backgroundColor: "#e3f2fd",
  },
  tabText: {
    fontSize: 14,
    color: "#555",
    fontWeight: "500",
  },
  activeTabText: {
    color: "#007AFF",
    fontWeight: "600",
  },
  card: {
    backgroundColor: "#fff",
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  name: { fontSize: 16, fontWeight: "600", color: "#2d3748" },
  actions: { flexDirection: "row", gap: 12 },
  statusBtn: {
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#f0f4f8",
  },
  presentActive: { backgroundColor: "#48bb78" },
  absentActive: { backgroundColor: "#f56565" },
  statusText: { fontSize: 18 },
  loadingContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    gap: 12,
  },
  loadingText: { color: "#718096", fontSize: 14 },
  errorText: {
    color: "#e53e3e",
    textAlign: "center",
    marginVertical: 16,
    fontWeight: "500",
  },
  scrollContainer: { paddingBottom: 24 },
});