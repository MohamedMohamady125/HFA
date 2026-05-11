import { useEffect, useState, useRef } from "react";
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  SafeAreaView,
  Alert,
} from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { Ionicons } from "@expo/vector-icons";
import api from "../../utils/api";
import moment from "moment";
import { useRouter, useLocalSearchParams } from "expo-router";

export default function CoachThreadsScreenUpdated() {
  const [user, setUser] = useState<any>(null);
  const [messages, setMessages] = useState<any[]>([]);
  const [messageInput, setMessageInput] = useState("");
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [threadId, setThreadId] = useState<number | null>(null);
  const [currentBranchId, setCurrentBranchId] = useState<number | null>(null);
  const [displayBranchId, setDisplayBranchId] = useState<number | null>(null);
  const flatListRef = useRef<FlatList>(null);
  const router = useRouter();
  const params = useLocalSearchParams();
  
  // Get override_branch from params - handle both string and array formats
  const override_branch = Array.isArray(params.override_branch) 
    ? params.override_branch[0] 
    : params.override_branch;

  // Load user data
  const loadUser = async () => {
    try {
      const stored = await AsyncStorage.getItem("authUser");
      const parsed = stored ? JSON.parse(stored) : null;
      if (parsed) {
        setUser(parsed);
        return parsed;
      }
      throw new Error("No user found");
    } catch (error) {
      console.error("Failed to load user:", error);
      Alert.alert("Error", "Failed to load user data");
      return null;
    }
  };

  // Get current user's branch info and determine effective branch
  const getCurrentBranch = async () => {
    try {
      const response = await api.get("/users/me");
      const actualBranchId = response.data.branch_id;
      const effectiveBranchId = override_branch ? Number(override_branch) : actualBranchId;
      
      console.log("User's actual branch ID:", actualBranchId);
      console.log("Override branch param:", override_branch);
      console.log("Effective branch ID for threads:", effectiveBranchId);
      
      // Set the actual user branch
      setCurrentBranchId(actualBranchId);
      // Set the branch to display and use for threads
      setDisplayBranchId(effectiveBranchId);
      
      return effectiveBranchId;
    } catch (error) {
      console.error("Failed to get branch info:", error);
      Alert.alert("Error", "Failed to load branch information");
      return null;
    }
  };

  // Ensure thread exists for branch and get thread ID
  const ensureThreadExists = async (branchId: number) => {
    try {
      console.log(`Fetching threads for branch ${branchId}`);
      
      // Try to get existing threads for this branch
      const threadsResponse = await api.get(`/threads/branch/${branchId}`);
      console.log(`Threads response for branch ${branchId}:`, threadsResponse.data);
      
      if (threadsResponse.data && threadsResponse.data.length > 0) {
        const threadId = threadsResponse.data[0].id;
        console.log(`Using existing thread ${threadId} for branch ${branchId}`);
        return threadId;
      }
      
      console.log(`No threads found for branch ${branchId}, backend should create one automatically`);
      
      // If no threads exist, the backend should create one automatically
      // Let's try again after a brief delay
      await new Promise(resolve => setTimeout(resolve, 1000));
      const retryResponse = await api.get(`/threads/branch/${branchId}`);
      
      if (retryResponse.data && retryResponse.data.length > 0) {
        const threadId = retryResponse.data[0].id;
        console.log(`Thread ${threadId} created automatically for branch ${branchId}`);
        return threadId;
      }
      
      throw new Error(`No threads available for branch ${branchId}`);
    } catch (error) {
      console.error("Failed to ensure thread exists:", error);
      throw error;
    }
  };

  // Load messages for a thread
  const loadMessages = async (threadId: number) => {
    try {
      console.log(`Loading messages for thread ${threadId}`);
      const response = await api.get(`/threads/${threadId}/posts`);
      console.log(`Loaded ${response.data.length} messages for thread ${threadId}`);
      
      const sortedMessages = response.data.sort((a: any, b: any) =>
        new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
      );
      setMessages(sortedMessages);
      
      // Scroll to bottom after messages load
      setTimeout(() => {
        flatListRef.current?.scrollToEnd({ animated: false });
      }, 100);
    } catch (error) {
      console.error("Failed to load messages:", error);
      setMessages([]);
      Alert.alert("Error", "Failed to load messages");
    }
  };

  // Main load function
  const loadThread = async () => {
    setLoading(true);
    try {
      console.log("=== Loading Thread ===");
      console.log("Override branch parameter:", override_branch);
      
      // Load user first
      const userData = await loadUser();
      if (!userData) {
        console.log("No user data, aborting");
        setLoading(false);
        return;
      }

      // Get branch ID (either override or user's actual branch)
      const branchId = await getCurrentBranch();
      if (!branchId) {
        console.log("No branch ID determined, aborting");
        setLoading(false);
        return;
      }

      console.log(`Using branch ID: ${branchId}`);

      // Ensure thread exists and get thread ID
      const threadId = await ensureThreadExists(branchId);
      setThreadId(threadId);

      // Load messages
      await loadMessages(threadId);

      console.log("=== Thread Loading Complete ===");

    } catch (error) {
      console.error("Thread loading failed:", error);
      setMessages([]);
      setThreadId(null);
      Alert.alert("Error", "Failed to load thread. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    console.log("Component effect triggered with override_branch:", override_branch);
    console.log("Type of override_branch:", typeof override_branch);
    console.log("Params object:", params);
    loadThread();
  }, [override_branch]);

  // Refresh messages
  const refreshMessages = async () => {
    if (threadId) {
      await loadMessages(threadId);
    }
  };

  const postMessage = async () => {
    if (!messageInput.trim() || !threadId || !user || sending) return;

    setSending(true);
    const messageText = messageInput.trim();
    
    // Create optimistic message
    const optimisticMessage = {
      id: `temp_${Date.now()}`, // Use string ID for temp messages
      user_id: user.id,
      message: messageText,
      author: user.name,
      created_at: new Date().toISOString(),
      sent: false, // Pending state
    };

    // Add optimistic message and clear input
    setMessages((prev) => [...prev, optimisticMessage]);
    setMessageInput("");
    
    // Scroll to bottom
    setTimeout(() => {
      flatListRef.current?.scrollToEnd({ animated: true });
    }, 100);

    try {
      // Send message to backend
      console.log(`Posting message to thread ${threadId}`);
      const response = await api.post(`/threads/${threadId}/post`, { 
        message: messageText 
      });

      if (response.data && (response.data.success || response.data.message)) {
        // Remove optimistic message and refresh to get real message
        setMessages((prev) => 
          prev.filter(msg => msg.id !== optimisticMessage.id)
        );
        
        // Refresh messages to get the real message with proper ID
        await refreshMessages();
        console.log("Message sent successfully");
      } else {
        throw new Error("Failed to send message");
      }
    } catch (error) {
      console.error("Message failed to send:", error);
      
      // Mark message as failed
      setMessages((prev) =>
        prev.map((msg) => 
          msg.id === optimisticMessage.id 
            ? { ...msg, sent: null } // Failed state
            : msg
        )
      );
      
      Alert.alert("Error", "Failed to send message. Please try again.");
    } finally {
      setSending(false);
    }
  };

  const renderItem = ({ item, index }: { item: any; index: number }) => {
    if (!user) return null;

    const isMine = item.user_id === user.id;
    const showDateLabel =
      index === 0 ||
      !moment(item.created_at).isSame(messages[index - 1]?.created_at, "day");

    // Status indicator for sent messages
    let statusIndicator = "";
    if (isMine) {
      if (item.sent === true) {
        statusIndicator = "✓✓"; // Delivered
      } else if (item.sent === false) {
        statusIndicator = "✓"; // Sending
      } else if (item.sent === null) {
        statusIndicator = "!"; // Failed
      }
    }

    return (
      <View>
        {showDateLabel && (
          <Text style={styles.dateLabel}>
            {moment(item.created_at).format("dddd, MMM D")}
          </Text>
        )}
        <View style={[styles.bubble, isMine ? styles.mine : styles.theirs]}>
          {!isMine && (
            <Text style={styles.author}>{item.author}</Text>
          )}
          <Text style={styles.message}>{item.message}</Text>
          <Text style={[styles.meta, item.sent === null && styles.failedMeta]}>
            {moment(item.created_at).format("h:mm A")} {statusIndicator}
          </Text>
        </View>
      </View>
    );
  };

  if (loading) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={styles.loadingText}>Loading thread...</Text>
        {displayBranchId && (
          <Text style={styles.loadingBranch}>Branch {displayBranchId}</Text>
        )}
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView
        style={styles.innerContainer}
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        keyboardVerticalOffset={Platform.OS === "ios" ? 0 : 0}
      >
        <View style={styles.header}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
            <Ionicons name="arrow-back" size={24} color="#007AFF" />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>
            Branch {displayBranchId || "..."} Chat
            {override_branch && currentBranchId && displayBranchId !== currentBranchId && 
              ` (Override from ${currentBranchId})`
            }
          </Text>
          <TouchableOpacity onPress={refreshMessages} style={styles.refreshBtn}>
            <Ionicons name="refresh" size={20} color="#007AFF" />
          </TouchableOpacity>
        </View>

        {messages.length === 0 && !loading ? (
          <View style={styles.emptyState}>
            <Ionicons name="chatbubbles-outline" size={64} color="#ccc" />
            <Text style={styles.emptyText}>No messages yet</Text>
            <Text style={styles.emptySubtext}>Be the first to start the conversation!</Text>
          </View>
        ) : (
          <FlatList
            ref={flatListRef}
            data={messages}
            keyExtractor={(item) => item.id.toString()}
            renderItem={renderItem}
            contentContainerStyle={styles.listContentContainer}
            onContentSizeChange={() => flatListRef.current?.scrollToEnd({ animated: true })}
            onLayout={() => flatListRef.current?.scrollToEnd({ animated: false })}
            showsVerticalScrollIndicator={false}
          />
        )}

        <View style={styles.inputContainer}>
          <View style={styles.inputRow}>
            <TextInput
              style={styles.input}
              placeholder="Type a message..."
              value={messageInput}
              onChangeText={setMessageInput}
              multiline
              maxLength={1000}
              editable={!sending}
            />
            <TouchableOpacity
              onPress={postMessage}
              style={[
                styles.sendBtn,
                { 
                  opacity: (messageInput.trim().length > 0 && !sending) ? 1 : 0.5,
                  backgroundColor: sending ? "#999" : "#007AFF"
                },
              ]}
              disabled={messageInput.trim().length === 0 || sending}
            >
              {sending ? (
                <ActivityIndicator size="small" color="white" />
              ) : (
                <Ionicons name="send" size={20} color="white" />
              )}
            </TouchableOpacity>
          </View>
          {displayBranchId && (
            <Text style={styles.branchIndicator}>
              Chatting in Branch {displayBranchId}
              {override_branch ? " (Override Mode)" : ""}
            </Text>
          )}
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#E5DDD5" },
  innerContainer: { flex: 1 },
  loading: { 
    flex: 1, 
    justifyContent: "center", 
    alignItems: "center",
    backgroundColor: "#E5DDD5" 
  },
  loadingText: {
    marginTop: 10,
    fontSize: 16,
    color: "#667781"
  },
  loadingBranch: {
    marginTop: 5,
    fontSize: 14,
    color: "#007AFF",
    fontWeight: "600"
  },
  emptyState: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: 20,
  },
  emptyText: {
    fontSize: 18,
    color: "#667781",
    marginTop: 16,
    fontWeight: "600"
  },
  emptySubtext: {
    fontSize: 14,
    color: "#999",
    marginTop: 8,
    textAlign: "center"
  },
  listContentContainer: { 
    paddingTop: 10, 
    paddingBottom: 10, 
    flexGrow: 1 
  },
  bubble: {
    maxWidth: "75%",
    paddingVertical: 8,
    paddingHorizontal: 12,
    marginVertical: 2,
    borderRadius: 18,
    marginHorizontal: 12,
  },
  mine: {
    backgroundColor: "#DCF8C6",
    alignSelf: "flex-end",
    borderBottomRightRadius: 4,
  },
  theirs: {
    backgroundColor: "#FFFFFF",
    alignSelf: "flex-start",
    borderBottomLeftRadius: 4,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 1,
    elevation: 1,
  },
  author: {
    fontSize: 12,
    fontWeight: "600",
    color: "#007AFF",
    marginBottom: 2,
  },
  message: { 
    fontSize: 16, 
    lineHeight: 21,
    color: "#000"
  },
  meta: {
    fontSize: 11,
    color: "#667781",
    alignSelf: "flex-end",
    marginTop: 4,
    marginLeft: 8,
  },
  failedMeta: {
    color: "#FF3B30",
  },
  dateLabel: {
    textAlign: "center",
    color: "#667781",
    fontSize: 12,
    marginVertical: 12,
    backgroundColor: "rgba(0,0,0,0.05)",
    alignSelf: "center",
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 12,
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 16,
    paddingTop: Platform.OS === "ios" ? 10 : 16,
    paddingBottom: 12,
    backgroundColor: "#E5DDD5",
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: "#ccc",
  },
  backBtn: {
    marginRight: 12,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: "600",
    color: "#333",
    flex: 1,
  },
  refreshBtn: {
    padding: 4,
  },
  inputContainer: {
    backgroundColor: "#F0F0F0",
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: "#D1D1D1",
    paddingVertical: 8,
    paddingHorizontal: 12,
  },
  inputRow: { 
    flexDirection: "row", 
    alignItems: "flex-end" 
  },
  input: {
    flex: 1,
    backgroundColor: "#FFFFFF",
    paddingHorizontal: 16,
    paddingTop: Platform.OS === "ios" ? 12 : 10,
    paddingBottom: Platform.OS === "ios" ? 12 : 10,
    borderRadius: 20,
    fontSize: 16,
    maxHeight: 100,
    minHeight: 44,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "#D1D1D1",
    marginRight: 12,
    textAlignVertical: "top",
  },
  sendBtn: {
    backgroundColor: "#007AFF",
    borderRadius: 22,
    width: 44,
    height: 44,
    justifyContent: "center",
    alignItems: "center",
    shadowColor: "#007AFF",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.3,
    shadowRadius: 2,
    elevation: 3,
  },
  branchIndicator: {
    fontSize: 12,
    color: "#667781",
    textAlign: "center",
    marginTop: 4,
    fontStyle: "italic"
  },
});