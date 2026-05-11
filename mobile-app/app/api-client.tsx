// apiClient.ts
import axios from "axios";
import AsyncStorage from "@react-native-async-storage/async-storage";

const api = axios.create({
  baseURL: "http://YOUR_BACKEND_URL/api", // Replace with your backend URL
  timeout: 10000,
});

api.interceptors.request.use(async (config) => {
  const token = await AsyncStorage.getItem("jwt_token");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default api;