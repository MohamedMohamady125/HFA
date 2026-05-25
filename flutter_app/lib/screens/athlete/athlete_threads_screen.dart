import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class _WA {
  static const bg = Color(0xFFECE5DD);
  static const headerBg = Color(0xFF075E54);
  static const headerLight = Color(0xFF128C7E);
  static const myBubble = Color(0xFFDCF8C6);
  static const otherBubble = Colors.white;
  static const dateChip = Color(0xFFE1F2FB);
  static const dateText = Color(0xFF54656F);
  static const timeText = Color(0xFF667781);
  static const nameColors = [Color(0xFF00A884), Color(0xFF53BDEB), Color(0xFFFF6B6B), Color(0xFF7C4DFF), Color(0xFFFF9800), Color(0xFFE91E63)];
}

class AthleteThreadsScreen extends StatefulWidget {
  const AthleteThreadsScreen({super.key});
  @override
  State<AthleteThreadsScreen> createState() => AthleteThreadsScreenState();
}

class AthleteThreadsScreenState extends State<AthleteThreadsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<dynamic> threads = [], posts = [];
  Map<String, dynamic>? selectedThread;
  Map<String, dynamic>? user;
  bool loading = true, postsLoading = false;
  String branchName = '';
  bool _fetched = false;
  final _scrollCtrl = ScrollController();
  final Map<String, Color> _authorColors = {};

  void silentRefresh() { if (_fetched && selectedThread != null) _selectThread(selectedThread!); }

  @override
  void initState() { super.initState(); _fetchData(); }

  Color _colorForAuthor(String name) => _authorColors.putIfAbsent(name, () => _WA.nameColors[_authorColors.length % _WA.nameColors.length]);

  Future<void> _fetchData() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      user = jsonDecode(prefs.getString('authUser')!);
      final api = ApiService();
      final me = await api.get('/users/me');
      final branchId = me.data['branch_id'];
      final results = await Future.wait([api.get('/branches/$branchId'), api.get('/threads/branch/$branchId')]);
      branchName = results[0].data['name'] ?? '';
      threads = (results[1].data as List).where((t) {
        final title = (t['title'] as String).toLowerCase();
        return !title.contains('gear') && !title.contains('equipment');
      }).toList();
      if (threads.isNotEmpty) await _selectThread(threads[0]);
      _fetched = true;
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _selectThread(dynamic thread) async {
    setState(() { postsLoading = true; selectedThread = Map<String, dynamic>.from(thread); });
    try {
      final r = await ApiService().get('/threads/${thread['id']}/posts');
      posts = r.data;
      posts.sort((a, b) => DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      });
    } catch (_) {} finally { if (mounted) setState(() => postsLoading = false); }
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
    super.build(context);
    if (loading) return Scaffold(backgroundColor: _WA.bg, body: const Center(child: CircularProgressIndicator(color: _WA.headerBg)));

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).padding.top, 0, 0),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [_WA.headerBg, _WA.headerLight])),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(children: [
                    CircleAvatar(radius: 20, backgroundColor: Colors.white24,
                      child: Text(branchName.isNotEmpty ? branchName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(branchName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                      Text('${posts.length} messages', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    ])),
                  ]),
                ),
                // Thread chips
                if (threads.length > 1)
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: threads.map((t) {
                        final active = selectedThread?['id'] == t['id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _selectThread(t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(color: active ? Colors.white24 : Colors.white10, borderRadius: BorderRadius.circular(18)),
                              child: Center(child: Text(t['title'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.white70))),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                if (threads.length > 1) const SizedBox(height: 8),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: Container(
              color: _WA.bg,
              child: postsLoading
                  ? const Center(child: CircularProgressIndicator(color: _WA.headerBg))
                  : posts.isEmpty
                      ? Center(child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(color: _WA.dateChip, borderRadius: BorderRadius.circular(8)),
                          child: const Text('No messages yet', style: TextStyle(fontSize: 14, color: _WA.dateText)),
                        ))
                      : ListView.builder(
                          controller: _scrollCtrl,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          itemCount: posts.length,
                          itemBuilder: (_, i) => _buildMessage(i),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(int i) {
    final msg = posts[i];
    final isMine = msg['user_id'] == user?['id'];
    final showDate = i == 0 || !_sameDay(msg['created_at'], posts[i - 1]['created_at']);
    final showAuthor = !isMine && (i == 0 || posts[i - 1]['user_id'] != msg['user_id'] || showDate);
    final isLastInGroup = i == posts.length - 1 || posts[i + 1]['user_id'] != msg['user_id'] || (i < posts.length - 1 && !_sameDay(msg['created_at'], posts[i + 1]['created_at']));

    final authorColor = _colorForAuthor(msg['author'] ?? '');
    final time = DateFormat('h:mm a').format(DateTime.parse(msg['created_at']));

    return Column(children: [
      if (showDate) Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: _WA.dateChip, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 2)]),
          child: Text(_formatDateLabel(DateTime.parse(msg['created_at'])), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _WA.dateText, letterSpacing: 0.3)),
        ),
      ),
      Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(left: isMine ? 60 : 4, right: isMine ? 4 : 60, top: showAuthor ? 8 : 1, bottom: 1),
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (showAuthor && !isMine) Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(msg['author'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: authorColor))),
                Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Flexible(child: Text(msg['message'] ?? '', style: const TextStyle(fontSize: 15.5, height: 1.3, color: Color(0xFF111B21)))),
                  const SizedBox(width: 8),
                  Text(time, style: const TextStyle(fontSize: 11, color: _WA.timeText)),
                ]),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  bool _sameDay(String a, String b) { final da = DateTime.parse(a); final db = DateTime.parse(b); return da.year == db.year && da.month == db.month && da.day == db.day; }

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }
}

class _BubbleTailPainter extends CustomPainter {
  final bool isMine;
  final Color color;
  _BubbleTailPainter({required this.isMine, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    if (isMine) { path.moveTo(size.width, 0); path.lineTo(size.width + 8, 0); path.lineTo(size.width, 10); }
    else { path.moveTo(0, 0); path.lineTo(-8, 0); path.lineTo(0, 10); }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
