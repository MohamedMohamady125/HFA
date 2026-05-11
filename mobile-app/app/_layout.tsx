import { Slot, useRouter, useSegments } from "expo-router";
import { useEffect, useState } from "react";
import { View, ActivityIndicator } from "react-native";
import { AuthProvider, useAuth } from "../context/auth";
import AsyncStorage from "@react-native-async-storage/async-storage";

function InnerLayout() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const segments = useSegments();

  const [headCoachMode, setHeadCoachMode] = useState(false);

  useEffect(() => {
    const checkHeadCoachMode = async () => {
      const value = await AsyncStorage.getItem("headCoachMode");
      setHeadCoachMode(value === "true");
    };
    checkHeadCoachMode();
  }, []);

  // Render Slot immediately to avoid navigate before mount error
  if (loading) {
    return <Slot />;
  }

  useEffect(() => {
    if (loading) return;

    const group = segments[0];
    const currentRoute = segments.join("/");

    const isPublic = [
      "guest-home",
      "pending-home-test",
      "athlete-home-test",
      "services",
      "login",
      "register",
      "admin-login",
      "forgot-password",
      "head-coach-login",
      "head-coach-branches",
    ].includes(currentRoute);

    if (!user && !isPublic && group !== "(tabs)") {
      router.replace("/guest-home");
      return;
    }

    if (user?.isLoggedIn && !user.isApproved && group !== "(tabs)") {
      router.replace("/pending-home-test");
      return;
    }

    if (user?.isLoggedIn && user.isApproved) {
      if (headCoachMode && user.role === "head_coach") {
        if (group !== "head-coach-branches" && currentRoute !== "head-coach-login") {
          router.replace("/head-coach-branches");
          return;
        }
      } else if (["coach", "head_coach"].includes(user.role)) {
        if (!["(coach-tabs)", "(coach-manage)"].includes(group)) {
          router.replace("/(coach-tabs)/home");
          return;
        }
      } else if (user.role === "athlete" && group !== "(athlete-tabs)") {
        router.replace("/(athlete-tabs)/home");
        return;
      }
    }
  }, [user, loading, segments, headCoachMode]);

  return <Slot />;
}

export default function RootLayout() {
  return (
    <AuthProvider>
      <InnerLayout />
    </AuthProvider>
  );
}