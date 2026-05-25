import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class AthleteThreadsScreen extends StatefulWidget {
  const AthleteThreadsScreen({super.key});
  @override
  State<AthleteThreadsScreen> createState() => AthleteThreadsScreenState();
}

class AthleteThreadsScreenState extends State<AthleteThreadsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<dynamic> threads = [], posts = [];
  Map<String, dynamic>? selectedThread, user;
  bool loading = true, postsLoading = false, _fetched = false;
  String branchName = '';
  final _scrollCtrl = ScrollController();
  final Map<String, Color> _authorColors = {};
  static const _nameColors = [Color(0xFF00A8E8), Color(0xFF7C4DFF), Color(0xFFFF6B6B), Color(0xFFFF9800), Color(0xFFE91E63), Color(0xFF00BFA5)];

  void silentRefresh() { if (_fetched && selectedThread != null) _selectThread(selectedThread!); }

  @override
  void initState() { super.initState(); _fetchData(); }

  Color _colorFor(String name) => _authorColors.putIfAbsent(name, () => _nameColors[_authorColors.length % _nameColors.length]);

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
      WidgetsBinding.instance.addPostFrameCallback((_) { if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent); });
    } catch (_) {} finally { if (mounted) setState(() => postsLoading = false); }
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(d);
    return DateFormat('MMM d, yyyy').format(d);
  }

  bool _sameDay(String a, String b) { final da = DateTime.parse(a); final db = DateTime.parse(b); return da.year == db.year && da.month == db.month && da.day == db.day; }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (loading) return const Scaffold(body: ShimmerList(count: 6));

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 8, 0),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(children: [
              Row(children: [
                CircleAvatar(radius: 20, backgroundColor: Colors.white12,
                  child: Text(branchName.isNotEmpty ? branchName[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(branchName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                  Text('${posts.length} messages', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                ])),
              ]),
              if (threads.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(height: 34, child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: threads.map((t) {
                      final active = selectedThread?['id'] == t['id'];
                      return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                        onTap: () => _selectThread(t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: active ? Colors.white24 : Colors.white10, borderRadius: BorderRadius.circular(18)),
                          child: Center(child: Text(t['title'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.white70))),
                        ),
                      ));
                    }).toList(),
                  )),
                ),
              const SizedBox(height: 10),
            ]),
          ),

          // Messages
          Expanded(
            child: Container(
              color: AppColors.scaffoldBg,
              child: postsLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : posts.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.textTertiary.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text('No messages yet', style: TextStyle(color: AppColors.textSecondary)),
                        ]))
                      : ListView.builder(
                          controller: _scrollCtrl,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                          itemCount: posts.length,
                          itemBuilder: (_, i) => _buildMsg(i),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMsg(int i) {
    final msg = posts[i];
    final isMine = msg['user_id'] == user?['id'];
    final showDate = i == 0 || !_sameDay(msg['created_at'], posts[i - 1]['created_at']);
    final showAuthor = !isMine && (i == 0 || posts[i - 1]['user_id'] != msg['user_id'] || showDate);
    final isLast = i == posts.length - 1 || posts[i + 1]['user_id'] != msg['user_id'] || (i < posts.length - 1 && !_sameDay(msg['created_at'], posts[i + 1]['created_at']));
    final time = DateFormat('h:mm a').format(DateTime.parse(msg['created_at']));

    return Column(children: [
      if (showDate) Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(8)),
          child: Text(_dateLabel(DateTime.parse(msg['created_at'])), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ),
      ),
      Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
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
            border: isMine ? null : Border.all(color: AppColors.divider),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 2, offset: const Offset(0, 1))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (showAuthor && !isMine)
              Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(msg['author'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _colorFor(msg['author'] ?? '')))),
            Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Flexible(child: Text(msg['message'] ?? '', style: const TextStyle(fontSize: 15, height: 1.35, color: AppColors.textPrimary))),
              const SizedBox(width: 8),
              Text(time, style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary)),
            ]),
          ]),
        ),
      ),
    ]);
  }

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }
}
