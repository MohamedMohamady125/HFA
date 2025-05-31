import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, Image } from "react-native";
import { useRouter } from "expo-router";
import { useTranslation } from "react-i18next";
import i18n from "../utils/i18n";

export default function GuestHome() {
  const router = useRouter();
  const { t } = useTranslation();

  const toggleLanguage = () => {
    const nextLang = i18n.language === "en" ? "ar" : "en";
    i18n.changeLanguage(nextLang);
  };

  return (
    <SafeAreaView style={styles.page}>
      {/* Gradient Background */}
      <View style={styles.gradientBackground} />
      <View style={styles.gradientOverlay} />

      {/* Language Toggle - Bottom Left */}
      <TouchableOpacity style={styles.langBtn} onPress={toggleLanguage}>
        <Text style={styles.langText}>
          {i18n.language === "en" ? "عربي" : "EN"}
        </Text>
      </TouchableOpacity>

      {/* Admin Button - Bottom Right */}
      <TouchableOpacity style={styles.adminBtn} onPress={() => router.push("../admin-login")}>
        <Text style={styles.adminBtnText}>⚙️</Text>
      </TouchableOpacity>

      <View style={styles.contentContainer}>
        {/* Elegant Header */}
        <View style={styles.header}>
          <View style={styles.brandContainer}>
            <Image 
              source={require('../assets/images/hfanew.png')} // ← Try with one dot
              style={styles.logoImage}
              resizeMode="contain"
            />
            <Text style={styles.brandName}></Text>
            <Text style={styles.brandSubName}></Text>
          </View>
          <Text style={styles.title}>{t("welcome_title")}</Text>
          <Text style={styles.subtitle}>{t("branch_count")}</Text>
        </View>

        {/* Modern Card */}
        <View style={styles.mainCard}>
          {/* Branch Info */}
          <View style={styles.infoSection}>
            <View style={styles.iconContainer}>
              <Text style={styles.sectionIcon}>📍</Text>
            </View>
            <View style={styles.infoContent}>
              <Text style={styles.infoTitle}>{t("nearest_branch")}</Text>
              <Text style={styles.infoText}>{t("branch_name")}</Text>
              <Text style={styles.infoTime}>{t("practice_time")}</Text>
            </View>
          </View>

          {/* Action Buttons */}
          <View style={styles.buttonGroup}>
            <TouchableOpacity style={styles.primaryBtn} onPress={() => router.push("/login")}>
              <Text style={styles.primaryBtnText}>{t("login")}</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.secondaryBtn} onPress={() => router.push("/register")}>
              <Text style={styles.secondaryBtnText}>{t("register")}</Text>
            </TouchableOpacity>
          </View>

          {/* Secondary Action */}
          <TouchableOpacity style={styles.linkBtn} onPress={() => router.push("/(tabs)/branches")}>
            <Text style={styles.linkBtnText}>{t("view_branches")}</Text>
            <Text style={styles.linkArrow}>→</Text>
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
    background: "linear-gradient(135deg, rgba(0, 212, 255, 0.03) 0%, rgba(59, 130, 246, 0.08) 100%)",
    backgroundColor: "rgba(0, 212, 255, 0.02)",
  },
  contentContainer: {
    flex: 1,
    paddingTop: 60,
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
  brandName: {
    fontSize: 12,
    fontWeight: "600",
    color: "#1e40af",
    letterSpacing: 0.5,
    textTransform: "uppercase",
  },
  brandSubName: {
    fontSize: 12,
    fontWeight: "600",
    color: "#1e40af",
    letterSpacing: 0.5,
    textTransform: "uppercase",
    marginTop: -2,
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
  infoSection: {
    flexDirection: "row",
    alignItems: "flex-start",
    marginBottom: 24,
    padding: 16,
    backgroundColor: "#f8fafc",
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#e2e8f0",
  },
  iconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "rgba(0, 212, 255, 0.1)",
    alignItems: "center",
    justifyContent: "center",
    marginRight: 12,
  },
  sectionIcon: {
    fontSize: 18,
  },
  infoContent: {
    flex: 1,
  },
  infoTitle: {
    fontSize: 14,
    fontWeight: "600",
    color: "#00d4ff",
    marginBottom: 6,
  },
  infoText: {
    fontSize: 13,
    color: "#475569",
    marginBottom: 2,
    fontWeight: "500",
  },
  infoTime: {
    fontSize: 12,
    color: "#64748b",
    fontWeight: "400",
  },
  buttonGroup: {
    marginBottom: 20,
  },
  primaryBtn: {
    backgroundColor: "#00d4ff",
    paddingVertical: 12,
    borderRadius: 12,
    alignItems: "center",
    marginBottom: 10,
    shadowColor: "#00d4ff",
    shadowOpacity: 0.25,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
  },
  primaryBtnText: {
    color: "#ffffff",
    fontWeight: "600",
    fontSize: 15,
    letterSpacing: 0.3,
  },
  secondaryBtn: {
    borderColor: "#00d4ff",
    borderWidth: 1.5,
    borderRadius: 12,
    paddingVertical: 12,
    alignItems: "center",
    backgroundColor: "rgba(0, 212, 255, 0.04)",
  },
  secondaryBtnText: {
    color: "#00d4ff",
    fontWeight: "600",
    fontSize: 15,
    letterSpacing: 0.3,
  },
  linkBtn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 12,
    paddingHorizontal: 16,
    backgroundColor: "#f1f5f9",
    borderRadius: 10,
    borderWidth: 1,
    borderColor: "#e2e8f0",
  },
  linkBtnText: {
    color: "#475569",
    fontWeight: "500",
    fontSize: 13,
    marginRight: 6,
  },
  linkArrow: {
    color: "#64748b",
    fontSize: 12,
    fontWeight: "600",
  },
  langBtn: {
    position: "absolute",
    bottom: 32,
    left: 20,
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 20,
    backgroundColor: "#ffffff",
    borderWidth: 1,
    borderColor: "#e2e8f0",
    shadowColor: "#64748b",
    shadowOpacity: 0.1,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 2 },
    elevation: 3,
    zIndex: 1000,
  },
  langText: {
    fontSize: 12,
    fontWeight: "600",
    color: "#475569",
  },
  adminBtn: {
    position: "absolute",
    bottom: 32,
    right: 20,
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: "#ffffff",
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 1,
    borderColor: "#e2e8f0",
    shadowColor: "#64748b",
    shadowOpacity: 0.12,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 6,
    zIndex: 1000,
  },
  adminBtnText: {
    fontSize: 16,
  },
});