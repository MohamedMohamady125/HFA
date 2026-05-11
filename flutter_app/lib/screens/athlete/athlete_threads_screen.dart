import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AthleteThreadsScreen extends StatefulWidget {
  const AthleteThreadsScreen({super.key});
  @override
  State<AthleteThreadsScreen> createState() => _AthleteThreadsScreenState();
}

class _AthleteThreadsScreenState extends State<AthleteThreadsScreen> {
  List<dynamic> threads = [], posts = [];
  Map<String, dynamic>? selectedThread;
  bool loading = true, postsLoading = false;
  String branchName = '';

  @override
  void initState() { super.initState(); _fetchData(); }

  Future<void> _fetchData() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = jsonDecode(prefs.getString('authUser')!);
      final h = {'Authorization': 'Bearer ${user['token']}'};
      final dio = Dio();
      final base = ApiService.baseUrl;

      final me = await dio.get('$base/users/me', options: Options(headers: h));
      final branchId = me.data['branch_id'];
      final br = await dio.get('$base/branches/$branchId', options: Options(headers: h));
      branchName = br.data['name'] ?? '';
      final tr = await dio.get('$base/threads/branch/$branchId', options: Options(headers: h));

      threads = (tr.data as List).where((t) {
        final title = (t['title'] as String).toLowerCase();
        return !title.contains('gear') && !title.contains('equipment');
      }).toList();

      if (threads.isNotEmpty) await _selectThread(threads[0], h);
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _selectThread(dynamic thread, Map<String, String>? h) async {
    setState(() { postsLoading = true; selectedThread = Map<String, dynamic>.from(thread); });
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = jsonDecode(prefs.getString('authUser')!);
      final headers = h ?? {'Authorization': 'Bearer ${user['token']}'};
      final r = await Dio().get('${ApiService.baseUrl}/threads/${thread['id']}/posts', options: Options(headers: headers));
      posts = r.data;
    } catch (_) {} finally { if (mounted) setState(() => postsLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const AppLoadingScreen(message: 'Loading threads...');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.forum_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(child: Text(branchName.isNotEmpty ? branchName : 'Threads', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                ],
              ),
            ),
            if (threads.isEmpty) const Expanded(child: Center(child: Text('No threads available', style: TextStyle(color: AppColors.textSecondary))))
            else ...[
              // Thread chips
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: threads.map((t) {
                    final active = selectedThread?['id'] == t['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t['title']),
                        selected: active,
                        onSelected: (_) => _selectThread(t, null),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: active ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                        backgroundColor: AppColors.surfaceLight,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),

              // Posts
              if (postsLoading)
                const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
              else if (posts.isEmpty)
                const Expanded(child: Center(child: Text('No messages yet', style: TextStyle(color: AppColors.textSecondary))))
              else
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (_, i) {
                      final post = posts[i];
                      final prev = i < posts.length - 1 ? posts[i + 1] : null;
                      final showDate = prev == null || _fmtDate(post['created_at']) != _fmtDate(prev['created_at']);
                      return Column(
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(20)),
                                child: Text(_fmtDate(post['created_at']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                              ),
                            ),
                          AppCard(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(radius: 14, backgroundColor: AppColors.accent.withValues(alpha: 0.15), child: Text((post['author'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent))),
                                    const SizedBox(width: 8),
                                    Text(post['author'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    const Spacer(),
                                    Text(_fmtTime(post['created_at']), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(post['message'] ?? '', style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtDate(String iso) { try { return DateFormat('EEE, MMM d').format(DateTime.parse(iso)); } catch (_) { return ''; } }
  String _fmtTime(String iso) { try { return DateFormat('h:mm a').format(DateTime.parse(iso)); } catch (_) { return ''; } }
}
