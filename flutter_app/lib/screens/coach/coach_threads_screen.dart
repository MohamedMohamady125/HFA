import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/offline/offline_repository.dart';
import '../../services/offline/connectivity_service.dart';
import '../../services/refresh_bus.dart';
import '../../widgets/app_feedback.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CoachThreadsScreen extends StatefulWidget {
  const CoachThreadsScreen({super.key});
  @override
  State<CoachThreadsScreen> createState() => CoachThreadsScreenState();
}

class CoachThreadsScreenState extends State<CoachThreadsScreen> with LiveRefreshMixin {
  Map<String, dynamic>? user;
  List<dynamic> messages = [];
  final _msgCtrl = TextEditingController();
  bool loading = true, sending = false;
  // Show the "saved offline" notice at most once per screen session.
  bool _queuedNoticeShown = false;
  int? threadId, displayBranchId;
  String branchName = '';
  final _scrollCtrl = ScrollController();
  final Map<String, Color> _authorColors = {};
  static const _nameColors = [Color(0xFF00A8E8), Color(0xFF7C4DFF), Color(0xFFFF6B6B), Color(0xFFFF9800), Color(0xFFE91E63), Color(0xFF00BFA5)];

  void silentRefresh() { if (threadId != null) _loadMessages(); }

  @override
  void onLiveRefresh() {
    if (threadId != null) {
      _loadMessages();
    } else {
      _loadThread();
    }
  }

  @override
  void initState() {
    super.initState();
    // Sync cache read
    final prefs = SharedPreferences.getInstance();
    prefs.then((p) {
      final stored = p.getString('authUser');
      if (stored != null) user = jsonDecode(stored);
    });
    final cachedMe = OfflineRepository.getCached('/users/me');
    if (cachedMe is Map) {
      displayBranchId = cachedMe['branch_id'];
      branchName = cachedMe['branch_name']?.toString() ?? '';
      final cachedThreads = OfflineRepository.getCached('/threads/branch/$displayBranchId');
      if (cachedThreads is List && cachedThreads.isNotEmpty) {
        threadId = cachedThreads[0]['id'];
        final cachedPosts = OfflineRepository.getCached('/threads/$threadId/posts');
        if (cachedPosts is List) { messages = cachedPosts; loading = false; }
      }
    }
    _loadThread();
  }

  Color _colorFor(String name) => _authorColors.putIfAbsent(name, () => _nameColors[_authorColors.length % _nameColors.length]);

  Future<void> _loadThread() async {
    if (messages.isEmpty) setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      user = jsonDecode(prefs.getString('authUser')!);
      final me = await OfflineRepository.getUserMe();
      displayBranchId = me['branch_id'];
      branchName = me['branch_name'] ?? 'Branch $displayBranchId';
      final tr = await OfflineRepository.getThreads(displayBranchId!);
      if (tr.isNotEmpty) {
        threadId = tr[0]['id'];
        await _loadMessages();
      }
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _loadMessages() async {
    if (threadId == null) return;
    try {
      final data = await OfflineRepository.getPosts(threadId!);
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
      final r = await OfflineRepository.postMessage(threadId!, text);
      if (r.synced) {
        await _loadMessages();
      } else if (mounted && !_queuedNoticeShown) {
        // Keep the optimistic bubble (clock icon = pending sync).
        _queuedNoticeShown = true;
        AppFeedback.showQueued(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() { messages.removeWhere((m) => m['id'] == optimistic['id']); });
        AppFeedback.showError(context, e);
      }
    }
    finally { if (mounted) setState(() => sending = false); }
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
    if (loading) return const Scaffold(body: ShimmerList(count: 6));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsetsDirectional.fromSTEB(16, MediaQuery.of(context).padding.top + 10, 12, 14),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(children: [
                GradientAvatar(name: branchName, size: 44),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(branchName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text('${messages.length} ${AppLocalizations.of(context).translate('messages')}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500)),
                ])),
                HeaderIconButton(icon: Icons.refresh_rounded, onTap: _loadMessages),
              ]),
            ),

            // Messages
            Expanded(
              child: Container(
                color: AppColors.scaffoldBg,
                child: messages.isEmpty
                    ? (!ConnectivityService.isOnline && threadId == null
                        ? EmptyState(
                            icon: Icons.wifi_off_rounded,
                            title: AppLocalizations.of(context).translate('no_connection'),
                            message: AppLocalizations.of(context).translate('offline_load_chat'),
                          )
                        : EmptyState(icon: Icons.chat_bubble_outline_rounded, title: AppLocalizations.of(context).translate('no_messages')))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
                        itemCount: messages.length,
                        itemBuilder: (_, i) => _buildMsg(i),
                      ),
              ),
            ),

            // Composer
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
              ),
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
              child: SafeArea(
                top: false,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: AppColors.divider, width: 0.8),
                      ),
                      child: TextField(
                        controller: _msgCtrl, maxLines: 5, minLines: 1, maxLength: 1000, enabled: !sending,
                        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(hintText: AppLocalizations.of(context).translate('message_hint'), hintStyle: const TextStyle(color: AppColors.textTertiary), counterText: '', border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), fillColor: Colors.transparent, filled: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _msgCtrl.text.trim().isNotEmpty && !sending ? _postMessage : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        gradient: sending || _msgCtrl.text.trim().isEmpty ? null : AppColors.accentGradient,
                        color: sending || _msgCtrl.text.trim().isEmpty ? AppColors.shimmerBase : null,
                        shape: BoxShape.circle,
                        boxShadow: sending || _msgCtrl.text.trim().isEmpty
                            ? null
                            : [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Center(child: sending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(Icons.send_rounded, color: _msgCtrl.text.trim().isEmpty ? AppColors.textTertiary : Colors.white, size: 22)),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMsg(int i) {
    final msg = Map<String, dynamic>.from(messages[i]);
    final createdAt = msg['created_at']?.toString() ?? DateTime.now().toIso8601String();
    final author = msg['author']?.toString() ?? AppLocalizations.of(context).translate('unknown_author');
    final message = msg['message']?.toString() ?? '';
    final isMine = msg['user_id'] == user?['id'];
    final isSending = msg['_sending'] == true;
    final showDate = i == 0 || !_sameDay(createdAt, messages[i - 1]['created_at']?.toString() ?? '');
    final showAuthor = !isMine && (i == 0 || messages[i - 1]['user_id'] != msg['user_id'] || showDate);
    final isLast = i == messages.length - 1 || messages[i + 1]['user_id'] != msg['user_id'] || (i < messages.length - 1 && !_sameDay(createdAt, messages[i + 1]['created_at']?.toString() ?? ''));
    final time = DateFormat('h:mm a', AppLocalizations.of(context).locale.languageCode).format(DateTime.tryParse(createdAt) ?? DateTime.now());

    final bubble = AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isSending ? 0.6 : 1.0,
      child: Container(
        padding: EdgeInsets.fromLTRB(14, showAuthor && !isMine ? 8 : 10, 14, 9),
        decoration: BoxDecoration(
          gradient: isMine ? AppColors.accentGradient : null,
          color: isMine ? null : AppColors.cardBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(!isMine && isLast ? 4 : 18),
            topRight: Radius.circular(isMine && isLast ? 4 : 18),
            bottomLeft: const Radius.circular(18),
            bottomRight: const Radius.circular(18),
          ),
          border: isMine ? null : Border.all(color: AppColors.divider, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: isMine ? AppColors.accent.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (showAuthor && !isMine)
            Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(author, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _colorFor(author)))),
          Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Flexible(child: Text(message, style: TextStyle(fontSize: 15, height: 1.35, color: isMine ? Colors.white : AppColors.textPrimary))),
            const SizedBox(width: 8),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(time, style: TextStyle(fontSize: 10.5, color: isMine ? Colors.white.withValues(alpha: 0.75) : AppColors.textTertiary)),
              if (isMine) ...[
                const SizedBox(width: 3),
                Icon(isSending ? Icons.access_time : Icons.done_all, size: 15, color: isSending ? Colors.white.withValues(alpha: 0.6) : Colors.white),
              ],
            ]),
          ]),
        ]),
      ),
    );

    return Column(children: [
      if (showDate) Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Text(_dateLabel(DateTime.tryParse(createdAt) ?? DateTime.now()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
      ),
      Align(
        alignment: isMine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: isMine ? 56 : 0,
            end: isMine ? 0 : 56,
            top: showAuthor ? 8 : 2,
            bottom: 2,
          ),
          child: isMine
              ? bubble
              : Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                  if (isLast) GradientAvatar(name: author, size: 30)
                  else const SizedBox(width: 30),
                  const SizedBox(width: 8),
                  Flexible(child: bubble),
                ]),
        ),
      ),
    ]);
  }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }
}
