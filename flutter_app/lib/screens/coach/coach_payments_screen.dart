import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class CoachPaymentsScreen extends StatefulWidget {
  const CoachPaymentsScreen({super.key});
  @override
  State<CoachPaymentsScreen> createState() => _CoachPaymentsScreenState();
}

class _CoachPaymentsScreenState extends State<CoachPaymentsScreen> {
  List<dynamic> records = [];
  List<String> sessionDates = [];
  bool loading = true;
  String search = '';

  @override
  void initState() { super.initState(); _fetchSummary(); }

  Future<void> _fetchSummary() async {
    setState(() => loading = true);
    final branchId = context.read<AuthProvider>().branchId;
    try {
      final res = await ApiService().get('/payments/summary/$branchId');
      records = res.data['records'] ?? [];
      sessionDates = List<String>.from(res.data['session_dates'] ?? []);
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _markPayment(int athleteId, String date, String status) async {
    try {
      await ApiService().post('/payments/mark', data: {'athlete_id': athleteId, 'session_date': date, 'status': status});
      _fetchSummary();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (loading) return AppLoadingScreen(message: l.translate('loading'));

    final sorted = List.from(records)..sort((a, b) => (a['athlete_name'] as String).compareTo(b['athlete_name']));
    final filtered = sorted.where((r) => (r['athlete_name'] as String).toLowerCase().contains(search.toLowerCase())).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.translate('payment_tracking'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('${filtered.length} athletes', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (v) => setState(() => search = v),
                    decoration: InputDecoration(hintText: l.translate('search_athlete'), prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchSummary,
                child: filtered.isEmpty
                    ? ListView(children: [const SizedBox(height: 100), Center(child: Text(l.translate('no_athletes'), style: const TextStyle(color: AppColors.textSecondary)))])
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
            ),
          ],
        ),
      ),
    );
  }
}
