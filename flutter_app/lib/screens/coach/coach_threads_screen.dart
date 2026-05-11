import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
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
  final _msgCtrl = TextEditingController();
  bool loading = true, sending = false;
  int? threadId, displayBranchId;
  final _scrollCtrl = ScrollController();

  @override
  void initState() { super.initState(); _loadThread(); }

  Future<void> _loadThread() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      user = jsonDecode(prefs.getString('authUser')!);
      final api = ApiService();
      final me = await api.get('/users/me');
      displayBranchId = me.data['branch_id'];
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
      WidgetsBinding.instance.addPostFrameCallback((_) { if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent); });
    } catch (_) { messages = []; }
    if (mounted) setState(() {});
  }

  Future<void> _postMessage() async {
    if (_msgCtrl.text.trim().isEmpty || threadId == null || sending) return;
    setState(() => sending = true);
    final text = _msgCtrl.text.trim();
    _msgCtrl.clear();
    try {
      await ApiService().post('/threads/$threadId/post', data: {'message': text});
      await _loadMessages();
    } catch (_) {} finally { if (mounted) setState(() => sending = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (loading) return AppLoadingScreen(message: l.translate('loading'));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text('${displayBranchId ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.translate('branch_chat'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('${messages.length} ${l.translate('messages')}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ])),
                  IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.accent), onPressed: _loadMessages),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: messages.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.textTertiary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(l.translate('no_messages'), style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ]))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final msg = messages[i];
                        final isMine = msg['user_id'] == user?['id'];
                        final showDate = i == 0 || !_sameDay(msg['created_at'], messages[i - 1]['created_at']);

                        return Column(children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(20)),
                                child: Text(DateFormat('EEEE, MMM d').format(DateTime.parse(msg['created_at'])), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                              ),
                            ),
                          Align(
                            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                              decoration: BoxDecoration(
                                color: isMine ? AppColors.accent : AppColors.cardBg,
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isMine ? const Radius.circular(4) : null,
                                  bottomLeft: !isMine ? const Radius.circular(4) : null,
                                ),
                                border: isMine ? null : Border.all(color: AppColors.divider),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (!isMine) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(msg['author'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent))),
                                Text(msg['message'] ?? '', style: TextStyle(fontSize: 15, height: 1.4, color: isMine ? Colors.white : AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Align(alignment: Alignment.bottomRight, child: Text(DateFormat('h:mm a').format(DateTime.parse(msg['created_at'])), style: TextStyle(fontSize: 11, color: isMine ? Colors.white60 : AppColors.textTertiary))),
                              ]),
                            ),
                          ),
                        ]);
                      },
                    ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              decoration: BoxDecoration(color: AppColors.cardBg, border: Border(top: BorderSide(color: AppColors.divider))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl, maxLines: null, maxLength: 1000, enabled: !sending,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(hintText: l.translate('type_message'), counterText: '', contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppColors.divider)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppColors.divider))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: sending ? AppColors.textTertiary : AppColors.accent, shape: BoxShape.circle),
                    child: IconButton(
                      onPressed: _msgCtrl.text.trim().isNotEmpty && !sending ? _postMessage : null,
                      icon: sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(String a, String b) { final da = DateTime.parse(a); final db = DateTime.parse(b); return da.year == db.year && da.month == db.month && da.day == db.day; }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }
}
