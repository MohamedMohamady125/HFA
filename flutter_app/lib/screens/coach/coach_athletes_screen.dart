import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/offline/offline_repository.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

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
    final l = AppLocalizations.of(context);
    if (loading) return const Scaffold(body: ShimmerList(count: 5));

    final filtered = athletes.where((a) => (a['name'] as String).toLowerCase().contains(search.toLowerCase())).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeSlideIn(
              child: HeroHeader(
                title: l.translate('athletes'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text('${athletes.length}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
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
                onRefresh: () => _fetch(silent: true), color: AppColors.accent,
                child: filtered.isEmpty
                    ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                        const SizedBox(height: 60),
                        EmptyState(icon: Icons.people_outline_rounded, title: l.translate('no_athletes')),
                      ])
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 20),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final a = filtered[i];
                          final rate = a['attendance_rate'] ?? 0;
                          final rateColor = rate >= 75 ? AppColors.success : rate >= 50 ? AppColors.warning : AppColors.error;
                          final payStatus = a['payment_status'] ?? 'none';
                          final payColor = payStatus == 'paid' ? AppColors.success : payStatus == 'late' ? AppColors.error : AppColors.warning;

                          return FadeSlideIn(delay: i * 50, child: ScaleOnTap(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AthleteDetailScreen(athlete: a))),
                            child: AppCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(children: [
                                GradientAvatar(name: a['name'] ?? '?', size: 48),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(a['name'] ?? '', style: AppTypography.titleMedium),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    StatusBadge(label: '$rate%', color: rateColor),
                                    const SizedBox(width: 6),
                                    StatusBadge(label: payStatus == 'none' ? l.translate('no_payment') : l.translate(payStatus), color: payColor),
                                  ]),
                                ])),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 22),
                              ]),
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
  List<dynamic> _healthRecords = [];
  List<dynamic> _coachNotes = [];

  Map<String, dynamic> get a => widget.athlete;

  @override
  void initState() { super.initState(); _fetchMonth(); _fetchHealthRecords(); _fetchCoachNotes(); }

  Future<void> _fetchMonth() async {
    setState(() => _loadingCal = true);
    try {
      final res = await ApiService().get('/attendance/athlete/${a['user_id']}/month/${_currentMonth.year}/${_currentMonth.month}');
      _attMap = { for (var r in (res.data as List)) r['date'].toString(): r['status']?.toString() ?? '' };
    } catch (_) { _attMap = {}; }
    finally { if (mounted) setState(() => _loadingCal = false); }
  }

  Future<void> _fetchHealthRecords() async {
    try {
      final res = await ApiService().get('/athlete/${a['user_id']}/health-records');
      if (mounted) setState(() => _healthRecords = res.data is List ? res.data : []);
    } catch (_) {}
  }

  Future<void> _fetchCoachNotes() async {
    try {
      final res = await ApiService().get('/coach/notes/${a['athlete_id']}');
      if (mounted) setState(() => _coachNotes = res.data is List ? res.data : []);
    } catch (_) {}
  }

  Future<void> _addCoachNote() async {
    final l = AppLocalizations.of(context);
    final noteCtrl = TextEditingController();
    final now = DateTime.now();
    final periodStart = now.subtract(Duration(days: now.weekday - 1));
    final periodEnd = periodStart.add(const Duration(days: 13));
    final periodLabel = '${DateFormat('MMM d').format(periodStart)} - ${DateFormat('MMM d, yyyy').format(periodEnd)}';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.translate('add_coach_note'), style: const TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.date_range_rounded, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(periodLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
            ]),
          ),
          const SizedBox(height: 14),
          TextField(controller: noteCtrl, maxLines: 5, decoration: InputDecoration(hintText: l.translate('coach_note_hint'))),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.translate('cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.translate('save'))),
        ],
      ),
    );

    if (result != true || noteCtrl.text.trim().isEmpty) return;
    try {
      await ApiService().post('/coach/notes', data: {
        'athlete_id': a['athlete_id'],
        'note': noteCtrl.text.trim(),
        'period_label': periodLabel,
      });
      _fetchCoachNotes();
    } catch (_) {}
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
      appBar: AppBar(title: Text(a['name'] ?? AppLocalizations.of(context).translate('athlete'))),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Profile header
          FadeSlideIn(child: AppCard(child: Row(children: [
            GradientAvatar(name: a['name'] ?? '?', size: 56),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (a['email'] != null) Text(a['email'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              if (a['phone'] != null) Text(a['phone'], style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: rateColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [Text('$rate%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: rateColor)), Text(AppLocalizations.of(context).translate('rate'), style: TextStyle(fontSize: 10, color: rateColor))])),
          ]))),

          // ─── Monthly Attendance ───────────────────────────
          const SizedBox(height: 8),
          FadeSlideIn(delay: 100, child: SectionHeader(title: AppLocalizations.of(context).translate('monthly_attendance'))),
          FadeSlideIn(delay: 120, child: AppCard(child: Column(children: [
            // Month nav
            Row(children: [
              _navBtn(Icons.chevron_left_rounded, _prevMonth),
              Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                child: Text(DateFormat('MMMM yyyy', AppLocalizations.of(context).locale.languageCode).format(_currentMonth), key: ValueKey(_currentMonth), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center))),
              _navBtn(Icons.chevron_right_rounded, isCurrentMonth ? null : _nextMonth),
            ]),
            const SizedBox(height: 8),
            // Stats
            Row(children: [
              _miniStat('$presentCount', AppLocalizations.of(context).translate('present'), AppColors.success),
              const SizedBox(width: 8),
              _miniStat('$absentCount', AppLocalizations.of(context).translate('absent'), AppColors.error),
            ]),
            const SizedBox(height: 10),
            // Day headers
            Row(children: [for (int i = 0; i < 7; i++) Expanded(child: Center(child: Text(DateFormat.E(AppLocalizations.of(context).locale.languageCode).format(DateTime(2025, 1, 5 + i)), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary))))]),
            const SizedBox(height: 4),
            // Calendar
            if (_loadingCal)
              const Padding(padding: EdgeInsets.all(20), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))))
            else
              _buildCal(),
          ]))),

          // ─── Measurements ─────────────────────────────────
          const SizedBox(height: 8),
          FadeSlideIn(delay: 200, child: SectionHeader(title: AppLocalizations.of(context).translate('body_measurements'))),
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
                  Text(AppLocalizations.of(context).translate('no_measurements'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ]))),

          // ─── Swim Events ──────────────────────────────────
          const SizedBox(height: 8),
          FadeSlideIn(delay: 300, child: SectionHeader(title: AppLocalizations.of(context).translate('swim_events_times'))),
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
                  Text(AppLocalizations.of(context).translate('no_swim_events'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ]))),

          // ─── Health History (from athlete) ─────────────────
          const SizedBox(height: 8),
          FadeSlideIn(delay: 400, child: SectionHeader(title: AppLocalizations.of(context).translate('health_history'))),
          FadeSlideIn(delay: 420, child: _healthRecords.isEmpty
              ? AppCard(child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.textTertiary, size: 18), const SizedBox(width: 8),
                  Expanded(child: Text(AppLocalizations.of(context).translate('no_health_records'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))),
                ]))
              : Column(children: _healthRecords.map((r) {
                  final files = r['files'] as List? ?? [];
                  final date = r['created_at'] != null ? DateTime.tryParse(r['created_at']) : null;
                  final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '';
                  return Padding(padding: const EdgeInsets.only(bottom: 8), child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.medical_information_rounded, color: AppColors.error, size: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ])),
                    ]),
                    if (r['notes'] != null && r['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(r['notes'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                    if (files.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(height: 64, child: ListView.separated(
                        scrollDirection: Axis.horizontal, itemCount: files.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, fi) {
                          try {
                            final bytes = base64Decode(files[fi]['file_data']);
                            return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(bytes, width: 64, height: 64, fit: BoxFit.cover));
                          } catch (_) {
                            return Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.broken_image_rounded, color: AppColors.textTertiary, size: 20));
                          }
                        },
                      )),
                    ],
                  ])));
                }).toList())),

          // ─── Coach Notes (bi-weekly) ───────────────────────
          const SizedBox(height: 8),
          FadeSlideIn(delay: 500, child: SectionHeader(
            title: AppLocalizations.of(context).translate('coach_notes'),
            trailing: TextButton.icon(
              onPressed: _addCoachNote,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(AppLocalizations.of(context).translate('add_note')),
            ),
          )),
          FadeSlideIn(delay: 520, child: _coachNotes.isEmpty
              ? AppCard(child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.textTertiary, size: 18), const SizedBox(width: 8),
                  Expanded(child: Text(AppLocalizations.of(context).translate('no_coach_notes'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))),
                ]))
              : Column(children: _coachNotes.map((n) {
                  return Padding(padding: const EdgeInsets.only(bottom: 8), child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.note_alt_rounded, color: AppColors.accent, size: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (n['period_label'] != null) Text(n['period_label'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
                        Text(n['coach_name'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ])),
                    ]),
                    const SizedBox(height: 8),
                    Text(n['note'] ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                  ])));
                }).toList())),
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
    for (int i = 0; i < startWeekday; i++) { cells.add(const SizedBox()); }
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
