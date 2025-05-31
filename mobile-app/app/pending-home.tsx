import { View, Text, StyleSheet, TouchableOpacity, Linking } from "react-native";
import { useEffect, useState } from "react";
import { useRouter } from "expo-router";
import * as Location from "expo-location";

const branches = [
  {
    id: "1",
    name: "Downtown Branch",
    practiceTime: "Mon–Fri, 4PM–6PM",
    phone: "0123456789",
    location: { latitude: 30.0444, longitude: 31.2357 },
  },
  {
    id: "2",
    name: "Hadayek Al Ahram Branch",
    practiceTime: "Sat–Wed, 5PM–7PM",
    phone: "0987654321",
    location: { latitude: 30.0626, longitude: 31.2497 },
  },
];

export default function PendingHome() {
  const progressPercent = 66;
  const router = useRouter();
  const [nearest, setNearest] = useState<any>(null);

  useEffect(() => {
    (async () => {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== "granted") return;

      const userLoc = await Location.getCurrentPositionAsync({});
      const nearestBranch = branches.reduce((prev, curr) => {
        const prevDist = Math.abs(userLoc.coords.latitude - prev.location.latitude) +
                         Math.abs(userLoc.coords.longitude - prev.location.longitude);
        const currDist = Math.abs(userLoc.coords.latitude - curr.location.latitude) +
                         Math.abs(userLoc.coords.longitude - curr.location.longitude);
        return currDist < prevDist ? curr : prev;
      });

      setNearest(nearestBranch);
    })();
  }, []);

  return (
    <View style={styles.page}>
      <View style={styles.card}>
        <Text style={styles.title}>⏳ Waiting for Approval</Text>
        <Text style={styles.subtext}>Your account is under review by the coach.</Text>
        <View style={styles.progressBar}>
          <View style={[styles.progressFill, { width: `${progressPercent}%` }]} />
        </View>
        <Text style={styles.progressText}>{progressPercent}% complete</Text>
      </View>

      {nearest && (
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>📍 Nearest Branch</Text>
          <Text style={styles.branchText}>{nearest.name}</Text>
          <Text style={styles.branchDetail}>{nearest.practiceTime}</Text>
          <Text
            style={styles.link}
            onPress={() => Linking.openURL(`tel:${nearest.phone}`)}
          >
            📞 {nearest.phone}
          </Text>
        </View>
      )}

      <TouchableOpacity
        style={styles.ctaButton}
        onPress={() => router.push("/branches")}
      >
        <Text style={styles.ctaButtonText}>📽️ View All Branches & Videos</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  page: {
    flex: 1,
    padding: 20,
    backgroundColor: "#f5f9ff",
  },
  card: {
    backgroundColor: "#fff",
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 3,
  },
  title: {
    fontSize: 18,
    fontWeight: "700",
    marginBottom: 6,
    color: "#333",
  },
  subtext: {
    fontSize: 14,
    marginBottom: 10,
    color: "#555",
  },
  progressBar: {
    height: 10,
    backgroundColor: "#eee",
    borderRadius: 5,
    overflow: "hidden",
  },
  progressFill: {
    height: 10,
    backgroundColor: "#007AFF",
  },
  progressText: {
    marginTop: 6,
    fontSize: 12,
    color: "#888",
    textAlign: "right",
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: "600",
    marginBottom: 6,
    color: "#333",
  },
  branchText: {
    fontSize: 15,
    fontWeight: "500",
    color: "#222",
  },
  branchDetail: {
    fontSize: 13,
    color: "#555",
    marginTop: 2,
  },
  ctaButton: {
    backgroundColor: "#34a853",
    paddingVertical: 14,
    borderRadius: 10,
    alignItems: "center",
  },
  ctaButtonText: {
    color: "#fff",
    fontWeight: "600",
    fontSize: 16,
  },
  link: {
    color: "#007AFF",
    marginTop: 4,
  },
});