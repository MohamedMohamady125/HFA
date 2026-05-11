import { useEffect, useRef, useState } from "react";
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  ActivityIndicator,
  SafeAreaView,
  TouchableOpacity,
  Alert,
} from "react-native";
import axios from "axios";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";

const BASE_URL = "http://192.168.1.8:8000";

export default function AthleteThreadsScreen() {
  const [threads, setThreads] = useState<any[]>([]);
  const [posts, setPosts] = useState<any[]>([]);
  const [selectedThread, setSelectedThread] = useState<any | null>(null);
  const [loading, setLoading] = useState(true);
  const [postsLoading, setPostsLoading] = useState(false);
  const [branchName, setBranchName] = useState<string>("");
  const flatListRef = useRef<FlatList>(null);
  const router = useRouter();

  const fetchData = async () => {
    try {
      setLoading(true);
      const storedUser = await AsyncStorage.getItem("authUser");
      if (!storedUser) {
        Alert.alert("Error", "No user data found. Please log in again.");
        return;
      }

      const { token } = JSON.parse(storedUser);
      const headers = { Authorization: `Bearer ${token}` };

      // 1. Get user info including branch ID
      const meRes = await axios.get(`${BASE_URL}/users/me`, { headers });
      const branchId = meRes.data.branch_id;

      // 2. Fetch branch name
      const branchRes = await axios.get(`${BASE_URL}/branches/${branchId}`, { headers });
      setBranchName(branchRes.data.name);

      // 3. Fetch threads for the branch
      const threadsRes = await axios.get(`${BASE_URL}/threads/branch/${branchId}`, { headers });
      let fetchedThreads = threadsRes.data;

      // 4. Replace thread titles like "Branch {branchId} General" with "Branch: {branchName} General"
      fetchedThreads = fetchedThreads.map((thread: any) => {
        const regex = new RegExp(`Branch\\s+${branchId}\\s+General`, "i");
        if (regex.test(thread.title)) {
          return {
            ...thread,
            title: `Branch: ${branchRes.data.name} `,
          };
        }
        return thread;
      });

      // 5. Filter out gear and equipment threads
      const filtered = fetchedThreads.filter(
        (t: any) =>
          !t.title.toLowerCase().includes("gear") &&
          !t.title.toLowerCase().includes("equipment")
      );

      setThreads(filtered);

      // 6. Auto-select first thread if exists
      if (filtered.length > 0) {
        await selectThread(filtered[0], headers);
      }
    } catch (error: any) {
      const errorMessage = error.response?.data?.detail || error.message || "Unknown error";
      Alert.alert("Error", `Failed to load threads: ${errorMessage}`);
    } finally {
      setLoading(false);
    }
  };

  const selectThread = async (thread: any, headersOverride?: any) => {
    try {
      setPostsLoading(true);
      setSelectedThread(thread);

      const storedUser = await AsyncStorage.getItem("authUser");
      const { token } = JSON.parse(storedUser || "{}");
      const headers = headersOverride || { Authorization: `Bearer ${token}` };

      const postsRes = await axios.get(`${BASE_URL}/threads/${thread.id}/posts`, { headers });
      setPosts(postsRes.data);
    } catch (error: any) {
      const errorMessage = error.response?.data?.detail || error.message || "Unknown error";
      Alert.alert("Error", `Failed to load posts: ${errorMessage}`);
    } finally {
      setPostsLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const formatDate = (iso: string) => {
    try {
      return new Date(iso).toLocaleDateString(undefined, {
        weekday: "short",
        year: "numeric",
        month: "short",
        day: "numeric",
      });
    } catch {
      return "Invalid Date";
    }
  };

  const formatTime = (iso: string) => {
    try {
      return new Date(iso).toLocaleTimeString(undefined, {
        hour: "2-digit",
        minute: "2-digit",
      });
    } catch {
      return "Invalid Time";
    }
  };

  const groupedPosts = posts.reduceRight((acc: any[], post, i) => {
    const date = formatDate(post.created_at);
    const prevDate = i < posts.length - 1 ? formatDate(posts[i + 1]?.created_at) : null;

    if (date !== prevDate) {
      acc.push({ type: "date", id: `date-${i}`, date });
    }

    acc.push({ type: "message", ...post });
    return acc;
  }, []).reverse();

  if (loading) {
    return (
      <View style={styles.loading}>
        <View style={styles.loadingCard}>
          <ActivityIndicator size="large" color="#00BCD4" />
          <Text style={styles.loadingText}>Loading threads...</Text>
        </View>
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color="#ffffff" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>💬 Branch Threads{branchName ? ` - ${branchName}` : ""}</Text>
      </View>

      {threads.length === 0 ? (
        <View style={styles.noThreads}>
          <Text style={styles.noThreadsText}>No threads available</Text>
        </View>
      ) : (
        <>
          <View style={styles.threadList}>
            {threads.map((thread) => (
              <TouchableOpacity
                key={thread.id}
                style={[
                  styles.threadButton,
                  selectedThread?.id === thread.id && styles.threadButtonActive,
                ]}
                onPress={() => selectThread(thread)}
              >
                <Text
                  style={[
                    styles.threadButtonText,
                    selectedThread?.id === thread.id && styles.threadButtonTextActive,
                  ]}
                >
                  {thread.title}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          {postsLoading ? (
            <View style={styles.postsLoading}>
              <ActivityIndicator size="large" color="#00BCD4" />
              <Text style={styles.loadingText}>Loading messages...</Text>
            </View>
          ) : posts.length === 0 ? (
            <View style={styles.noPosts}>
              <Text style={styles.noPostsText}>
                {selectedThread ? `No messages in "${selectedThread.title}" yet` : "Select a thread to view messages"}
              </Text>
            </View>
          ) : (
            <FlatList
              ref={flatListRef}
              data={groupedPosts}
              keyExtractor={(item) => item.id?.toString() || item.date}
              renderItem={({ item }) =>
                item.type === "date" ? (
                  <View style={styles.dateHeader}>
                    <Text style={styles.dateHeaderText}>{item.date}</Text>
                  </View>
                ) : (
                  <View style={styles.bubble}>
                    <Text style={styles.message}>{item.message}</Text>
                    <Text style={styles.meta}>
                      — {item.author} | {formatTime(item.created_at)}
                    </Text>
                  </View>
                )
              }
              contentContainerStyle={{ paddingBottom: 80, paddingTop: 12, paddingHorizontal: 16 }}
              inverted
            />
          )}
        </>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#E6F2FF", // Light blue background
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 20,
    paddingTop: 50,
    paddingBottom: 20,
    backgroundColor: "#3399FF",
    borderBottomWidth: 1,
    borderBottomColor: "#2b89e0",
  },
  backButton: {
    padding: 8,
    borderRadius: 12,
    backgroundColor: "#5aaeff",
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: "700",
    marginLeft: 16,
    color: "#ffffff",
    letterSpacing: -0.3,
  },
  threadList: {
    flexDirection: "row",
    flexWrap: "wrap",
    padding: 16,
    backgroundColor: "#D0E7FF",
    borderBottomWidth: 1,
    borderBottomColor: "#99ccff",
  },
  threadButton: {
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 25,
    backgroundColor: "#99ccff",
    margin: 6,
  },
  threadButtonActive: {
    backgroundColor: "#3399FF",
    shadowColor: "#1a73e8",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  threadButtonText: {
    color: "#003366",
    fontWeight: "600",
    fontSize: 14,
  },
  threadButtonTextActive: {
    color: "#ffffff",
    fontWeight: "700",
  },
  bubble: {
    backgroundColor: "#CDE7FF",
    padding: 16,
    borderRadius: 16,
    marginTop: 12,
    borderWidth: 1,
    borderColor: "#99cfff",
  },
  message: {
    fontSize: 16,
    color: "#003366",
    fontWeight: "500",
    lineHeight: 22,
  },
  meta: {
    fontSize: 13,
    color: "#336699",
    marginTop: 8,
    textAlign: "left",
    fontWeight: "500",
  },
  dateHeader: {
    alignSelf: "center",
    backgroundColor: "#99ccff",
    borderRadius: 12,
    paddingVertical: 6,
    paddingHorizontal: 16,
    marginTop: 20,
  },
  dateHeaderText: {
    fontSize: 14,
    fontWeight: "700",
    color: "#003366",
  },
  loading: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#E6F2FF",
  },
  loadingCard: {
    backgroundColor: "#ffffff",
    borderRadius: 24,
    padding: 40,
    alignItems: "center",
    borderWidth: 1,
    borderColor: "#3399FF",
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: "#1a73e8",
    fontWeight: "600",
  },
  postsLoading: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  noThreads: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  noThreadsText: {
    fontSize: 18,
    color: "#005580",
    textAlign: "center",
    fontWeight: "600",
  },
  noPosts: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: 20,
  },
  noPostsText: {
    fontSize: 16,
    color: "#003366",
    textAlign: "center",
    fontWeight: "500",
    lineHeight: 24,
  },
});