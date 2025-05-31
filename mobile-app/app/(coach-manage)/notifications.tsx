// FILE: app/(coach-manage)/notifications.tsx
import { useEffect, useState } from "react";
import {
  View,
  Text,
  TextInput,
  Button,
  Alert,
  FlatList,
  ActivityIndicator,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import api from "../../utils/api";

export default function CoachNotifications() {
  const [athletes, setAthletes] = useState<any[]>([]);
  const [message, setMessage] = useState("");
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  const fetchAthletes = async () => {
    try {
      const res = await api.get("/users/athletes");
      setAthletes(res.data);
    } catch (err) {
      Alert.alert("Error", "Failed to load athletes");
    } finally {
      setLoading(false);
    }
  };

  const sendNotification = async () => {
    if (!message || !selectedId) {
      Alert.alert("Missing data", "Select athlete and enter a message");
      return;
    }

    try {
      await api.post("/notifications", {
        user_id: selectedId,
        message,
      });

      Alert.alert("Success", "Notification sent");
      setMessage("");
    } catch (err: any) {
      Alert.alert("Error", err.response?.data?.detail || "Failed to send notification");
    }
  };

  useEffect(() => {
    fetchAthletes();
  }, []);

  if (loading) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.page}>
      {/* 🔙 Back Button */}
      <TouchableOpacity onPress={() => router.push("/(coach-tabs)/home")} style={styles.backButton}>
        <Ionicons name="arrow-back" size={24} color="#007AFF" />
      </TouchableOpacity>

      <Text style={styles.title}>📣 Send Notification</Text>

      <Text style={styles.label}>Select Athlete:</Text>
      <FlatList
        data={athletes}
        keyExtractor={(item) => item.id.toString()}
        horizontal
        renderItem={({ item }) => (
          <Button
            title={item.name}
            color={selectedId === item.id ? "#007AFF" : "#ccc"}
            onPress={() => setSelectedId(item.id)}
          />
        )}
        contentContainerStyle={{ gap: 10, marginBottom: 20 }}
      />

      <TextInput
        placeholder="Enter your message"
        value={message}
        onChangeText={setMessage}
        multiline
        style={styles.input}
      />

      <Button title="Send Notification" onPress={sendNotification} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: { padding: 20, paddingTop: 60 },
  backButton: {
    marginBottom: 10,
    alignSelf: "flex-start",
  },
  title: { fontSize: 22, fontWeight: "bold", marginBottom: 20 },
  label: { marginBottom: 10, fontSize: 14 },
  input: {
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 10,
    padding: 12,
    backgroundColor: "#fff",
    marginBottom: 20,
    minHeight: 100,
    textAlignVertical: "top",
  },
  loading: { flex: 1, justifyContent: "center", alignItems: "center" },
});