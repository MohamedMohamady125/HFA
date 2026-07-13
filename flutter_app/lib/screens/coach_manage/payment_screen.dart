import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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
    HapticFeedback.lightImpact();
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            FadeSlideIn(
              child: HeroHeader(
                title: l.translate('payment_tracking'),
                leading: HeaderIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.go('/coach/home')),
                trailing: records.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text('${records.length}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                      )
                    : null,
                bottom: TextField(
                  onChanged: (v) => setState(() => search = v),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l.translate('search_athlete'),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchSummary(silent: true),
                color: AppColors.accent,
                child: filtered.isEmpty
                    ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                        const SizedBox(height: 60),
                        EmptyState(icon: Icons.payments_rounded, title: l.translate('no_athletes')),
                      ])
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 20),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          return FadeSlideIn(
                            delay: i * 50,
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Athlete header
                                  Row(children: [
                                    GradientAvatar(name: item['athlete_name'] ?? '?', size: 44),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(item['athlete_name'], style: AppTypography.titleLarge)),
                                  ]),
                                  const SizedBox(height: 14),

                                  // Payment dates
                                  ...sessionDates.map((date) {
                                    final cs = (item['statuses'] ?? {})[date] ?? 'pending';
                                    final csColor = cs == 'paid' ? AppColors.success : cs == 'late' ? AppColors.error : AppColors.warning;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Expanded(child: Text(date, style: AppTypography.caption)),
                                            StatusBadge(label: l.translate(cs), color: csColor),
                                          ]),
                                          const SizedBox(height: 8),
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
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payBtn(String label, IconData icon, Color color, bool active, VoidCallback onTap) {
    return Expanded(
      child: ScaleOnTap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 48,
          decoration: BoxDecoration(
            color: active ? color : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: active ? null : Border.all(color: AppColors.divider),
            boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: active ? Colors.white : AppColors.textTertiary),
            const SizedBox(width: 4),
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textTertiary))),
          ]),
        ),
      ),
    );
  }
}
