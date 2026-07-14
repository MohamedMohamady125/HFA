import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/offline/offline_repository.dart';
import '../../services/offline/connectivity_service.dart';
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

  List<dynamic> _filterThreads(dynamic data) {
    if (data is! List) return [];
    return data.where((t) {
      final title = (t['title'] as String? ?? '').toLowerCase();
      return !title.contains('gear') && !title.contains('equipment');
    }).toList();
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      user = jsonDecode(prefs.getString('authUser')!);
      final branchId = user!['branch_id'] ?? (OfflineRepository.getCached('/users/me') as Map?)?['branch_id'];

      // Instant cache reads — render immediately when possible
      if (branchId != null) {
        final cachedBranch = OfflineRepository.getCached('/branches/$branchId');
        if (cachedBranch is Map) branchName = cachedBranch['name']?.toString() ?? '';
        final cachedThreads = _filterThreads(OfflineRepository.getCached('/threads/branch/$branchId'));
        if (cachedThreads.isNotEmpty) {
          threads = cachedThreads;
          if (mounted) setState(() => loading = false);
        }
      }

      // Cache-first fetch with background refresh
      final effectiveBranchId = branchId ?? (await OfflineRepository.getUserMe())['branch_id'];
      if (effectiveBranchId == null) return;
      final results = await Future.wait([
        OfflineRepository.getBranch(effectiveBranchId, onFresh: (d) {
          if (mounted && d is Map) setState(() => branchName = d['name']?.toString() ?? branchName);
        }),
        OfflineRepository.getThreads(effectiveBranchId, onFresh: (d) {
          final fresh = _filterThreads(d);
          if (mounted && fresh.isNotEmpty) setState(() => threads = fresh);
        }),
      ]);
      branchName = (results[0] as Map)['name']?.toString() ?? branchName;
      threads = _filterThreads(results[1]);
      if (threads.isNotEmpty && selectedThread == null) await _selectThread(threads[0]);
      _fetched = true;
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  void _applyPosts(dynamic data) {
    if (data is! List) return;
    posts = List.of(data);
    posts.sort((a, b) => DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
    WidgetsBinding.instance.addPostFrameCallback((_) { if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent); });
  }

  Future<void> _selectThread(dynamic thread) async {
    final threadId = thread['id'];
    // Instant cache read — skip the shimmer when we already have posts
    final cached = OfflineRepository.getCached('/threads/$threadId/posts');
    setState(() {
      selectedThread = Map<String, dynamic>.from(thread);
      postsLoading = cached is! List;
      if (cached is List) _applyPosts(cached);
    });
    try {
      final data = await OfflineRepository.getPosts(threadId, onFresh: (fresh) {
        if (mounted && selectedThread?['id'] == threadId) setState(() => _applyPosts(fresh));
      });
      if (selectedThread?['id'] == threadId) _applyPosts(data);
    } catch (_) {} finally { if (mounted) setState(() => postsLoading = false); }
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    final l = AppLocalizations.of(context);
    if (diff == 0) return l.translate('today');
    if (diff == 1) return l.translate('yesterday');
    final locale = l.locale.languageCode;
    if (diff < 7) return DateFormat('EEEE', locale).format(d);
    return DateFormat('MMM d, yyyy', locale).format(d);
  }

  bool _sameDay(String a, String b) {
    final da = DateTime.tryParse(a); final db = DateTime.tryParse(b);
    if (da == null || db == null) return false;
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    if (loading) return const Scaffold(body: SafeArea(child: ShimmerList(count: 6)));

    return Scaffold(
      body: Column(
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16),
                child: Column(children: [
                  Row(children: [
                    GradientAvatar(name: branchName, size: 44),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(branchName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                      const SizedBox(height: 2),
                      Text('${posts.length} ${l.translate('messages')}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12.5, fontWeight: FontWeight.w500)),
                    ])),
                    const HeaderIconButton(icon: Icons.forum_rounded),
                  ]),
                  if (threads.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: SizedBox(height: 36, child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: threads.map((t) {
                          final active = selectedThread?['id'] == t['id'];
                          return Padding(padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm), child: GestureDetector(
                            onTap: () => _selectThread(t),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: active ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: active ? Colors.white.withValues(alpha: 0.4) : Colors.transparent, width: 1),
                              ),
                              child: Center(child: Text(t['title'], style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: active ? Colors.white : Colors.white70))),
                            ),
                          ));
                        }).toList(),
                      )),
                    ),
                ]),
              ),
            ),
          ),

          // Messages
          Expanded(
            child: Container(
              color: AppColors.scaffoldBg,
              child: postsLoading
                  ? const ShimmerList(count: 5)
                  : posts.isEmpty
                      ? (!ConnectivityService.isOnline
                          ? EmptyState(
                              icon: Icons.cloud_off_rounded,
                              title: l.translate('no_connection'),
                              message: l.translate('no_connection_data'),
                            )
                          : EmptyState(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: l.translate('no_messages'),
                            ))
                      : ListView.builder(
                          controller: _scrollCtrl,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
    final msg = Map<String, dynamic>.from(posts[i]);
    final createdAt = msg['created_at']?.toString() ?? DateTime.now().toIso8601String();
    final author = msg['author']?.toString() ?? AppLocalizations.of(context).translate('unknown_author');
    final message = msg['message']?.toString() ?? '';
    final isMine = msg['user_id'] == user?['id'];
    final showDate = i == 0 || !_sameDay(createdAt, posts[i - 1]['created_at']?.toString() ?? '');
    final showAuthor = !isMine && (i == 0 || posts[i - 1]['user_id'] != msg['user_id'] || showDate);
    final time = DateFormat('h:mm a', AppLocalizations.of(context).locale.languageCode).format(DateTime.tryParse(createdAt) ?? DateTime.now());

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      margin: EdgeInsetsDirectional.only(top: showAuthor ? 6 : 2, bottom: 2),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 9, 14, 8),
      decoration: BoxDecoration(
        gradient: isMine ? AppColors.accentGradient : null,
        color: isMine ? null : AppColors.cardBg,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(isMine ? AppRadius.lg : (showAuthor ? 4 : AppRadius.lg)),
          topEnd: Radius.circular(isMine ? 4 : AppRadius.lg),
          bottomStart: const Radius.circular(AppRadius.lg),
          bottomEnd: const Radius.circular(AppRadius.lg),
        ),
        border: isMine ? null : Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (showAuthor && !isMine)
          Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(author, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _colorFor(author)))),
        Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(child: Text(message, style: TextStyle(fontSize: 15, height: 1.35, color: isMine ? Colors.white : AppColors.textPrimary))),
          const SizedBox(width: AppSpacing.sm),
          Text(time, style: TextStyle(fontSize: 10.5, color: isMine ? Colors.white.withValues(alpha: 0.75) : AppColors.textTertiary)),
        ]),
      ]),
    );

    return Column(children: [
      if (showDate) Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Text(_dateLabel(DateTime.tryParse(createdAt) ?? DateTime.now()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
      ),
      Align(
        alignment: isMine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: isMine
            ? bubble
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showAuthor)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                      child: GradientAvatar(name: author, size: 30, colors: [_colorFor(author), AppColors.primary]),
                    )
                  else
                    const SizedBox(width: 38),
                  Flexible(child: bubble),
                ],
              ),
      ),
    ]);
  }

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }
}
