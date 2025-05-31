// ✅ FILE: app/_layout.tsx
import { Slot, useRouter, useSegments, useLocalSearchParams } from "expo-router";
import { useEffect } from "react";
import { View, ActivityIndicator } from "react-native";
import { AuthProvider, useAuth } from "../context/auth";
import '../utils/i18n';

function InnerLayout() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const segments = useSegments();
  const params = useLocalSearchParams();

  useEffect(() => {
    if (loading) return;

    const group = segments[0];
    const currentRoute = segments.join("/");

    const isPublic = [
      "guest-home", "pending-home-test", "athlete-home-test",
      "services", "login", "register", "admin-login", "forgot-password",
    ].includes(currentRoute);

    const isCoachAllowedRoute = ["edit-profile", "change-password"].includes(currentRoute);

    if (!user && !isPublic && group !== "(tabs)") {
      router.replace("/guest-home");
      return;
    }

    if (user?.isLoggedIn && !user.isApproved && group !== "(tabs)") {
      router.replace("/pending-home-test");
      return;
    }

    if (
      user?.isLoggedIn &&
      user.isApproved &&
      user.role === "coach" &&
      !["(coach-tabs)", "(coach-manage)"].includes(group) &&
      !isCoachAllowedRoute
    ) {
      router.replace("/(coach-tabs)/home");
      return;
    }

    if (
      user?.isLoggedIn &&
      user.isApproved &&
      user.role === "head_coach" &&
      group !== "(coach-tabs)" &&
      !params.override_branch
    ) {
      router.replace("/head-coach-branches");
      return;
    }

    if (
      user?.isLoggedIn &&
      user.isApproved &&
      user.role === "athlete" &&
      group !== "(athlete-tabs)"
    ) {
      router.replace("/(athlete-tabs)/home");
      return;
    }
  }, [user, loading, segments]);

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  return <Slot />;
}

export default function RootLayout() {
  return (
    <AuthProvider>
      <InnerLayout />
    </AuthProvider>
  );
}