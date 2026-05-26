import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/offline/offline_repository.dart';
import '../../theme/app_theme.dart';

class CoachAthletesScreen extends StatefulWidget {
  const CoachAthletesScreen({super.key});
  @override
  State<CoachAthletesScreen> createState() => CoachAthletesScreenState();
}

class CoachAthletesScreenState extends State<CoachAthletesScreen> {
  List<dynamic> athletes = [];
  bool loading = true;
  String search = '';

  void silentRefresh() { _fetch(silent: true); }

  @override
  void initState() {
    super.initState();
    final branchId = context.read<AuthProvider>().branchId;
    if (branchId != null) {
      final cached = OfflineRepository.getCached('/athletes/branch/$branchId/full');
      if (cached is List && cached.isNotEmpty) { athletes = cached; loading = false; }
    }
    _fetch();
  }

  Future<void> _fetch({bool silent = false}) async {
    if (!silent && athletes.isEmpty) setState(() => loading = true);
    final branchId = context.read<AuthProvider>().branchId;
    try {
      final data = await OfflineRepository.getAthletesFull(branchId!);
      athletes = data;
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: ShimmerList(count: 5));

    final filtered = athletes.where((a) => (a['name'] as String).toLowerCase().contains(search.toLowerCase())).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FadeSlideIn(child: Row(children: [
                  const Expanded(child: Text('Athletes', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text('${athletes.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent))),
                ])),
                const SizedBox(height: 14),
                TextField(onChanged: (v) => setState(() => search = v), decoration: const InputDecoration(hintText: 'Search athlete...', prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiary))),
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetch(silent: true), color: AppColors.accent,
                child: filtered.isEmpty
                    ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [const SizedBox(height: 100), Center(child: Icon(Icons.people_outline_rounded, size: 56, color: AppColors.textTertiary.withValues(alpha: 0.4))), const SizedBox(height: 16), const Center(child: Text('No athletes found', style: TextStyle(color: AppColors.textSecondary)))])
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final a = filtered[i];
                          final rate = a['attendance_rate'] ?? 0;
                          final rateColor = rate >= 75 ? AppColors.success : rate >= 50 ? AppColors.warning : AppColors.error;
                          final payStatus = a['payment_status'] ?? 'none';
                          final payColor = payStatus == 'paid' ? AppColors.success : payStatus == 'late' ? AppColors.error : AppColors.warning;

                          return FadeSlideIn(delay: i * 40, child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ScaleOnTap(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AthleteDetailScreen(athlete: a))),
                              child: AppCard(child: Row(children: [
                                GradientAvatar(name: a['name'] ?? '?', size: 48),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(a['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    StatusBadge(label: '$rate%', color: rateColor),
                                    const SizedBox(width: 6),
                                    StatusBadge(label: payStatus == 'none' ? 'No payment' : payStatus[0].toUpperCase() + payStatus.substring(1), color: payColor),
                                  ]),
                                ])),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
                              ])),
                            ),
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

// ═══════════════════════════════════════════════════════════
// ATHLETE DETAIL SCREEN
// ═══════════════════════════════════════════════════════════
class _AthleteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> athlete;
  const _AthleteDetailScreen({required this.athlete});
  @override
  State<_AthleteDetailScreen> createState() => _AthleteDetailScreenState();
}

class _AthleteDetailScreenState extends State<_AthleteDetailScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, String> _attMap = {};
  bool _loadingCal = true;

  Map<String, dynamic> get a => widget.athlete;

  @override
  void initState() { super.initState(); _fetchMonth(); }

  Future<void> _fetchMonth() async {
    setState(() => _loadingCal = true);
    try {
      final res = await ApiService().get('/attendance/athlete/${a['user_id']}/month/${_currentMonth.year}/${_currentMonth.month}');
      _attMap = { for (var r in (res.data as List)) r['date'].toString(): r['status']?.toString() ?? '' };
    } catch (_) { _attMap = {}; }
    finally { if (mounted) setState(() => _loadingCal = false); }
  }

  void _prevMonth() { setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)); _fetchMonth(); }
  void _nextMonth() {
    final now = DateTime.now();
    if (DateTime(_currentMonth.year, _currentMonth.month + 1).isAfter(DateTime(now.year, now.month + 1))) return;
    setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));
    _fetchMonth();
  }

  @override
  Widget build(BuildContext context) {
    final measurements = a['measurements'] as Map<String, dynamic>?;
    final events = a['events'] as List? ?? [];
    final rate = a['attendance_rate'] ?? 0;
    final rateColor = rate >= 75 ? AppColors.success : rate >= 50 ? AppColors.warning : AppColors.error;
    final now = DateTime.now();
    final isCurrentMonth = _currentMonth.year == now.year && _currentMonth.month == now.month;
    final presentCount = _attMap.values.where((s) => s == 'present').length;
    final absentCount = _attMap.values.where((s) => s == 'absent').length;

    return Scaffold(
      appBar: AppBar(title: Text(a['name'] ?? 'Athlete')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Profile header
          FadeSlideIn(child: AppCard(child: Row(children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text((a['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (a['email'] != null) Text(a['email'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              if (a['phone'] != null) Text(a['phone'], style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: rateColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [Text('$rate%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: rateColor)), Text('Rate', style: TextStyle(fontSize: 10, color: rateColor))])),
          ]))),

          // ─── Monthly Attendance ───────────────────────────
          const SizedBox(height: 8),
          FadeSlideIn(delay: 100, child: const SectionHeader(title: 'Monthly Attendance')),
          FadeSlideIn(delay: 120, child: AppCard(child: Column(children: [
            // Month nav
            Row(children: [
              _navBtn(Icons.chevron_left_rounded, _prevMonth),
              Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                child: Text(DateFormat('MMMM yyyy').format(_currentMonth), key: ValueKey(_currentMonth), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center))),
              _navBtn(Icons.chevron_right_rounded, isCurrentMonth ? null : _nextMonth),
            ]),
            const SizedBox(height: 8),
            // Stats
            Row(children: [
              _miniStat('$presentCount', 'Present', AppColors.success),
              const SizedBox(width: 8),
              _miniStat('$absentCount', 'Absent', AppColors.error),
            ]),
            const SizedBox(height: 10),
            // Day headers
            Row(children: ['S','M','T','W','T','F','S'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary))))).toList()),
            const SizedBox(height: 4),
            // Calendar
            if (_loadingCal)
              const Padding(padding: EdgeInsets.all(20), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))))
            else
              _buildCal(),
          ]))),

          // ─── Measurements ─────────────────────────────────
          const SizedBox(height: 8),
          FadeSlideIn(delay: 200, child: const SectionHeader(title: 'Body Measurements')),
          FadeSlideIn(delay: 220, child: measurements != null
              ? AppCard(child: Wrap(spacing: 8, runSpacing: 8, children: [
                  _measureChip('Height', '${measurements['height']} cm'),
                  _measureChip('Weight', '${measurements['weight']} kg'),
                  _measureChip('Arm', '${measurements['arm']} cm'),
                  _measureChip('Leg', '${measurements['leg']} cm'),
                  _measureChip('Fat', '${measurements['fat']}%'),
                  _measureChip('Muscle', '${measurements['muscle']}%'),
                ]))
              : AppCard(child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.textTertiary, size: 18), const SizedBox(width: 8),
                  const Text('No measurements recorded yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ]))),

          // ─── Swim Events ──────────────────────────────────
          const SizedBox(height: 8),
          FadeSlideIn(delay: 300, child: const SectionHeader(title: 'Swim Events & Times')),
          FadeSlideIn(delay: 320, child: events.isNotEmpty
              ? AppCard(child: Column(children: events.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.pool_rounded, size: 18, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(child: Text(e['event_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                      Text(e['result_time']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
                    ]),
                  ),
                )).toList()))
              : AppCard(child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.textTertiary, size: 18), const SizedBox(width: 8),
                  const Text('No swim events recorded yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ]))),
        ]),
      ),
    );
  }

  Widget _buildCal() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final cells = <Widget>[];
    for (int i = 0; i < startWeekday; i++) cells.add(const SizedBox());
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final status = _attMap[dateStr];
      final isToday = date == today;
      Color? bg; Color tc = AppColors.textPrimary;
      if (status == 'present') { bg = AppColors.success; tc = Colors.white; }
      else if (status == 'absent') { bg = AppColors.error; tc = Colors.white; }
      else if (date.isAfter(today)) { tc = AppColors.textTertiary; }
      cells.add(Container(margin: const EdgeInsets.all(2), decoration: BoxDecoration(color: bg?.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(8), border: isToday ? Border.all(color: AppColors.accent, width: 2) : null),
        child: Center(child: Text('$day', style: TextStyle(fontSize: 12, fontWeight: isToday ? FontWeight.w800 : FontWeight.w500, color: bg != null ? tc : tc)))));
    }
    return GridView.count(crossAxisCount: 7, childAspectRatio: 1.2, physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, children: cells);
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) => GestureDetector(onTap: onTap, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: onTap != null ? AppColors.surfaceLight : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: onTap != null ? AppColors.textPrimary : AppColors.textTertiary, size: 20)));

  Widget _miniStat(String val, String label, Color color) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(color == AppColors.success ? Icons.check_rounded : Icons.close_rounded, size: 14, color: color), const SizedBox(width: 4), Text('$val $label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))])));

  Widget _measureChip(String label, String value) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary)), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))]));
}
