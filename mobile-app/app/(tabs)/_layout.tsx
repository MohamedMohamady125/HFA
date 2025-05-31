import { Tabs } from "expo-router";
import { Ionicons } from "@expo/vector-icons";

export default function TabsLayout() {
  return (
    <Tabs screenOptions={{ headerShown: false }}>
      <Tabs.Screen name="home" options={{ title: "Home", tabBarIcon: ({ color, size }) => (
        <Ionicons name="home-outline" size={size} color={color} />
      ) }} />
      <Tabs.Screen name="branches" options={{ title: "Branches", tabBarIcon: ({ color, size }) => (
        <Ionicons name="business-outline" size={size} color={color} />
      ) }} />
      <Tabs.Screen name="contact" options={{ title: "Contact", tabBarIcon: ({ color, size }) => (
        <Ionicons name="call-outline" size={size} color={color} />
      ) }} />
      <Tabs.Screen name="profile" options={{ title: "Profile", tabBarIcon: ({ color, size }) => (
        <Ionicons name="person-outline" size={size} color={color} />
      ) }} />
    </Tabs>
  );
}
