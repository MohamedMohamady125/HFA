import { useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  SafeAreaView,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import axios from "axios";
import { useRouter } from "expo-router";

const BASE_URL = "http://192.168.1.8:8000";

export default function HeadCoachLogin() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  const handleLogin = async () => {
    if (!email || !password) {
      Alert.alert("Error", "Please enter email and password");
      return;
    }

    setLoading(true);

    try {
      const res = await axios.post(`${BASE_URL}/auth/login`, {
        email,
        password,
      });

      const { token, user } = res.data;

      if (user.role !== "head_coach") {
        Alert.alert("Unauthorized", "Only head coach can login here.");
        setLoading(false);
        return;
      }

      // Save user info and token in AsyncStorage
      await AsyncStorage.setItem(
        "authUser",
        JSON.stringify({
          ...user,
          token,
        })
      );
      // Set headCoachMode flag to true
      await AsyncStorage.setItem("headCoachMode", "true");

      // Redirect to head coach branches page
      router.replace("/head-coach-branches");
    } catch (error: any) {
      console.error("Login error:", error);
      const message = error.response?.data?.detail || "Login failed";
      Alert.alert("Login Failed", message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView
        behavior={Platform.select({ ios: "padding", android: undefined })}
        style={{ flex: 1, justifyContent: "center" }}
      >
        <View style={styles.innerContainer}>
          <Text style={styles.title}>👑 Head Coach Login</Text>

          <TextInput
            placeholder="Email"
            keyboardType="email-address"
            autoCapitalize="none"
            style={styles.input}
            value={email}
            onChangeText={setEmail}
            editable={!loading}
          />

          <TextInput
            placeholder="Password"
            secureTextEntry
            style={styles.input}
            value={password}
            onChangeText={setPassword}
            editable={!loading}
          />

          <TouchableOpacity
            style={[styles.button, loading && styles.buttonDisabled]}
            onPress={handleLogin}
            disabled={loading}
          >
            {loading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.buttonText}>Login</Text>
            )}
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#f0f6fc",
  },
  innerContainer: {
    marginHorizontal: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: "700",
    marginBottom: 40,
    textAlign: "center",
    color: "#007AFF",
  },
  input: {
    height: 50,
    backgroundColor: "#fff",
    borderRadius: 10,
    paddingHorizontal: 16,
    marginBottom: 16,
    fontSize: 16,
    borderWidth: 1,
    borderColor: "#cbd5e1",
  },
  button: {
    backgroundColor: "#007AFF",
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: "center",
    marginTop: 10,
  },
  buttonDisabled: {
    backgroundColor: "#6ca0ff",
  },
  buttonText: {
    color: "#fff",
    fontWeight: "600",
    fontSize: 18,
  },
});