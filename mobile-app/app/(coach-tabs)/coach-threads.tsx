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
} from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { Ionicons } from "@expo/vector-icons";
import api from "../../utils/api";
import moment from "moment";
import { useRouter } from "expo-router";

export default function CoachThreadsScreenUpdated() {
  const [user, setUser] = useState<any>(null);
  const [messages, setMessages] = useState<any[]>([]);
  const [messageInput, setMessageInput] = useState("");
  const [loading, setLoading] = useState(true);
  const [threadId, setThreadId] = useState<number | null>(null);
  const flatListRef = useRef<FlatList>(null);
  const router = useRouter();

  const loadThread = async () => {
    setLoading(true);
    try {
      const stored = await AsyncStorage.getItem("authUser");
      const parsed = stored ? JSON.parse(stored) : null;
      setUser(parsed);
      console.log("🧑‍🏫 Authenticated coach:", parsed);
      const me = await api.get("/users/me");
      const branchId = me.data.branch_id;

      const threads = await api.get(`/threads/branch/${branchId}`);
      if (threads.data.length > 0) {
        const currentThreadId = threads.data[0].id;
        setThreadId(currentThreadId);
        const posts = await api.get(`/threads/${currentThreadId}/posts`);
        const sortedMessages = posts.data.sort((a: any, b: any) =>
          new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
        );
        setMessages(sortedMessages);
      } else {
        setMessages([]);
      }
    } catch (e) {
      console.error("Thread loading failed", e);
    } finally {
      setLoading(false);
      setTimeout(() => flatListRef.current?.scrollToEnd({ animated: false }), 100);
    }
  };

  const postMessage = async () => {
    if (!messageInput.trim() || !threadId || !user) return;

    const optimisticMessage = {
      id: Date.now(),
      user_id: user.id,
      message: messageInput,
      created_at: new Date().toISOString(),
      sent: false,
    };

    setMessages(prev => [...prev, optimisticMessage]);
    setMessageInput("");
    flatListRef.current?.scrollToEnd({ animated: true });

    try {
      const res = await api.post(`/threads/${threadId}/post`, { message: optimisticMessage.message });
      console.log("✅ Message posted", res.data);
      setMessages(prev =>
        prev.map(msg =>
          msg.id === optimisticMessage.id ? { ...msg, sent: true } : msg
        )
      );
    } catch (e: any) {
      console.error("❌ Message failed to send", e.response?.data || e.message);
      setMessages(prev =>
        prev.map(msg =>
          msg.id === optimisticMessage.id ? { ...msg, sent: null } : msg
        )
      );
    }
  };

  useEffect(() => {
    loadThread();
  }, []);

  const renderItem = ({ item, index }: { item: any; index: number }) => {
    if (!user) return null;

    const isMine = item.user_id === user.id;
    const showDateLabel = index === 0 ||
      !moment(item.created_at).isSame(messages[index - 1]?.created_at, 'day');

    let statusIndicator = "";
    if (isMine) {
      statusIndicator = item.sent === true ? "✓✓" : item.sent === false ? "✓" : "!";
    }

    return (
      <View>
        {showDateLabel && (
          <Text style={styles.dateLabel}>{moment(item.created_at).format("dddd, MMM D")}</Text>
        )}
        <View style={[styles.bubble, isMine ? styles.mine : styles.theirs]}>
          <Text style={styles.message}>{item.message}</Text>
          <Text style={styles.meta}>
            {moment(item.created_at).format("h:mm A")} {statusIndicator}
          </Text>
        </View>
      </View>
    );
  };

  if (loading) {
    return <View style={styles.loading}><ActivityIndicator size="large" color="#007AFF" /></View>;
  }

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView
        style={styles.innerContainer}
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        keyboardVerticalOffset={Platform.OS === "ios" ? 0 : 0}
      >
        <View style={styles.header}>
          <TouchableOpacity onPress={() => router.back()}>
            <Ionicons name="arrow-back" size={24} color="#007AFF" />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Branch Group</Text>
        </View>

        <FlatList
          ref={flatListRef}
          data={messages}
          keyExtractor={(item) => item.id.toString()}
          renderItem={renderItem}
          contentContainerStyle={styles.listContentContainer}
          onContentSizeChange={() => flatListRef.current?.scrollToEnd({ animated: true })}
          onLayout={() => flatListRef.current?.scrollToEnd({ animated: false })}
        />

        <View style={styles.inputContainer}>
          <View style={styles.inputRow}>
            <TextInput
              style={styles.input}
              placeholder="Type a message..."
              value={messageInput}
              onChangeText={setMessageInput}
              multiline
            />
            <TouchableOpacity
              onPress={postMessage}
              style={[styles.sendBtn, { opacity: messageInput.trim().length > 0 ? 1 : 0.5 }]}
              disabled={messageInput.trim().length === 0}
            >
              <Ionicons name="send" size={20} color="white" />
            </TouchableOpacity>
          </View>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#E5DDD5" },
  innerContainer: { flex: 1 },
  loading: { flex: 1, justifyContent: "center", alignItems: "center" },
  flatList: { flex: 1 },
  listContentContainer: { paddingTop: 10, paddingBottom: 10, flexGrow: 1 },
  bubble: {
    maxWidth: "75%",
    paddingVertical: 8,
    paddingHorizontal: 12,
    marginVertical: 4,
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
  message: { fontSize: 16, lineHeight: 21 },
  meta: { fontSize: 11, color: "#667781", alignSelf: "flex-end", marginTop: 4, marginLeft: 8 },
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
    paddingTop: Platform.OS === "ios" ? 50 : 16,
    paddingBottom: 12,
    backgroundColor: "#E5DDD5",
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: "#ccc",
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: "600",
    marginLeft: 12,
    color: "#333",
  },
  inputContainer: {
    backgroundColor: "#F0F0F0",
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: "#D1D1D1",
    paddingVertical: 6,
    paddingHorizontal: 8,
  },
  inputRow: { flexDirection: "row", alignItems: "flex-end" },
  input: {
    flex: 1,
    backgroundColor: "#FFFFFF",
    paddingHorizontal: 16,
    paddingTop: Platform.OS === 'ios' ? 10 : 8,
    paddingBottom: Platform.OS === 'ios' ? 10 : 8,
    borderRadius: 20,
    fontSize: 16,
    maxHeight: 100,
    minHeight: 40,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "#D1D1D1",
    marginRight: 8,
  },
  sendBtn: {
    backgroundColor: "#007AFF",
    borderRadius: 20,
    width: 40,
    height: 40,
    justifyContent: "center",
    alignItems: "center",
    shadowColor: "#007AFF",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.3,
    shadowRadius: 2,
    elevation: 3,
  },
});