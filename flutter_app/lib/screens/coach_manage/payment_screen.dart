import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<dynamic> records = [];
  List<String> sessionDates = [];
  bool loading = true;
  String search = '';

  @override
  void initState() { super.initState(); _fetchSummary(); }

  Future<void> _fetchSummary() async {
    final branchId = context.read<AuthProvider>().branchId;
    try {
      final res = await ApiService().get('/payments/summary/$branchId');
      records = res.data['records'] ?? [];
      sessionDates = List<String>.from(res.data['session_dates'] ?? []);
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _markPayment(int athleteId, String date, String status) async {
    try { await ApiService().post('/payments/mark', data: {'athlete_id': athleteId, 'session_date': date, 'status': status}); _fetchSummary(); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const AppLoadingScreen(message: 'Loading payments...');

    final sorted = List.from(records)..sort((a, b) => (a['athlete_name'] as String).compareTo(b['athlete_name']));
    final filtered = sorted.where((r) => (r['athlete_name'] as String).toLowerCase().contains(search.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Tracking'), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/coach/home'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: const InputDecoration(hintText: 'Search athlete...', prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiary)),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No athletes found.', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['athlete_name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
                              const SizedBox(height: 12),
                              ...sessionDates.map((date) {
                                final cs = (item['statuses'] ?? {})[date] ?? 'pending';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(date, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                                      ...['paid', 'pending', 'late'].map((s) {
                                        final active = cs == s;
                                        final color = s == 'paid' ? AppColors.success : s == 'late' ? AppColors.error : AppColors.warning;
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 6),
                                          child: GestureDetector(
                                            onTap: () => _markPayment(item['athlete_id'], date, s),
                                            child: Container(
                                              width: 36, height: 36,
                                              decoration: BoxDecoration(color: active ? color : AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
                                              child: Center(child: Text(s[0].toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textSecondary))),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
