import React, { useState } from "react";
import {
  View,
  Text,
  TextInput,
  Button,
  StyleSheet,
  Alert,
} from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import axios from "axios";

export default function SwimMeetsTab() {
  const [events, setEvents] = useState([
    { name: "", time: "" },
    { name: "", time: "" },
  ]);
  const [meetName, setMeetName] = useState("");
  const [meetDate, setMeetDate] = useState("");

  const formatTime = (input: string): string => {
    const parts = input.trim().split(/[\s:.,]+/).map((p) => p.padStart(2, "0"));

    if (parts.length === 3) {
      const [min, sec, hund] = parts;
      return `${parseInt(min)}:${sec}.${hund}`;
    }

    if (parts.length === 2) {
      const [sec, hund] = parts;
      return `${parseInt(sec)}.${hund}`;
    }

    return input; // fallback
  };

  const updateEvent = (
    index: number,
    key: "name" | "time",
    value: string
  ) => {
    const newEvents = [...events];
    newEvents[index][key] = key === "time" ? formatTime(value) : value;
    setEvents(newEvents);
  };

  const submit = async () => {
    try {
      const storedUser = await AsyncStorage.getItem("authUser");
      if (!storedUser) throw new Error("User not authenticated");
      const { token } = JSON.parse(storedUser);
      const headers = { Authorization: `Bearer ${token}` };

      if (!meetName || !meetDate) {
        Alert.alert("Missing info", "Please enter the meet name and date.");
        return;
      }

      let saved = false;
      for (const e of events) {
        if (!e.name || !e.time) continue;

        await axios.post(
          "http://192.168.1.8:8000/athlete/performance-log",
          {
            meet_name: meetName,
            meet_date: meetDate,
            event_name: e.name,
            result_time: e.time,
          },
          { headers }
        );
        saved = true;
      }

      if (saved) Alert.alert("✅ Events saved successfully!");
      else Alert.alert("No valid events to save");
    } catch (err) {
      console.error("❌ Error submitting performance logs:", err);
      Alert.alert("Error", "Could not save events.");
    }
  };

  return (
    <View style={styles.container}>
      <TextInput
        style={styles.input}
        placeholder="Meet Name"
        value={meetName}
        onChangeText={setMeetName}
      />
      <TextInput
        style={styles.input}
        placeholder="Meet Date (YYYY-MM-DD)"
        value={meetDate}
        onChangeText={setMeetDate}
      />

      {events.map((e, idx) => (
        <View key={idx} style={styles.row}>
          <TextInput
            style={styles.input}
            placeholder="Event Name"
            value={e.name}
            onChangeText={(val) => updateEvent(idx, "name", val)}
          />
          <TextInput
            style={styles.input}
            placeholder="mm:ss.00"
            value={e.time}
            onChangeText={(val) => updateEvent(idx, "time", val)}
            keyboardType="numeric"
          />
        </View>
      ))}

      {/* Removed the Add Event button */}
      <Button title="Save Events" onPress={submit} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { padding: 20 },
  row: { flexDirection: "row", marginBottom: 10 },
  input: {
    flex: 1,
    borderBottomWidth: 1,
    borderColor: "#ccc",
    paddingVertical: 5,
    marginHorizontal: 5,
    fontSize: 16,
  },
});