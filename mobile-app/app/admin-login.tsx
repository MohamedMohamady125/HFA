import { useState } from "react";
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  Alert,
  TouchableOpacity,
  SafeAreaView,
  Image,
  ActivityIndicator,
} from "react-native";
import { useRouter } from "expo-router";
import { useAuth } from "../context/auth"; // Adjust this path if your context folder is elsewhere
import api from "../utils/api"; // Adjust this path if your utils folder is elsewhere
import AsyncStorage from "@react-native-async-storage/async-storage";

export default function AdminLoginScreen() {
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
  
      if (user.role !== "coach" && user.role !== "head_coach") {
        Alert.alert("Access Denied", "Only coaches can access this page.");
        setLoading(false);
        return;
      }
  
      const authUser = {
        ...user,
        isLoggedIn: true,
        isApproved: Boolean(user.approved),
        token,
      };
  
      await AsyncStorage.removeItem("authUser");
      login(authUser);
  
      if (user.role === "head_coach") {
        console.log("Navigating to headcoach-branches");
        await router.replace("../headcoach-branches");
        console.log("Navigation triggered");
      } else {
        await router.replace("/(coach-tabs)/home");
      }
  
    } catch (err: any) {
      console.error("❌ Admin Login error:", err);
      Alert.alert("Login Failed", err.response?.data?.detail || "Server error");
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.page}>
      <View style={styles.gradientBackground} />
      <View style={styles.gradientOverlay} />

      <TouchableOpacity style={styles.backBtn} onPress={() => router.back()}>
        <Text style={styles.backBtnText}>←</Text>
      </TouchableOpacity>

      <View style={styles.contentContainer}>
        <View style={styles.header}>
          <View style={styles.brandContainer}>
          <Image
  source={require("../assets/images/hfanew.png")}
  style={styles.logoImage}
  resizeMode="contain"
/>
          </View>
          <Text style={styles.title}>Coach Portal</Text>
          <Text style={styles.subtitle}>Access your coaching dashboard</Text>
        </View>

        <View style={styles.mainCard}>
          <View style={styles.inputContainer}>
            <Text style={styles.inputLabel}>Email Address</Text>
            <TextInput
              placeholder="Enter your coach email"
              value={email}
              onChangeText={setEmail}
              keyboardType="email-address"
              autoCapitalize="none"
              style={styles.input}
              placeholderTextColor="#94a3b8"
              editable={!loading}
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
              editable={!loading}
            />
          </View>

          <TouchableOpacity
            style={[styles.loginBtn, loading && styles.loginBtnDisabled]}
            onPress={handleLogin}
            disabled={loading}
          >
            {loading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.loginBtnText}>Sign In</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.forgotBtn}
            onPress={() => router.push("/forgot-password")}
          >
            <Text style={styles.forgotBtnText}>Forgot Password?</Text>
          </TouchableOpacity>
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  page: {
    flex: 1,
    backgroundColor: "#fafbfc",
  },
  gradientBackground: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#f8fafc",
  },
  gradientOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(0, 212, 255, 0.02)",
  },
  backBtn: {
    position: "absolute",
    top: 60,
    left: 20,
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: "#ffffff",
    alignItems: "center",
    justifyContent: "center",
    shadowColor: "#64748b",
    shadowOpacity: 0.12,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 6,
    zIndex: 1000,
    borderWidth: 1,
    borderColor: "#e2e8f0",
  },
  backBtnText: {
    fontSize: 16,
    color: "#475569",
    fontWeight: "600",
  },
  contentContainer: {
    flex: 1,
    paddingTop: 120,
    paddingHorizontal: 20,
    alignItems: "center",
    justifyContent: "flex-start",
  },
  header: {
    alignItems: "center",
    marginBottom: 32,
  },
  brandContainer: {
    alignItems: "center",
    marginBottom: 16,
  },
  logoImage: {
    width: 120,
    height: 120,
    marginBottom: 12,
  },
  title: {
    fontSize: 24,
    fontWeight: "700",
    color: "#1e293b",
    marginBottom: 6,
    textAlign: "center",
    letterSpacing: -0.3,
  },
  subtitle: {
    fontSize: 14,
    color: "#64748b",
    textAlign: "center",
    fontWeight: "500",
  },
  mainCard: {
    backgroundColor: "#ffffff",
    borderRadius: 20,
    padding: 24,
    width: "100%",
    maxWidth: 360,
    shadowColor: "#0ea5e9",
    shadowOpacity: 0.08,
    shadowRadius: 24,
    shadowOffset: { width: 0, height: 8 },
    elevation: 8,
    borderWidth: 1,
    borderColor: "rgba(226, 232, 240, 0.8)",
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
    backgroundColor: "#f8fafc",
    borderWidth: 1,
    borderColor: "#e2e8f0",
    padding: 16,
    borderRadius: 12,
    fontSize: 16,
    color: "#1e293b",
    fontWeight: "500",
  },
  loginBtn: {
    backgroundColor: "#00d4ff",
    paddingVertical: 12,
    borderRadius: 12,
    alignItems: "center",
    marginTop: 8,
    marginBottom: 20,
    shadowColor: "#00d4ff",
    shadowOpacity: 0.25,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
  },
  loginBtnDisabled: {
    backgroundColor: "#94a3b8",
    shadowOpacity: 0.1,
  },
  loginBtnText: {
    color: "#ffffff",
    fontWeight: "600",
    fontSize: 15,
    letterSpacing: 0.3,
  },
  forgotBtn: {
    alignSelf: "center",
    padding: 8,
  },
  forgotBtnText: {
    fontSize: 14,
    fontWeight: "500",
    color: "#64748b",
  },
});