import { useEffect, useState } from "react";
import { View, Text, ScrollView, StyleSheet, ActivityIndicator } from "react-native";
import api from "../../utils/api";
import { useAuth } from "../../context/auth";

export default function AttendanceSummary() {
  const { user } = useAuth();
  const [data, setData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [sessionDates, setSessionDates] = useState<string[]>([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [summaryRes, sessionDaysRes] = await Promise.all([
          api.get(`/attendance/branch/${user.branch_id}/summary`),
          api.get(`/attendance/branch/${user.branch_id}/session-dates`),
        ]);

        setData(summaryRes.data.records);
        setSessionDates(sessionDaysRes.data);
      } catch (e) {
        console.error("Failed to load summary or session days", e);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const groupByAthlete = () => {
    const grouped: { [athlete: string]: { [date: string]: string | null } } = {};
    for (let row of data) {
      if (!grouped[row.athlete_name]) grouped[row.athlete_name] = {};
      grouped[row.athlete_name][row.session_date] = row.status;
    }
    return grouped;
  };

  if (loading) return <ActivityIndicator size="large" />;

  const grouped = groupByAthlete();

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>📊 Attendance Summary</Text>

      {Object.entries(grouped).map(([name, records]) => (
        <View key={name} style={styles.card}>
          <Text style={styles.name}>{name}</Text>
          {sessionDates.map((date, idx) => (
            <Text key={date} style={styles.record}>
              Day {idx + 1} ({date}): {records[date] ?? "—"}
            </Text>
          ))}
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { padding: 20 },
  title: { fontSize: 20, fontWeight: "bold", marginBottom: 12 },
  card: {
    backgroundColor: "#f8f9fa",
    padding: 16,
    borderRadius: 10,
    marginBottom: 16,
  },
  name: { fontSize: 16, fontWeight: "600", marginBottom: 6 },
  record: { fontSize: 14, color: "#333" },
});