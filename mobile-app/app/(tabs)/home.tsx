// FILE: app/(tabs)/home.tsx
import { useEffect, useState } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  Linking,
  StyleSheet,
  ScrollView,
} from "react-native";
import * as Location from "expo-location";
import { Ionicons } from "@expo/vector-icons";
import { getDistance } from "geolib";
import { useRouter } from "expo-router";
import { useAuth } from "../../context/auth";

const branches = [
  {
    id: "1",
    name: "Downtown Branch",
    practiceTime: "Mon–Fri, 4PM–6PM",
    phone: "0123456789",
    location: { latitude: 30.0444, longitude: 31.2357 },
    videoUrl: "https://example.com/video1.mp4",
  },
  {
    id: "2",
    name: "Hadayek Al Ahram Branch",
    practiceTime: "Sat–Wed, 5PM–7PM",
    phone: "0987654321",
    location: { latitude: 30.0626, longitude: 31.2497 },
    videoUrl: "https://example.com/video2.mp4",
  },
];

export default function HomeScreen() {
  const router = useRouter();
  const { user } = useAuth();

  const [nearest, setNearest] = useState<any>(null);
  const [progressPercent, setProgressPercent] = useState<number>(0);

  useEffect(() => {
    (async () => {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== "granted") return;

      const userLoc = await Location.getCurrentPositionAsync({});
      const nearestBranch = branches.reduce((prev, curr) => {
        const prevDist = getDistance(userLoc.coords, prev.location);
        const currDist = getDistance(userLoc.coords, curr.location);
        return currDist < prevDist ? curr : prev;
      });

      setNearest(nearestBranch);
    })();
  }, []);

  useEffect(() => {
    if (user?.isLoggedIn && !user.isApproved) {
      setProgressPercent(66);
    }
  }, [user]);

  return (
    <ScrollView contentContainerStyle={styles.page}>
      <Text style={styles.pageTitle}>🏠 Welcome to HFA</Text>

      {user?.isLoggedIn && !user.isApproved && (
        <View style={styles.card}>
          <Text style={styles.title}>⏳ Verification Pending</Text>
          <Text>Your account is being reviewed by a coach.</Text>
          <View style={styles.progressBar}>
            <View style={[styles.progressFill, { width: `${progressPercent}%` }]} />
          </View>
          <Text style={styles.percent}>{progressPercent}% complete</Text>
        </View>
      )}

      {nearest && (
        <View style={styles.card}>
          <Text style={styles.title}>📍 Nearest Branch</Text>
          <Text style={styles.branchName}>{nearest.name}</Text>
          <Text>{nearest.practiceTime}</Text>
          <TouchableOpacity onPress={() => Linking.openURL(`tel:${nearest.phone}`)}>
            <Text style={styles.link}>📞 {nearest.phone}</Text>
          </TouchableOpacity>
          <Text style={styles.videoLabel}>🎥 Welcome Video</Text>
          <Text>{nearest.videoUrl}</Text>
        </View>
      )}

      <TouchableOpacity
        style={styles.button}
        onPress={() => router.push("/branches")}
      >
        <Text style={styles.buttonText}>🌍 View All Branches & Videos</Text>
      </TouchableOpacity>

      {!user?.isLoggedIn && (
  <View style={styles.joinCard}>
    <Text style={styles.joinTitle}>🏋️ Want to join the best fitness academy in Egypt?</Text>

    {/* ✅ LOGIN Button */}
    <TouchableOpacity
      style={styles.loginBtn}
      onPress={() => router.push("/login")} // Make sure /login.tsx exists in /app/
    >
      <Text style={styles.loginText}>Login</Text>
    </TouchableOpacity>

    {/* ✅ REGISTER Button */}
    <TouchableOpacity
      style={styles.registerBtn}
      onPress={() => router.push("/register")} // Make sure /register.tsx exists in /app/
    >
      <Text style={styles.registerText}>Register</Text>
    </TouchableOpacity>
  </View>
)
      }
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: {
    paddingTop: 60,
    paddingHorizontal: 16,
    paddingBottom: 30,
  },
  pageTitle: {
    fontSize: 22,
    fontWeight: "bold",
    marginBottom: 20,
    textAlign: "center",
  },
  card: {
    backgroundColor: "#fff",
    borderRadius: 10,
    padding: 16,
    marginBottom: 20,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 2,
  },
  title: {
    fontSize: 18,
    fontWeight: "bold",
    marginBottom: 6,
  },
  branchName: {
    fontSize: 16,
    fontWeight: "600",
    marginBottom: 3,
  },
  link: {
    marginTop: 5,
    color: "#007AFF",
    fontWeight: "600",
  },
  videoLabel: {
    marginTop: 10,
    fontWeight: "600",
    color: "#333",
  },
  progressBar: {
    height: 10,
    backgroundColor: "#eee",
    borderRadius: 5,
    marginTop: 10,
    overflow: "hidden",
  },
  progressFill: {
    height: 10,
    backgroundColor: "#007AFF",
  },
  percent: {
    fontSize: 12,
    color: "#666",
    textAlign: "right",
    marginTop: 4,
  },
  button: {
    backgroundColor: "#28a745",
    padding: 14,
    borderRadius: 10,
    alignItems: "center",
    marginBottom: 20,
  },
  buttonText: {
    color: "#fff",
    fontWeight: "600",
    fontSize: 16,
  },
  joinCard: {
    backgroundColor: "#fff",
    borderRadius: 10,
    padding: 16,
    marginTop: 20,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 2,
    alignItems: "center",
  },
  joinTitle: {
    fontSize: 18,
    fontWeight: "600",
    marginBottom: 12,
    textAlign: "center",
  },
  loginBtn: {
    backgroundColor: "#007AFF",
    paddingVertical: 10,
    paddingHorizontal: 30,
    borderRadius: 8,
    marginBottom: 10,
  },
  loginText: {
    color: "#fff",
    fontWeight: "bold",
  },
  registerBtn: {
    borderColor: "#007AFF",
    borderWidth: 1,
    borderRadius: 8,
    paddingVertical: 10,
    paddingHorizontal: 30,
  },
  registerText: {
    color: "#007AFF",
    fontWeight: "bold",
  },
});