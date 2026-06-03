import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/offline/offline_repository.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

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

  Future<void> _fetchSummary({bool silent = false}) async {
    if (!silent) setState(() => loading = true);
    final branchId = context.read<AuthProvider>().branchId;
    try {
      final data = await OfflineRepository.getPaymentSummary(branchId!);
      records = data['records'] ?? [];
      sessionDates = List<String>.from(data['session_dates'] ?? []);
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  void _markPayment(int athleteId, String date, String status) {
    final branchId = context.read<AuthProvider>().branchId;
    setState(() { for (var r in records) { if (r['athlete_id'] == athleteId) { (r['statuses'] as Map)[date] = status; break; } } });
    OfflineRepository.markPayment(athleteId, date, status, branchId!);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (loading) return const Scaffold(body: ShimmerList(count: 5));

    final sorted = List.from(records)..sort((a, b) => (a['athlete_name'] as String).compareTo(b['athlete_name']));
    final filtered = sorted.where((r) => (r['athlete_name'] as String).toLowerCase().contains(search.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.translate('payment_tracking')),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/coach/home')),
        actions: [
          if (records.isNotEmpty) Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('${records.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
          ))),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(hintText: l.translate('search_athlete'), prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary)),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchSummary(silent: true),
              color: AppColors.accent,
              child: filtered.isEmpty
                  ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [const SizedBox(height: 100), Center(child: Text(l.translate('no_athletes'), style: const TextStyle(color: AppColors.textSecondary)))])
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final item = filtered[i];
                        return FadeSlideIn(
                          delay: i * 50,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Athlete header
                                  Row(children: [
                                    Container(
                                      width: 42, height: 42,
                                      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(12)),
                                      child: Center(child: Text((item['athlete_name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(item['athlete_name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary))),
                                  ]),
                                  const SizedBox(height: 14),

                                  // Payment dates
                                  ...sessionDates.map((date) {
                                    final cs = (item['statuses'] ?? {})[date] ?? 'pending';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 6),
                                          Row(children: [
                                            _payBtn(l.translate('paid'), Icons.check_circle_rounded, AppColors.success, cs == 'paid', () => _markPayment(item['athlete_id'], date, 'paid')),
                                            const SizedBox(width: 8),
                                            _payBtn(l.translate('pending'), Icons.schedule_rounded, AppColors.warning, cs == 'pending', () => _markPayment(item['athlete_id'], date, 'pending')),
                                            const SizedBox(width: 8),
                                            _payBtn(l.translate('late'), Icons.warning_rounded, AppColors.error, cs == 'late', () => _markPayment(item['athlete_id'], date, 'late')),
                                          ]),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payBtn(String label, IconData icon, Color color, bool active, VoidCallback onTap) {
    return Expanded(
      child: ScaleOnTap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? color : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: active ? null : Border.all(color: AppColors.divider),
            boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: active ? Colors.white : AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textTertiary)),
          ]),
        ),
      ),
    );
  }
}
