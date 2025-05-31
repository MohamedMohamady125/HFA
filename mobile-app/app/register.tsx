import { useState } from "react";
import { 
  View, 
  Text, 
  TextInput, 
  StyleSheet, 
  Alert, 
  SafeAreaView, 
  TouchableOpacity,
  Image,
  ScrollView
} from "react-native";
import { Picker } from "@react-native-picker/picker";
import { useRouter } from "expo-router";
import api from "../utils/api";

export default function RegisterScreen() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [branchId, setBranchId] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const branches = [
    { label: "Maadi", value: "1" },
    { label: "Hadayek Al-Ahram", value: "2" },
    { label: "6th October", value: "3" },
    { label: "Nasr City", value: "4" },
    { label: "New Cairo", value: "5" },
  ];

  const getBranchLabel = (value: string) => {
    const branch = branches.find(b => b.value === value);
    return branch ? branch.label : "Select your branch";
  };

  const showBranchPicker = () => {
    Alert.alert(
      "Select Branch",
      "Choose the branch you practice at:",
      [
        ...branches.map(branch => ({
          text: branch.label,
          onPress: () => setBranchId(branch.value)
        })),
        { text: "Cancel", style: "cancel" }
      ]
    );
  };

  const handleRegister = async () => {
    if (!email || !password || !confirmPassword || !name || !phone || !branchId) {
      Alert.alert("Missing Fields", "Please fill in all fields.");
      return;
    }
    if (password !== confirmPassword) {
      Alert.alert("Password Mismatch", "Passwords do not match.");
      return;
    }
    
    try {
      setLoading(true);
      await api.post("/auth/register", {
        email,
        password,
        name,
        phone,
        branch_id: parseInt(branchId),
      });
      Alert.alert("Registration Sent", "Your request will be reviewed by a coach.");
    } catch (err: any) {
      const errorMsg = err.response?.data?.message || err.response?.data?.detail;
      Alert.alert(
        "Registration Failed",
        Array.isArray(errorMsg) ? errorMsg[0] : errorMsg || "Server error"
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.page}>
      {/* Gradient Background */}
      <View style={styles.gradientBackground} />
      <View style={styles.gradientOverlay} />
      
      {/* Back Button */}
      <TouchableOpacity style={styles.backBtn} onPress={() => router.back()}>
        <Text style={styles.backBtnText}>←</Text>
      </TouchableOpacity>

      <ScrollView contentContainerStyle={styles.contentContainer} showsVerticalScrollIndicator={false}>
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.brandContainer}>
            <Image 
              source={require('../assets/images/hfanew.png')} 
              style={styles.logoImage}
              resizeMode="contain"
            />
          </View>
          <Text style={styles.title}>Join Our Academy</Text>
          <Text style={styles.subtitle}>Create your athlete account</Text>
        </View>

        {/* Main Card */}
        <View style={styles.mainCard}>
          <View style={styles.inputContainer}>
            <Text style={styles.inputLabel}>Full Name</Text>
            <TextInput
              placeholder="Enter your full name"
              value={name}
              onChangeText={setName}
              style={styles.input}
              placeholderTextColor="#94a3b8"
            />
          </View>

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
            <Text style={styles.inputLabel}>Phone Number</Text>
            <TextInput
              placeholder="Enter your phone number"
              value={phone}
              onChangeText={setPhone}
              keyboardType="phone-pad"
              style={styles.input}
              placeholderTextColor="#94a3b8"
            />
          </View>

          <View style={styles.inputContainer}>
            <Text style={styles.inputLabel}>Password</Text>
            <TextInput
              placeholder="Create a password"
              value={password}
              secureTextEntry
              onChangeText={setPassword}
              style={styles.input}
              placeholderTextColor="#94a3b8"
            />
          </View>

          <View style={styles.inputContainer}>
            <Text style={styles.inputLabel}>Confirm Password</Text>
            <TextInput
              placeholder="Confirm your password"
              value={confirmPassword}
              secureTextEntry
              onChangeText={setConfirmPassword}
              style={styles.input}
              placeholderTextColor="#94a3b8"
            />
          </View>

          <View style={styles.inputContainer}>
            <Text style={styles.inputLabel}>Select Branch</Text>
            <TouchableOpacity style={styles.branchSelector} onPress={showBranchPicker}>
              <Text style={[styles.branchText, !branchId && styles.placeholderText]}>
                {getBranchLabel(branchId)}
              </Text>
              <Text style={styles.dropdownArrow}>▼</Text>
            </TouchableOpacity>
          </View>

          <TouchableOpacity 
            style={[styles.submitBtn, loading && styles.submitBtnDisabled]} 
            onPress={handleRegister}
            disabled={loading}
          >
            <Text style={styles.submitBtnText}>
              {loading ? "Submitting..." : "Submit Request"}
            </Text>
          </TouchableOpacity>

          <View style={styles.noteContainer}>
            <Text style={styles.noteText}>
              Your registration will be reviewed by our coaching team. You'll receive a confirmation email once approved.
            </Text>
          </View>
        </View>
      </ScrollView>
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
    paddingTop: 140,
    paddingHorizontal: 20,
    paddingBottom: 40,
    alignItems: "center",
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
  branchSelector: {
    backgroundColor: "#f8fafc",
    borderWidth: 1,
    borderColor: "#e2e8f0",
    padding: 16,
    borderRadius: 12,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    minHeight: 56,
  },
  branchText: {
    fontSize: 16,
    color: "#1e293b",
    fontWeight: "500",
    flex: 1,
  },
  placeholderText: {
    color: "#94a3b8",
    fontWeight: "400",
  },
  dropdownArrow: {
    fontSize: 12,
    color: "#64748b",
    marginLeft: 8,
  },
  submitBtn: {
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
  submitBtnDisabled: {
    backgroundColor: "#94a3b8",
    shadowOpacity: 0.1,
  },
  submitBtnText: {
    color: "#ffffff",
    fontWeight: "600",
    fontSize: 15,
    letterSpacing: 0.3,
  },
  noteContainer: {
    backgroundColor: "#f8fafc",
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: "#e2e8f0",
  },
  noteText: {
    fontSize: 13,
    color: "#64748b",
    textAlign: "center",
    lineHeight: 18,
    fontWeight: "500",
  },
});