// ✅ FILE: app/index.tsx
import { useEffect } from "react";
import { useRouter } from "expo-router";
import { View, Text, StyleSheet } from "react-native";
import '../utils/i18n'; // ⬅️ relative path, must be top-most import


export default function Index() {
  const router = useRouter();

  useEffect(() => {
    const timer = setTimeout(() => {
      router.replace("/guest-home"); 
    }, 2000);

    return () => clearTimeout(timer);
  }, []);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Welcome to HFA</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: "center", alignItems: "center" },
  title: { fontSize: 24, fontWeight: "bold" },
});