import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

// WhatsApp-style colors
class _WA {
  static const bg = Color(0xFFECE5DD);
  static const headerBg = Color(0xFF075E54);
  static const headerLight = Color(0xFF128C7E);
  static const myBubble = Color(0xFFDCF8C6);
  static const otherBubble = Colors.white;
  static const inputBg = Colors.white;
  static const sendBtn = Color(0xFF00A884);
  static const dateChip = Color(0xFFE1F2FB);
  static const dateText = Color(0xFF54656F);
  static const timeText = Color(0xFF667781);
  static const nameColors = [Color(0xFF00A884), Color(0xFF53BDEB), Color(0xFFFF6B6B), Color(0xFF7C4DFF), Color(0xFFFF9800), Color(0xFFE91E63)];
}

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

  void silentRefresh() { if (threadId != null) _loadMessages(); }

  @override
  void initState() { super.initState(); _loadThread(); }

  Color _colorForAuthor(String name) {
    return _authorColors.putIfAbsent(name, () => _WA.nameColors[_authorColors.length % _WA.nameColors.length]);
  }

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
    final text = _msgCtrl.text.trim();

    // Optimistic update
    final optimistic = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': user?['id'],
      'message': text,
      'author': user?['name'] ?? 'You',
      'created_at': DateTime.now().toIso8601String(),
      '_sending': true,
    };
    setState(() { messages.add(optimistic); sending = true; });
    _msgCtrl.clear();
    _scrollToBottom();

    try {
      await ApiService().post('/threads/$threadId/post', data: {'message': text});
      await _loadMessages();
    } catch (_) {
      // Remove optimistic message on failure
      setState(() { messages.removeWhere((m) => m['id'] == optimistic['id']); });
    } finally { if (mounted) setState(() => sending = false); }
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    if (diff < 7) return DateFormat('EEEE').format(date).toUpperCase();
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Scaffold(backgroundColor: _WA.bg, body: const Center(child: CircularProgressIndicator(color: _WA.headerBg)));

    return Scaffold(
      body: Column(
        children: [
          // ─── WhatsApp Header ─────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).padding.top, 0, 0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_WA.headerBg, _WA.headerLight]),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 12),
              child: Row(
                children: [
                  // Back button
                  const SizedBox(width: 4),
                  // Group avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white24,
                    child: Text(branchName.isNotEmpty ? branchName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(branchName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                        Text('${messages.length} messages', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 22), onPressed: _loadMessages),
                ],
              ),
            ),
          ),

          // ─── Chat Area ───────────────────────────────────
          Expanded(
            child: Container(
              // WhatsApp doodle background
              decoration: const BoxDecoration(
                color: _WA.bg,
                image: DecorationImage(
                  image: AssetImage('assets/images/hfanew.png'),
                  opacity: 0.03,
                  repeat: ImageRepeat.repeat,
                ),
              ),
              child: messages.isEmpty
                  ? Center(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(color: _WA.dateChip, borderRadius: BorderRadius.circular(8)),
                      child: const Text('No messages yet. Say hello!', style: TextStyle(fontSize: 14, color: _WA.dateText)),
                    ))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      itemCount: messages.length,
                      itemBuilder: (_, i) => _buildMessage(i),
                    ),
            ),
          ),

          // ─── Input Bar ───────────────────────────────────
          Container(
            color: _WA.bg,
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Message field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: _WA.inputBg, borderRadius: BorderRadius.circular(24)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _msgCtrl,
                              maxLines: 6,
                              minLines: 1,
                              maxLength: 1000,
                              enabled: !sending,
                              style: const TextStyle(fontSize: 16),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Message',
                                hintStyle: TextStyle(color: _WA.timeText, fontSize: 16),
                                counterText: '',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                                fillColor: Colors.transparent,
                                filled: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Send button
                  GestureDetector(
                    onTap: _msgCtrl.text.trim().isNotEmpty && !sending ? _postMessage : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: sending ? _WA.timeText : _WA.sendBtn,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: sending
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(int i) {
    final msg = messages[i];
    final isMine = msg['user_id'] == user?['id'];
    final isSending = msg['_sending'] == true;
    final showDate = i == 0 || !_sameDay(msg['created_at'], messages[i - 1]['created_at']);
    final showAuthor = !isMine && (i == 0 || messages[i - 1]['user_id'] != msg['user_id'] || showDate);
    final isLastInGroup = i == messages.length - 1 || messages[i + 1]['user_id'] != msg['user_id'] || (i < messages.length - 1 && !_sameDay(msg['created_at'], messages[i + 1]['created_at']));

    final authorColor = _colorForAuthor(msg['author'] ?? '');
    final time = DateFormat('h:mm a').format(DateTime.parse(msg['created_at']));

    return Column(
      children: [
        // Date chip
        if (showDate)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _WA.dateChip, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 2)]),
              child: Text(_formatDateLabel(DateTime.parse(msg['created_at'])), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _WA.dateText, letterSpacing: 0.3)),
            ),
          ),

        // Message bubble
        Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isSending ? 0.6 : 1.0,
            child: Container(
              margin: EdgeInsets.only(
                left: isMine ? 60 : 4,
                right: isMine ? 4 : 60,
                top: showAuthor ? 8 : 1,
                bottom: 1,
              ),
              child: CustomPaint(
                painter: isLastInGroup ? _BubbleTailPainter(isMine: isMine, color: isMine ? _WA.myBubble : _WA.otherBubble) : null,
                child: Container(
                  padding: EdgeInsets.fromLTRB(10, showAuthor && !isMine ? 6 : 8, 10, 8),
                  margin: EdgeInsets.only(left: !isMine && isLastInGroup ? 8 : 0, right: isMine && isLastInGroup ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isMine ? _WA.myBubble : _WA.otherBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(!isMine && isLastInGroup ? 0 : 8),
                      topRight: Radius.circular(isMine && isLastInGroup ? 0 : 8),
                      bottomLeft: const Radius.circular(8),
                      bottomRight: const Radius.circular(8),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 1, offset: const Offset(0, 1))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author name
                      if (showAuthor && !isMine)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(msg['author'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: authorColor)),
                        ),
                      // Message + time in a wrap
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(child: Text(msg['message'] ?? '', style: const TextStyle(fontSize: 15.5, height: 1.3, color: Color(0xFF111B21)))),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(time, style: const TextStyle(fontSize: 11, color: _WA.timeText)),
                                if (isMine) ...[
                                  const SizedBox(width: 3),
                                  Icon(isSending ? Icons.access_time : Icons.done_all, size: 16, color: isSending ? _WA.timeText : const Color(0xFF53BDEB)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _sameDay(String a, String b) { final da = DateTime.parse(a); final db = DateTime.parse(b); return da.year == db.year && da.month == db.month && da.day == db.day; }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }
}

// WhatsApp-style bubble tail
class _BubbleTailPainter extends CustomPainter {
  final bool isMine;
  final Color color;
  _BubbleTailPainter({required this.isMine, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();

    if (isMine) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width + 8, 0);
      path.lineTo(size.width, 10);
    } else {
      path.moveTo(0, 0);
      path.lineTo(-8, 0);
      path.lineTo(0, 10);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
