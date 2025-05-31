// FILE: app/utils/api.ts

import axios from "axios";
import AsyncStorage from "@react-native-async-storage/async-storage";

const api = axios.create({
  baseURL: process.env.EXPO_PUBLIC_API_URL || "http://192.168.1.8:8000",
});

api.interceptors.request.use(async (config) => {
  try {
    const stored = await AsyncStorage.getItem("authUser");
    const user = stored ? JSON.parse(stored) : null;

    if (user?.token) {
      config.headers.Authorization = `Bearer ${user.token}`;
      if (__DEV__) console.log("🔐 Using token:", user.token);
    } else if (__DEV__) {
      console.warn("🚨 No token found in AsyncStorage! (maybe before login)");
    }
  } catch (e) {
    console.error("❌ Error parsing token from AsyncStorage", e);
  }

  return config;
});

export default api;