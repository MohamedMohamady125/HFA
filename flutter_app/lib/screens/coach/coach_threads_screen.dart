import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CoachThreadsScreen extends StatefulWidget {
  const CoachThreadsScreen({super.key});
  @override
  State<CoachThreadsScreen> createState() => _CoachThreadsScreenState();
}

class _CoachThreadsScreenState extends State<CoachThreadsScreen> {
  Map<String, dynamic>? user;
  List<dynamic> messages = [];
  final _messageController = TextEditingController();
  bool loading = true;
  bool sending = false;
  int? threadId;
  int? displayBranchId;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  Future<void> _loadThread() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored == null) return;
      user = jsonDecode(stored);

      final api = ApiService();
      final meRes = await api.get('/users/me');
      final branchId = meRes.data['branch_id'];
      displayBranchId = branchId;

      final threadsRes = await api.get('/threads/branch/$branchId');
      if (threadsRes.data is List && (threadsRes.data as List).isNotEmpty) {
        threadId = threadsRes.data[0]['id'];
        await _loadMessages();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load thread: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (threadId == null) return;
    try {
      final res = await ApiService().get('/threads/$threadId/posts');
      final data = res.data as List;
      data.sort((a, b) => DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
      messages = data;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    } catch (_) {
      messages = [];
    }
    if (mounted) setState(() {});
  }

  Future<void> _postMessage() async {
    if (_messageController.text.trim().isEmpty || threadId == null || sending) return;
    setState(() => sending = true);
    final text = _messageController.text.trim();
    _messageController.clear();

    try {
      await ApiService().post('/threads/$threadId/post', data: {'message': text});
      await _loadMessages();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send message'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE5DDD5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF007AFF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFCCCCCC), width: 0.5))),
              child: Row(
                children: [
                  Text('Branch ${displayBranchId ?? '...'} Chat', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF007AFF), size: 20), onPressed: _loadMessages),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('No messages yet', style: TextStyle(fontSize: 18, color: Color(0xFF667781), fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text('Be the first to start the conversation!', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
                      ]))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final msg = messages[i];
                        final isMine = msg['user_id'] == user?['id'];
                        final showDate = i == 0 || !_sameDay(msg['created_at'], messages[i - 1]['created_at']);

                        return Column(
                          children: [
                            if (showDate)
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                                child: Text(DateFormat('EEEE, MMM d').format(DateTime.parse(msg['created_at'])), style: const TextStyle(fontSize: 12, color: Color(0xFF667781))),
                              ),
                            Align(
                              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                decoration: BoxDecoration(
                                  color: isMine ? const Color(0xFFDCF8C6) : Colors.white,
                                  borderRadius: BorderRadius.circular(18).copyWith(
                                    bottomRight: isMine ? const Radius.circular(4) : null,
                                    bottomLeft: !isMine ? const Radius.circular(4) : null,
                                  ),
                                  boxShadow: isMine ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 1, offset: const Offset(0, 1))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMine) Text(msg['author'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF007AFF))),
                                    Text(msg['message'] ?? '', style: const TextStyle(fontSize: 16, height: 1.31)),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(DateFormat('h:mm a').format(DateTime.parse(msg['created_at'])), style: const TextStyle(fontSize: 11, color: Color(0xFF667781))),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),

            // Input
            Container(
              color: const Color(0xFFF0F0F0),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          maxLength: 1000,
                          enabled: !sending,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            counterText: '',
                            filled: true, fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey[300]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey[300]!)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: sending ? const Color(0xFF999999) : const Color(0xFF007AFF),
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _messageController.text.trim().isNotEmpty && !sending ? _postMessage : null,
                          child: SizedBox(
                            width: 44, height: 44,
                            child: Center(child: sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send, color: Colors.white, size: 20)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (displayBranchId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Chatting in Branch $displayBranchId', style: const TextStyle(fontSize: 12, color: Color(0xFF667781), fontStyle: FontStyle.italic)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(String a, String b) {
    final da = DateTime.parse(a);
    final db = DateTime.parse(b);
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
