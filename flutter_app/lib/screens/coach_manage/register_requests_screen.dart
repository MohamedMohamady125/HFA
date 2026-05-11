import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';

class RegisterRequestsScreen extends StatefulWidget {
  const RegisterRequestsScreen({super.key});
  @override
  State<RegisterRequestsScreen> createState() => _RegisterRequestsScreenState();
}

class _RegisterRequestsScreenState extends State<RegisterRequestsScreen> {
  List<dynamic> requests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final res = await ApiService().get('/users/requests');
      requests = res.data;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load requests'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _approve(int id) async {
    try {
      await ApiService().post('/users/approve/$id');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Athlete approved.'), backgroundColor: Colors.green));
      _fetchRequests();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to approve'), backgroundColor: Colors.red));
    }
  }

  Future<void> _reject(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Reject'),
        content: const Text('This will permanently reject the registration request.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Reject')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService().post('/users/reject/$id');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected.'), backgroundColor: Colors.orange));
      _fetchRequests();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to reject'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF007AFF))));

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF007AFF)), onPressed: () => context.go('/coach/home')),
              const SizedBox(height: 10),
              const Text('\u{1F4DD} Pending Registration Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (requests.isEmpty)
                const Text('No pending requests.')
              else
                ...requests.map((req) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('\u{1F4E7} ${req['email']}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('\u{1F4F1} ${req['phone']}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('\u{1F9CD} ${req['athlete_name']}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: ElevatedButton(onPressed: () => _approve(req['id']), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('Approve'))),
                          const SizedBox(width: 10),
                          Expanded(child: ElevatedButton(onPressed: () => _reject(req['id']), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Reject'))),
                        ],
                      ),
                    ],
                  ),
                )),
            ],
          ),
        ),
      ),
    );
  }
}
