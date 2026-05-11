import React, { createContext, useContext, useEffect, useState } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";

const AuthContext = createContext({
  user: null,
  loading: true,
  setUser: () => {},
  refreshUser: () => {},
});

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadUser = async () => {
      try {
        const storedUser = await AsyncStorage.getItem("authUser");
        if (storedUser) setUser(JSON.parse(storedUser));
      } catch (e) {
        console.error("Failed to load user", e);
      } finally {
        setLoading(false);
      }
    };
    loadUser();
  }, []);

  const refreshUser = async () => {
    const storedUser = await AsyncStorage.getItem("authUser");
    if (storedUser) setUser(JSON.parse(storedUser));
  };

  return (
    <AuthContext.Provider value={{ user, loading, setUser, refreshUser }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);