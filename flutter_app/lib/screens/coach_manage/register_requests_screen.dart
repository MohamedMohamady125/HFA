import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class RegisterRequestsScreen extends StatefulWidget {
  const RegisterRequestsScreen({super.key});
  @override
  State<RegisterRequestsScreen> createState() => _RegisterRequestsScreenState();
}

class _RegisterRequestsScreenState extends State<RegisterRequestsScreen> {
  List<dynamic> requests = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _fetchRequests(); }

  Future<void> _fetchRequests() async {
    try { final res = await ApiService().get('/users/requests'); requests = res.data; }
    catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _approve(int id) async {
    try { await ApiService().post('/users/approve/$id'); _showMsg('Athlete approved'); _fetchRequests(); }
    catch (_) { _showMsg('Failed to approve', error: true); }
  }

  Future<void> _reject(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Reject Request?'), content: const Text('This will permanently reject the registration.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('Reject'))],
    ));
    if (ok != true) return;
    try { await ApiService().post('/users/reject/$id'); _showMsg('Request rejected'); _fetchRequests(); }
    catch (_) { _showMsg('Failed to reject', error: true); }
  }

  void _showMsg(String msg, {bool error = false}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? AppColors.error : AppColors.success));

  @override
  Widget build(BuildContext context) {
    if (loading) return const AppLoadingScreen(message: 'Loading requests...');

    return Scaffold(
      appBar: AppBar(title: const Text('Registration Requests'), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/coach/home'))),
      body: requests.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inbox_rounded, size: 56, color: AppColors.textTertiary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text('No pending requests', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: requests.length,
              itemBuilder: (_, i) {
                final req = requests[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          CircleAvatar(radius: 20, backgroundColor: AppColors.accent.withValues(alpha: 0.1), child: Text((req['athlete_name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(req['athlete_name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text(req['email'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ])),
                        ]),
                        if (req['phone'] != null) Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [const Icon(Icons.phone_outlined, size: 14, color: AppColors.textTertiary), const SizedBox(width: 6), Text(req['phone'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))])),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: OutlinedButton(onPressed: () => _reject(req['id']), style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)), child: const Text('Reject'))),
                          const SizedBox(width: 12),
                          Expanded(child: ElevatedButton(onPressed: () => _approve(req['id']), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success), child: const Text('Approve'))),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
