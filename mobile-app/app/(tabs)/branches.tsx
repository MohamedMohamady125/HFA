import { useEffect, useState } from "react";
import { useRouter } from "expo-router";
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  Linking,
  StyleSheet,
  ScrollView,
} from "react-native";
import axios from "axios";
import { Ionicons } from "@expo/vector-icons";

// Define the structure of a branch
interface Branch {
  id: number;
  name: string;
  address: string;
  phone: string;
  video_url: string;
  practice_days: string;
}

export default function BranchesScreen() {
  const router = useRouter();
  const [branches, setBranches] = useState<Branch[]>([]);

  useEffect(() => {
    const fetchBranches = async () => {
      try {
        const res = await axios.get("http://192.168.1.8:8000/branches/");
        setBranches(res.data);
      } catch (err) {
        console.error("Failed to fetch branches", err);
      }
    };
    fetchBranches();
  }, []);

  return (
    <ScrollView contentContainerStyle={styles.page}>
      <View style={styles.topBar}>
        <Text style={styles.hfa}>HFA</Text>
        <Ionicons name="notifications-outline" size={24} color="#333" />
      </View>

      <Text style={styles.sectionTitle}>🏢 Our Branches</Text>

      <FlatList
        data={branches}
        keyExtractor={(item) => item.id.toString()}
        scrollEnabled={false}
        contentContainerStyle={{ gap: 20 }}
        renderItem={({ item }) => (
          <View style={styles.widget}>
            <Text style={styles.widgetName}>{item.name}</Text>
            <Text style={styles.widgetText}>{item.address}</Text>
            <Text style={styles.widgetText}>Practice Schedule:</Text>
            {item.practice_days.split(",").map((line, idx) => (
              <Text key={idx} style={styles.practiceLine}>{line.trim()}</Text>
            ))}
            <TouchableOpacity onPress={() => Linking.openURL(`tel:${item.phone}`)}>
              <Text style={styles.link}>📞 {item.phone}</Text>
            </TouchableOpacity>
            <Text style={styles.videoLabel}>🎥 Branch Tour</Text>
            <Text style={styles.widgetText}>{item.video_url}</Text>
          </View>
        )}
      />

      <View style={styles.authCard}>
        <Text style={styles.authText}>🚀 Ready to join HFA?</Text>
        <TouchableOpacity style={styles.authBtn} onPress={() => router.push("/login")}>
          <Text style={styles.authBtnText}>Login</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.authBtnAlt} onPress={() => router.push("/register")}>
          <Text style={styles.authBtnAltText}>Don’t have an account? Register now</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: { paddingTop: 60, paddingHorizontal: 15, paddingBottom: 30 },
  topBar: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingBottom: 10,
    marginBottom: 10,
  },
  hfa: {
    fontSize: 22,
    fontWeight: "bold",
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: "bold",
    marginBottom: 10,
    marginTop: 10,
  },
  widget: {
    backgroundColor: "#fff",
    padding: 15,
    borderRadius: 10,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 3,
  },
  widgetName: {
    fontSize: 16,
    fontWeight: "600",
    marginBottom: 3,
  },
  widgetText: {
    fontSize: 14,
    color: "#333",
    marginBottom: 4,
  },
  practiceLine: {
    fontSize: 14,
    color: "#333",
    marginLeft: 10,
    marginBottom: 2,
  },
  link: {
    color: "#007AFF",
    marginTop: 5,
  },
  videoLabel: {
    marginTop: 10,
    fontWeight: "600",
    color: "#333",
  },
  authCard: {
    marginTop: 30,
    backgroundColor: "#fff",
    padding: 16,
    borderRadius: 12,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 2,
    alignItems: "center",
    marginBottom: 30,
  },
  authText: {
    fontSize: 16,
    fontWeight: "600",
    marginBottom: 12,
  },
  authBtn: {
    backgroundColor: "#007AFF",
    paddingVertical: 10,
    paddingHorizontal: 24,
    borderRadius: 10,
    marginBottom: 10,
  },
  authBtnText: {
    color: "#fff",
    fontWeight: "bold",
  },
  authBtnAlt: {
    paddingVertical: 8,
  },
  authBtnAltText: {
    color: "#007AFF",
    fontWeight: "600",
  },
});