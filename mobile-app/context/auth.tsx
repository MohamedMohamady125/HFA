import { createContext, useContext, useEffect, useState } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import api from "../utils/api";

const AuthContext = createContext<any>(null);

export const AuthProvider = ({ children }: any) => {
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  // ✅ Clean load: remove invalid/stale tokens and load fresh
  useEffect(() => {
    const loadUser = async () => {
      try {
        await AsyncStorage.removeItem("authUser"); // 🔥 force clear
        setUser(null);
      } catch (e) {
        console.error("Failed to clear old authUser", e);
      } finally {
        setLoading(false);
      }
    };
    loadUser();
  }, []);

  // ✅ Login
  const login = async (userData: any) => {
    console.log("Logging in user:", userData);
    setUser(userData);
    await AsyncStorage.setItem("authUser", JSON.stringify(userData));
  };

  // ✅ Logout
  const logout = async () => {
    setUser(null);
    await AsyncStorage.removeItem("authUser");
  };

  // ✅ Optional manual refresh
  const refreshUser = async () => {
    try {
      if (!user?.token) return;
      const res = await api.get("/users/me", {
        headers: { Authorization: `Bearer ${user.token}` },
      });

      const updated = {
        ...res.data,
        isLoggedIn: true,
        isApproved: Boolean(res.data.approved),
        token: user.token,
      };

      setUser(updated);
      await AsyncStorage.setItem("authUser", JSON.stringify(updated));
    } catch (e) {
      console.error("❌ Failed to refresh user:", e);
      await logout();
    }
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, refreshUser }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);