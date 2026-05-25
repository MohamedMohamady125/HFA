import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CoachThreadsScreen extends StatefulWidget {
  const CoachThreadsScreen({super.key});
  @override
  State<CoachThreadsScreen> createState() => CoachThreadsScreenState();
}

class CoachThreadsScreenState extends State<CoachThreadsScreen> {
  Map<String, dynamic>? user;
  List<dynamic> messages = [];
  final _msgCtrl = TextEditingController();
  bool loading = true, sending = false;
  int? threadId, displayBranchId;
  String branchName = '';
  final _scrollCtrl = ScrollController();
  final Map<String, Color> _authorColors = {};
  static const _nameColors = [Color(0xFF00A8E8), Color(0xFF7C4DFF), Color(0xFFFF6B6B), Color(0xFFFF9800), Color(0xFFE91E63), Color(0xFF00BFA5)];

  void silentRefresh() { if (threadId != null) _loadMessages(); }

  @override
  void initState() { super.initState(); _loadThread(); }

  Color _colorFor(String name) => _authorColors.putIfAbsent(name, () => _nameColors[_authorColors.length % _nameColors.length]);

  Future<void> _loadThread() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      user = jsonDecode(prefs.getString('authUser')!);
      final api = ApiService();
      final me = await api.get('/users/me');
      displayBranchId = me.data['branch_id'];
      branchName = me.data['branch_name'] ?? 'Branch $displayBranchId';
      final tr = await api.get('/threads/branch/$displayBranchId');
      if (tr.data is List && (tr.data as List).isNotEmpty) {
        threadId = tr.data[0]['id'];
        await _loadMessages();
      }
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _loadMessages() async {
    if (threadId == null) return;
    try {
      final res = await ApiService().get('/threads/$threadId/posts');
      final data = res.data as List;
      data.sort((a, b) => DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
      messages = data;
      _scrollToBottom();
    } catch (_) { messages = []; }
    if (mounted) setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  Future<void> _postMessage() async {
    if (_msgCtrl.text.trim().isEmpty || threadId == null || sending) return;
    HapticFeedback.mediumImpact();
    final text = _msgCtrl.text.trim();
    final optimistic = {'id': 'temp_${DateTime.now().millisecondsSinceEpoch}', 'user_id': user?['id'], 'message': text, 'author': user?['name'] ?? 'You', 'created_at': DateTime.now().toIso8601String(), '_sending': true};
    setState(() { messages.add(optimistic); sending = true; });
    _msgCtrl.clear();
    _scrollToBottom();
    try {
      await ApiService().post('/threads/$threadId/post', data: {'message': text});
      await _loadMessages();
    } catch (_) { setState(() { messages.removeWhere((m) => m['id'] == optimistic['id']); }); }
    finally { if (mounted) setState(() => sending = false); }
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(d);
    return DateFormat('MMM d, yyyy').format(d);
  }

  bool _sameDay(String a, String b) {
    final da = DateTime.tryParse(a); final db = DateTime.tryParse(b);
    if (da == null || db == null) return false;
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: ShimmerList(count: 6));

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 8, 12),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Row(children: [
              GradientAvatar(name: branchName, size: 40),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(branchName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                Text('${messages.length} messages', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
              ])),
              IconButton(icon: Icon(Icons.refresh_rounded, color: Colors.white.withValues(alpha: 0.7), size: 22), onPressed: _loadMessages),
            ]),
          ),

          // Messages
          Expanded(
            child: Container(
              color: AppColors.scaffoldBg,
              child: messages.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.textTertiary.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      const Text('No messages yet', style: TextStyle(color: AppColors.textSecondary)),
                    ]))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      itemCount: messages.length,
                      itemBuilder: (_, i) => _buildMsg(i),
                    ),
            ),
          ),

          // Input
          Container(
            color: AppColors.cardBg,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: SafeArea(
              top: false,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(24)),
                    child: TextField(
                      controller: _msgCtrl, maxLines: 5, minLines: 1, maxLength: 1000, enabled: !sending,
                      style: const TextStyle(fontSize: 16),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: 'Message', hintStyle: TextStyle(color: AppColors.textTertiary), counterText: '', border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), fillColor: Colors.transparent, filled: true),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _msgCtrl.text.trim().isNotEmpty && !sending ? _postMessage : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: sending ? AppColors.textTertiary : AppColors.accent, shape: BoxShape.circle),
                    child: Center(child: sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 22)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMsg(int i) {
    final msg = Map<String, dynamic>.from(messages[i]);
    final createdAt = msg['created_at']?.toString() ?? DateTime.now().toIso8601String();
    final author = msg['author']?.toString() ?? 'Unknown';
    final message = msg['message']?.toString() ?? '';
    final isMine = msg['user_id'] == user?['id'];
    final isSending = msg['_sending'] == true;
    final showDate = i == 0 || !_sameDay(createdAt, messages[i - 1]['created_at']?.toString() ?? '');
    final showAuthor = !isMine && (i == 0 || messages[i - 1]['user_id'] != msg['user_id'] || showDate);
    final isLast = i == messages.length - 1 || messages[i + 1]['user_id'] != msg['user_id'] || (i < messages.length - 1 && !_sameDay(createdAt, messages[i + 1]['created_at']?.toString() ?? ''));
    final time = DateFormat('h:mm a').format(DateTime.tryParse(createdAt) ?? DateTime.now());

    return Column(children: [
      if (showDate) Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(8)),
          child: Text(_dateLabel(DateTime.tryParse(createdAt) ?? DateTime.now()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ),
      ),
      Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isSending ? 0.6 : 1.0,
          child: Container(
            margin: EdgeInsets.only(left: isMine ? 50 : 4, right: isMine ? 4 : 50, top: showAuthor ? 6 : 1, bottom: 1),
            padding: EdgeInsets.fromLTRB(12, showAuthor && !isMine ? 6 : 8, 12, 7),
            decoration: BoxDecoration(
              color: isMine ? AppColors.accentLight : AppColors.cardBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(!isMine && isLast ? 2 : 12),
                topRight: Radius.circular(isMine && isLast ? 2 : 12),
                bottomLeft: const Radius.circular(12),
                bottomRight: const Radius.circular(12),
              ),
              border: null,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 2, offset: const Offset(0, 1))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (showAuthor && !isMine)
                Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(author, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _colorFor(author)))),
              Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Flexible(child: Text(message, style: const TextStyle(fontSize: 15, height: 1.35, color: AppColors.textPrimary))),
                const SizedBox(width: 8),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(time, style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary)),
                  if (isMine) ...[
                    const SizedBox(width: 3),
                    Icon(isSending ? Icons.access_time : Icons.done_all, size: 15, color: isSending ? AppColors.textTertiary : AppColors.accent),
                  ],
                ]),
              ]),
            ]),
          ),
        ),
      ),
    ]);
  }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }
}
