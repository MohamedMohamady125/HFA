import { useState } from "react";
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Alert, SafeAreaView } from "react-native";
import { useRouter } from "expo-router";
import { useAuth } from "../context/auth";
import api from "../utils/api";
import AsyncStorage from "@react-native-async-storage/async-storage";

export default function AthleteLoginScreen() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const { login } = useAuth();

  const handleLogin = async () => {
    if (!email || !password) {
      Alert.alert("Error", "Please fill in all fields");
      return;
    }

    try {
      setLoading(true);
      const res = await api.post("/auth/login", { email, password });
      const { token } = res.data;
      const userRes = await api.get("/users/me", {
        headers: { Authorization: `Bearer ${token}` },
      });
      const user = userRes.data;
      console.log("🧾 Athlete login - user.role is:", user.role);
      
      // ✅ Reject if not athlete
      if (user.role !== "athlete") {
        Alert.alert("Access Denied", "Only athletes can login here.");
        return;
      }

      const isApproved = user.approved === true || user.approved === 1;
      const authUser = {
        ...user,
        isLoggedIn: true,
        isApproved,
        token,
      };
      
      await AsyncStorage.setItem("authUser", JSON.stringify(authUser));
      login(authUser);
      
      // ✅ Redirect based on approval status
      if (isApproved) {
        router.replace("/(athlete-tabs)/home");
      } else {
        router.replace("/pending-home-test");
      }
    } catch (err: any) {
      console.error("❌ Athlete Login error:", err);
      Alert.alert("Login Failed", err.response?.data?.detail || "Server error");
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Background Overlay */}
      <View style={styles.backgroundOverlay} />
      
      {/* Back Button */}
      <TouchableOpacity style={styles.backBtn} onPress={() => router.back()}>
        <Text style={styles.backBtnText}>←</Text>
      </TouchableOpacity>

      {/* Main Content */}
      <View style={styles.contentContainer}>
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.logoContainer}>
            <Text style={styles.logoIcon}>A</Text>
          </View>
          <Text style={styles.title}>Athlete Login</Text>
          <Text style={styles.subtitle}>Welcome back, champion!</Text>
        </View>

        {/* Glass Card */}
        <View style={styles.glassCard}>
          <View style={styles.inputContainer}>
            <Text style={styles.inputLabel}>Email Address</Text>
            <TextInput
              placeholder="Enter your email"
              value={email}
              onChangeText={setEmail}
              keyboardType="email-address"
              autoCapitalize="none"
              style={styles.input}
              placeholderTextColor="#94a3b8"
            />
          </View>

          <View style={styles.inputContainer}>
            <Text style={styles.inputLabel}>Password</Text>
            <TextInput
              placeholder="Enter your password"
              value={password}
              onChangeText={setPassword}
              secureTextEntry
              style={styles.input}
              placeholderTextColor="#94a3b8"
            />
          </View>

          <TouchableOpacity 
            style={[styles.loginBtn, loading && styles.loginBtnDisabled]} 
            onPress={handleLogin}
            disabled={loading}
          >
            <Text style={styles.loginBtnText}>
              {loading ? "Logging in..." : "Login"}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.forgotBtn}>
            <Text style={styles.forgotBtnText}>Forgot Password?</Text>
          </TouchableOpacity>
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#e6f7ff",
  },
  backgroundOverlay: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: "rgba(0, 212, 255, 0.1)",
  },
  backBtn: {
    position: "absolute",
    top: 60,
    left: 24,
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: "rgba(255, 255, 255, 0.9)",
    alignItems: "center",
    justifyContent: "center",
    shadowColor: "#00d4ff",
    shadowOpacity: 0.2,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
    zIndex: 1000,
    borderWidth: 1,
    borderColor: "rgba(0, 212, 255, 0.2)",
  },
  backBtnText: {
    fontSize: 20,
    color: "#00d4ff",
    fontWeight: "600",
  },
  contentContainer: {
    flex: 1,
    paddingTop: 120,
    paddingHorizontal: 24,
    alignItems: "center",
    justifyContent: "flex-start",
  },
  header: {
    alignItems: "center",
    marginBottom: 32,
  },
  logoContainer: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: "rgba(255, 255, 255, 0.9)",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 20,
    shadowColor: "#00d4ff",
    shadowOpacity: 0.3,
    shadowRadius: 20,
    shadowOffset: { width: 0, height: 8 },
    elevation: 8,
    borderWidth: 1,
    borderColor: "rgba(0, 212, 255, 0.2)",
  },
  logoIcon: {
    fontSize: 32,
    color: "#00d4ff",
    fontWeight: "800",
  },
  title: {
    fontSize: 28,
    fontWeight: "800",
    color: "#00d4ff",
    marginBottom: 8,
    textAlign: "center",
    letterSpacing: -0.5,
  },
  subtitle: {
    fontSize: 16,
    color: "#64748b",
    textAlign: "center",
    fontWeight: "500",
  },
  glassCard: {
    backgroundColor: "rgba(255, 255, 255, 0.85)",
    borderRadius: 24,
    padding: 28,
    width: "100%",
    maxWidth: 400,
    shadowColor: "#00d4ff",
    shadowOpacity: 0.2,
    shadowRadius: 30,
    shadowOffset: { width: 0, height: 15 },
    elevation: 10,
    borderWidth: 1,
    borderColor: "rgba(255, 255, 255, 0.3)",
  },
  inputContainer: {
    marginBottom: 20,
  },
  inputLabel: {
    fontSize: 14,
    fontWeight: "600",
    color: "#475569",
    marginBottom: 8,
    marginLeft: 4,
  },
  input: {
    backgroundColor: "rgba(248, 250, 252, 0.8)",
    borderWidth: 1,
    borderColor: "rgba(0, 212, 255, 0.2)",
    padding: 16,
    borderRadius: 12,
    fontSize: 16,
    color: "#1e293b",
    fontWeight: "500",
  },
  loginBtn: {
    backgroundColor: "#00d4ff",
    paddingVertical: 16,
    paddingHorizontal: 32,
    borderRadius: 16,
    alignItems: "center",
    marginTop: 8,
    marginBottom: 16,
    shadowColor: "#00d4ff",
    shadowOpacity: 0.4,
    shadowRadius: 15,
    shadowOffset: { width: 0, height: 6 },
    elevation: 6,
  },
  loginBtnDisabled: {
    backgroundColor: "#94a3b8",
    shadowOpacity: 0.2,
  },
  loginBtnText: {
    color: "#ffffff",
    fontWeight: "700",
    fontSize: 18,
    letterSpacing: 0.5,
  },
  forgotBtn: {
    alignSelf: "center",
    padding: 8,
  },
  forgotBtnText: {
    fontSize: 14,
    fontWeight: "600",
    color: "#00d4ff",
  },
});