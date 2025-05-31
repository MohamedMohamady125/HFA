import { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  Switch,
  Button,
  Platform,
  KeyboardAvoidingView,
  Alert,
  SafeAreaView,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import axios from "axios";
import AsyncStorage from "@react-native-async-storage/async-storage";

export default function ProfileTab() {
  const [user, setUser] = useState<any>(null);
  const [attendance, setAttendance] = useState<any[]>([]);
  const [branchName, setBranchName] = useState<string>("");
  const [labels, setLabels] = useState<string[]>(["Day 1", "Day 2", "Day 3"]);
  const [measurements, setMeasurements] = useState({
    height: "",
    weight: "",
    arm: "",
    leg: "",
    fat: "",
    muscle: "",
  });
  const [isArabic, setIsArabic] = useState(false);
  const [events, setEvents] = useState([{ name: "", time: "" }]);
  const [editable, setEditable] = useState(true);
  const [eventsEditable, setEventsEditable] = useState(true); // New state for events editing

  useEffect(() => {
    const fetchData = async () => {
      const storedUser = await AsyncStorage.getItem("authUser");
      if (!storedUser) return;
      const parsed = JSON.parse(storedUser);
      setUser(parsed);
      const headers = { Authorization: `Bearer ${parsed.token}` };

      try {
        // First fetch the basic data
        const [attRes, branchRes, sessionDaysRes, measurementsRes] = await Promise.all([
          axios.get(`http://192.168.1.8:8000/attendance/athlete/${parsed.id}/week`, { headers }),
          axios.get(`http://192.168.1.8:8000/branches/${parsed.branch_id}`, { headers }),
          axios.get(`http://192.168.1.8:8000/attendance/branch/${parsed.branch_id}/session-dates`, { headers }),
          axios.get(`http://192.168.1.8:8000/athlete/measurements`, { headers }),
        ]);

        // Try to fetch events separately to handle potential errors
        let eventsRes = null;
        try {
          eventsRes = await axios.get(`http://192.168.1.8:8000/athlete/performance-logs`, { headers });
        } catch (eventsError: any) {
          console.log("⚠️ Could not fetch existing events - they may not exist yet or endpoint not available");
          console.log("Error details:", eventsError.response?.data || eventsError.message);
        }

        setAttendance(attRes.data);
        setBranchName(branchRes.data.name);
        if (Array.isArray(sessionDaysRes.data)) {
          setLabels(sessionDaysRes.data.map((_, i) => `Day ${i + 1}`));
        }
        if (measurementsRes.data) {
          // Handle both single object and array responses
          const measurementData = Array.isArray(measurementsRes.data) 
            ? measurementsRes.data[0] 
            : measurementsRes.data;
          
          if (measurementData) {
            setMeasurements({
              height: measurementData.height?.toString() || "",
              weight: measurementData.weight?.toString() || "",
              arm: measurementData.arm?.toString() || "",
              leg: measurementData.leg?.toString() || "",
              fat: measurementData.fat?.toString() || "",
              muscle: measurementData.muscle?.toString() || "",
            });
            setEditable(false); // Set to non-editable since data exists
          }
        }
        
        // Load existing swim events if available
        if (eventsRes && eventsRes.data && Array.isArray(eventsRes.data) && eventsRes.data.length > 0) {
          const loadedEvents = eventsRes.data.map(event => ({
            name: event.event_name || "",
            time: event.result_time || "", // This will now be the formatted time string from backend
          }));
          setEvents(loadedEvents);
          setEventsEditable(false); // Set to non-editable since data exists
        }
      } catch (e) {
        console.error("❌ Error loading profile data", e);
      }
    };

    fetchData();
  }, []);

  const normalizeTime = (input: string): string => {
    const parts = input.trim().split(/[\s:.,]+/).map(p => p.padStart(2, "0")).filter(Boolean);
    if (parts.length === 3) {
      const [min, sec, frac] = parts;
      return `${parseInt(min)}:${sec}.${frac}`;
    } else if (parts.length === 2) {
      const [sec, frac] = parts;
      return `${parseInt(sec)}.${frac}`;
    } else if (parts.length === 1) {
      return parts[0];
    }
    return input;
  };

  const timeToSeconds = (timeString: string): number => {
    const normalized = normalizeTime(timeString);
    
    // Handle different time formats and convert to seconds
    if (normalized.includes(':')) {
      // Format: "2:13.50" (minutes:seconds.milliseconds)
      const [minutes, secondsPart] = normalized.split(':');
      const seconds = parseFloat(secondsPart);
      return parseInt(minutes) * 60 + seconds;
    } else if (normalized.includes('.')) {
      // Format: "13.50" (seconds.milliseconds)
      return parseFloat(normalized);
    } else {
      // Format: "13" (seconds only)
      return parseFloat(normalized);
    }
  };

  const saveMeasurements = async () => {
    try {
      const storedUser = await AsyncStorage.getItem("authUser");
      if (!storedUser) throw new Error("Not logged in");
      const { token } = JSON.parse(storedUser);
      
      // Format measurements according to the MeasurementInput model (no athlete_id needed)
      const formattedMeasurements = {
        height: parseFloat(measurements.height) || 0,
        weight: parseFloat(measurements.weight) || 0,
        arm: parseFloat(measurements.arm) || 0,
        leg: parseFloat(measurements.leg) || 0,
        fat: parseFloat(measurements.fat) || 0,
        muscle: parseFloat(measurements.muscle) || 0,
      };
      
      await axios.post("http://192.168.1.8:8000/athlete/measurements", formattedMeasurements, { 
        headers: { Authorization: `Bearer ${token}` } 
      });
      Alert.alert("✅ Measurements saved!");
      setEditable(false);
    } catch (err) {
      console.error("❌ Failed to save measurements", err);
      Alert.alert("Error", "Could not save measurements");
    }
  };

  const saveSwimEvents = async () => {
    try {
      const storedUser = await AsyncStorage.getItem("authUser");
      if (!storedUser) throw new Error("Not logged in");
      const { token } = JSON.parse(storedUser);
      const headers = { Authorization: `Bearer ${token}` };
      
      // Filter out empty events
      const validEvents = events.filter(e => e.name && e.time);
      
      if (validEvents.length === 0) {
        Alert.alert("No valid events to save");
        return;
      }

      // Step 1: Delete all existing performance logs for this athlete
      try {
        await axios.delete("http://192.168.1.8:8000/athlete/performance-logs", { headers });
      } catch (deleteError) {
        console.log("⚠️ Could not delete existing events (they may not exist)");
      }

      // Step 2: Insert all current events
      let saved = false;
      for (const e of validEvents) {
        const timeInSeconds = timeToSeconds(e.time);
        await axios.post("http://192.168.1.8:8000/athlete/performance-log", {
          meet_name: "Top Swim Event",
          meet_date: new Date().toISOString().split("T")[0],
          event_name: e.name,
          result_time: timeInSeconds, // Send as number (seconds)
        }, { headers });
        saved = true;
      }
      
      if (saved) {
        Alert.alert("✅ Events saved successfully!");
        setEventsEditable(false);
      }
    } catch (err) {
      console.error("❌ Error saving events:", err);
      Alert.alert("Error", "Could not save events.");
    }
  };

  const renderAttendance = () =>
    labels.map((label, idx) => {
      const record = attendance.find((r) => r.day_number === idx + 1);
      const status = record?.status;
      return (
        <View key={label} style={styles.attendanceBox}>
          <Text style={styles.attendanceDay}>{label}</Text>
          {status ? (
            <>
              <Ionicons
                name={status === "present" ? "checkmark-circle" : "close-circle"}
                size={24}
                color={status === "present" ? "green" : "red"}
              />
              <Text style={{ color: status === "present" ? "green" : "red" }}>
                {status.charAt(0).toUpperCase() + status.slice(1)}
              </Text>
            </>
          ) : (
            <>
              <Ionicons name="remove-circle-outline" size={24} color="#ccc" />
              <Text style={{ color: "#999" }}>—</Text>
            </>
          )}
        </View>
      );
    });

  const renderMeasurementInputs = () => {
    const labels: { [key: string]: string } = {
      height: "Height (cm)",
      weight: "Weight (kg)",
      arm: "Arm Length (cm)",
      leg: "Leg Length",
      fat: "Fat Percentage %",
      muscle: "Muscle Percentage %",
    };
    return Object.entries(measurements).map(([key, val]) => (
      <View key={key} style={{ marginBottom: 10 }}>
        <Text style={styles.label}>{labels[key]}</Text>
        <TextInput
          value={val?.toString()}
          onChangeText={(t) => setMeasurements((prev) => ({ ...prev, [key]: t }))}
          style={styles.input}
          keyboardType="numeric"
          editable={editable}
        />
      </View>
    ));
  };

  const renderEvents = () =>
    events.map((e, idx) => (
      <View key={idx} style={{ flexDirection: "row", gap: 10, marginBottom: 8 }}>
        <TextInput
          placeholder="Event Name"
          value={e.name}
          onChangeText={(val) => {
            const newEvents = [...events];
            newEvents[idx].name = val;
            setEvents(newEvents);
          }}
          style={[styles.input, { flex: 1 }]}
          editable={eventsEditable}
        />
        <TextInput
          placeholder="Time"
          value={e.time}
          onChangeText={(val) => {
            const newEvents = [...events];
            newEvents[idx].time = val;
            setEvents(newEvents);
          }}
          style={[styles.input, { flex: 1 }]}
          editable={eventsEditable}
        />
      </View>
    ));

  if (!user) return null;

  return (
    <KeyboardAvoidingView
      style={{ flex: 1 }}
      behavior={Platform.OS === "ios" ? "padding" : "height"}
      keyboardVerticalOffset={Platform.OS === "ios" ? 80 : 0}
    >
      <ScrollView style={styles.container} keyboardShouldPersistTaps="handled">
        <Text style={styles.header}>🎉 Welcome back, {user.name}!</Text>
        <Text style={styles.subHeader}>🏢 Branch: {branchName}</Text>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>🏆 Attendance Tracker</Text>
          <View style={styles.attendanceRow}>{renderAttendance()}</View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>📏 Measurements</Text>
          {renderMeasurementInputs()}
          <Button title="Save Measurements" onPress={saveMeasurements} />
          {editable ? null : <Button title="Edit Measurements" onPress={() => setEditable(true)} />}
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>🌐 Language</Text>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 10 }}>
            <Text>Current: {isArabic ? "Arabic" : "English"}</Text>
            <Switch value={isArabic} onValueChange={setIsArabic} />
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>🏊 Top Swim Events</Text>
          {renderEvents()}
          {events.length < 5 && eventsEditable && (
            <Button title="Add Event" onPress={() => setEvents([...events, { name: "", time: "" }])} />
          )}
          <Button title="Save Events" onPress={saveSwimEvents} />
          {eventsEditable ? null : <Button title="Edit Events" onPress={() => setEventsEditable(true)} />}
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20 },
  header: { fontSize: 22, fontWeight: "bold", marginBottom: 4 },
  subHeader: { fontSize: 16, fontWeight: "500", color: "#555", marginBottom: 20 },
  section: {
    backgroundColor: "#3399FF",
    padding: 15,
    borderRadius: 12,
    marginBottom: 20,
    elevation: 2,
  },
  sectionTitle: { fontSize: 16, fontWeight: "bold", marginBottom: 10, color: "#fff" },
  attendanceRow: { flexDirection: "row", justifyContent: "space-around", flexWrap: "wrap", gap: 10 },
  attendanceBox: { alignItems: "center", width: 70, gap: 4 },
  attendanceDay: { fontWeight: "bold", marginBottom: 2, color: "#fff" },
  input: {
    borderBottomWidth: 1,
    borderColor: "#ccc",
    paddingVertical: 4,
    marginBottom: 10,
    backgroundColor: "#E0F2F1",
    borderRadius: 6,
    paddingHorizontal: 8,
  },
  label: {
    fontSize: 14,
    fontWeight: "600",
    marginBottom: 4,
    color: "#fff",
  },
});