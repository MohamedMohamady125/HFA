import { useEffect, useState } from "react";
import { View, Text, ScrollView, StyleSheet, ActivityIndicator } from "react-native";
import api from "../../utils/api";
import { useAuth } from "../../context/auth";

export default function AttendanceSummary() {
  const { user } = useAuth();
  const [records, setRecords] = useState<any[]>([]);
  const [sessionDates, setSessionDates] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchSummary = async () => {
      try {
        const [summaryRes, datesRes] = await Promise.all([
          api.get(`/attendance/branch/${user?.branch_id}/summary`),
          api.get(`/attendance/branch/${user?.branch_id}/session-dates`),
        ]);

        setRecords(summaryRes.data.records || []);
        setSessionDates(datesRes.data || []);
      } catch (err) {
        console.error("❌ Failed to load attendance summary or session dates", err);
      } finally {
        setLoading(false);
      }
    };

    fetchSummary();
  }, []);

  const groupRecords = () => {
    const grouped: { [name: string]: { [date: string]: string } } = {};
    for (let row of records) {
      if (!grouped[row.athlete_name]) grouped[row.athlete_name] = {};
      grouped[row.athlete_name][row.session_date] = row.status;
    }
    return grouped;
  };

  const grouped = groupRecords();

  if (loading) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={{ marginTop: 10 }}>Loading summary...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>📊 Attendance Summary</Text>
      {Object.entries(grouped).map(([name, dateMap]) => (
        <View key={name} style={styles.card}>
          <Text style={styles.name}>{name}</Text>
          {sessionDates.map((date, idx) => (
            <Text key={date} style={styles.record}>
              Day {idx + 1} ({date}): {dateMap[date] ?? "—"}
            </Text>
          ))}
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { padding: 20 },
  title: { fontSize: 20, fontWeight: "bold", marginBottom: 16 },
  card: {
    backgroundColor: "#fff",
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    shadowColor: "#000",
    shadowOpacity: 0.05,
    shadowOffset: { width: 0, height: 2 },
    shadowRadius: 4,
    elevation: 2,
  },
  name: {
    fontSize: 16,
    fontWeight: "600",
    marginBottom: 8,
    color: "#1a202c",
  },
  record: {
    fontSize: 14,
    color: "#333",
  },
  loading: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    paddingTop: 100,
  },
});