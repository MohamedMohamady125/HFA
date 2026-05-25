import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
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
  final Set<String> _animating = {};

  @override
  void initState() { super.initState(); _fetchSummary(); }

  Future<void> _fetchSummary({bool silent = false}) async {
    if (!silent) setState(() => loading = true);
    final branchId = context.read<AuthProvider>().branchId;
    try {
      final res = await ApiService().get('/payments/summary/$branchId');
      records = res.data['records'] ?? [];
      sessionDates = List<String>.from(res.data['session_dates'] ?? []);
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _markPayment(int athleteId, String date, String status) async {
    final key = '$athleteId-$date';
    setState(() => _animating.add(key));
    try {
      await ApiService().post('/payments/mark', data: {'athlete_id': athleteId, 'session_date': date, 'status': status});
      // Update locally
      setState(() {
        for (var r in records) {
          if (r['athlete_id'] == athleteId) {
            (r['statuses'] as Map)[date] = status;
            break;
          }
        }
      });
    } catch (_) {}
    finally { setState(() => _animating.remove(key)); }
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
                                    final key = '${item['athlete_id']}-$date';
                                    final isAnimating = _animating.contains(key);

                                    return AnimatedOpacity(
                                      duration: const Duration(milliseconds: 200),
                                      opacity: isAnimating ? 0.5 : 1.0,
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
                                            const SizedBox(height: 6),
                                            if (isAnimating)
                                              const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)))
                                            else
                                              Row(children: [
                                                _payBtn('Paid', Icons.check_circle_rounded, AppColors.success, cs == 'paid', () => _markPayment(item['athlete_id'], date, 'paid')),
                                                const SizedBox(width: 8),
                                                _payBtn('Pending', Icons.schedule_rounded, AppColors.warning, cs == 'pending', () => _markPayment(item['athlete_id'], date, 'pending')),
                                                const SizedBox(width: 8),
                                                _payBtn('Late', Icons.warning_rounded, AppColors.error, cs == 'late', () => _markPayment(item['athlete_id'], date, 'late')),
                                              ]),
                                          ],
                                        ),
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
