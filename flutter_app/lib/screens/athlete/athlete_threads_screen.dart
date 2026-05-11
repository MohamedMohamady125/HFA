import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class AthleteThreadsScreen extends StatefulWidget {
  const AthleteThreadsScreen({super.key});
  @override
  State<AthleteThreadsScreen> createState() => _AthleteThreadsScreenState();
}

class _AthleteThreadsScreenState extends State<AthleteThreadsScreen> {
  List<dynamic> threads = [];
  List<dynamic> posts = [];
  Map<String, dynamic>? selectedThread;
  bool loading = true;
  bool postsLoading = false;
  String branchName = '';
  final _scrollController = ScrollController();
  static const baseUrl = ApiService.baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored == null) return;
      final user = jsonDecode(stored);
      final headers = {'Authorization': 'Bearer ${user['token']}'};
      final dio = Dio();

      final meRes = await dio.get('$baseUrl/users/me', options: Options(headers: headers));
      final branchId = meRes.data['branch_id'];

      final branchRes = await dio.get('$baseUrl/branches/$branchId', options: Options(headers: headers));
      branchName = branchRes.data['name'] ?? '';

      final threadsRes = await dio.get('$baseUrl/threads/branch/$branchId', options: Options(headers: headers));
      var fetched = threadsRes.data as List;

      fetched = fetched.map((t) {
        final title = t['title'] as String;
        if (title.toLowerCase().contains('branch') && title.contains('General')) {
          return {...t, 'title': 'Branch: $branchName'};
        }
        return t;
      }).where((t) {
        final title = (t['title'] as String).toLowerCase();
        return !title.contains('gear') && !title.contains('equipment');
      }).toList();

      threads = fetched;
      if (fetched.isNotEmpty) {
        await _selectThread(fetched[0], headers);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load threads: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _selectThread(dynamic thread, Map<String, String>? headersOverride) async {
    setState(() {
      postsLoading = true;
      selectedThread = Map<String, dynamic>.from(thread);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      final user = jsonDecode(stored!);
      final headers = headersOverride ?? {'Authorization': 'Bearer ${user['token']}'};
      final dio = Dio();

      final postsRes = await dio.get('$baseUrl/threads/${thread['id']}/posts', options: Options(headers: headers));
      posts = postsRes.data;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load posts: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => postsLoading = false);
    }
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('EEE, MMM d, yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return 'Invalid Date';
    }
  }

  String _formatTime(String iso) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return 'Invalid Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE6F2FF),
        body: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: Color(0xFF00BCD4)),
                SizedBox(height: 16),
                Text('Loading threads...', style: TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE6F2FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              color: const Color(0xFF3399FF),
              child: Row(
                children: [
                  Text('\u{1F4AC} Branch Threads${branchName.isNotEmpty ? ' - $branchName' : ''}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),

            if (threads.isEmpty)
              const Expanded(child: Center(child: Text('No threads available', style: TextStyle(fontSize: 18, color: Color(0xFF005580), fontWeight: FontWeight.w600))))
            else ...[
              // Thread buttons
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFD0E7FF),
                child: Wrap(
                  spacing: 12, runSpacing: 12,
                  children: threads.map((t) {
                    final isActive = selectedThread?['id'] == t['id'];
                    return GestureDetector(
                      onTap: () => _selectThread(t, null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF3399FF) : const Color(0xFF99CCFF),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: isActive ? [BoxShadow(color: const Color(0xFF1A73E8).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                        ),
                        child: Text(t['title'], style: TextStyle(color: isActive ? Colors.white : const Color(0xFF003366), fontWeight: isActive ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Posts
              if (postsLoading)
                const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4))))
              else if (posts.isEmpty)
                Expanded(child: Center(child: Text(selectedThread != null ? 'No messages in "${selectedThread!['title']}" yet' : 'Select a thread', style: const TextStyle(fontSize: 16, color: Color(0xFF003366)))))
              else
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: posts.length,
                    itemBuilder: (_, i) {
                      final post = posts[i];
                      final prevPost = i < posts.length - 1 ? posts[i + 1] : null;
                      final showDate = prevPost == null || _formatDate(post['created_at']) != _formatDate(prevPost['created_at']);

                      return Column(
                        children: [
                          if (showDate)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                              decoration: BoxDecoration(color: const Color(0xFF99CCFF), borderRadius: BorderRadius.circular(12)),
                              child: Text(_formatDate(post['created_at']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF003366))),
                            ),
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCDE7FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF99CFFF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post['message'] ?? '', style: const TextStyle(fontSize: 16, color: Color(0xFF003366), fontWeight: FontWeight.w500, height: 1.38)),
                                const SizedBox(height: 8),
                                Text('\u{2014} ${post['author']} | ${_formatTime(post['created_at'])}', style: const TextStyle(fontSize: 13, color: Color(0xFF336699), fontWeight: FontWeight.w500)),
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
}
