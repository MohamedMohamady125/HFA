import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class CoachPaymentsScreen extends StatefulWidget {
  const CoachPaymentsScreen({super.key});
  @override
  State<CoachPaymentsScreen> createState() => CoachPaymentsScreenState();
}

class CoachPaymentsScreenState extends State<CoachPaymentsScreen> {
  List<dynamic> records = [];
  List<String> sessionDates = [];
  bool loading = true;
  String search = '';
  final Set<String> _animating = {};

  void silentRefresh() { _fetchSummary(silent: true); }

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
      setState(() { for (var r in records) { if (r['athlete_id'] == athleteId) { (r['statuses'] as Map)[date] = status; break; } } });
    } catch (_) {}
    finally { setState(() => _animating.remove(key)); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (loading) return const Scaffold(body: ShimmerList(count: 4));

    final sorted = List.from(records)..sort((a, b) => (a['athlete_name'] as String).compareTo(b['athlete_name']));
    final filtered = sorted.where((r) => (r['athlete_name'] as String).toLowerCase().contains(search.toLowerCase())).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FadeSlideIn(child: Row(children: [
                  Expanded(child: Text(l.translate('payment_tracking'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text('${filtered.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent))),
                ])),
                const SizedBox(height: 16),
                TextField(onChanged: (v) => setState(() => search = v), decoration: InputDecoration(hintText: l.translate('search_athlete'), prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary))),
              ]),
            ),
            const SizedBox(height: 12),
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
                          return FadeSlideIn(delay: i * 50, child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Container(width: 42, height: 42, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(12)),
                                  child: Center(child: Text((item['athlete_name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)))),
                                const SizedBox(width: 12),
                                Expanded(child: Text(item['athlete_name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary))),
                              ]),
                              const SizedBox(height: 14),
                              ...sessionDates.map((date) {
                                final cs = (item['statuses'] ?? {})[date] ?? 'pending';
                                final key = '${item['athlete_id']}-$date';
                                final isAnim = _animating.contains(key);
                                return AnimatedOpacity(duration: const Duration(milliseconds: 200), opacity: isAnim ? 0.5 : 1.0,
                                  child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10)),
                                    child: Row(children: [
                                      Expanded(child: Text(date, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
                                      if (isAnim) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                                      else ...['paid', 'pending', 'late'].map((s) {
                                        final active = cs == s;
                                        final color = s == 'paid' ? AppColors.success : s == 'late' ? AppColors.error : AppColors.warning;
                                        return Padding(padding: const EdgeInsets.only(left: 6), child: ScaleOnTap(
                                          onTap: () => _markPayment(item['athlete_id'], date, s),
                                          child: AnimatedContainer(duration: const Duration(milliseconds: 250), width: 36, height: 36,
                                            decoration: BoxDecoration(color: active ? color : Colors.white, borderRadius: BorderRadius.circular(10),
                                              border: active ? null : Border.all(color: AppColors.divider),
                                              boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))] : null),
                                            child: Center(child: Text(s[0].toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: active ? Colors.white : AppColors.textTertiary)))),
                                        ));
                                      }),
                                    ]),
                                  )));
                              }),
                            ])),
                          ));
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
