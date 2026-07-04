import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});
  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  List<dynamic> branches = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() { loading = true; error = null; });
    try {
      final res = await ApiService().get('/branches/');
      branches = res.data is List ? res.data : [];
    } catch (_) {
      error = 'failed_load_branches';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: Text(l.translate('our_branches')),
      ),
      body: loading
          ? const ShimmerList(count: 4)
          : error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text(l.translate(error!), style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _fetchBranches, child: Text(l.translate('loading'))),
                ]))
              : RefreshIndicator(
                  onRefresh: _fetchBranches,
                  color: AppColors.accent,
                  child: branches.isEmpty
                      ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                          const SizedBox(height: 100),
                          Center(child: Icon(Icons.location_city_rounded, size: 56, color: AppColors.textTertiary.withValues(alpha: 0.4))),
                          const SizedBox(height: 16),
                          Center(child: Text(l.translate('no_branches_found'), style: const TextStyle(color: AppColors.textSecondary))),
                        ])
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          itemCount: branches.length + 1, // +1 for CTA card at bottom
                          itemBuilder: (_, i) {
                            if (i == branches.length) return _ctaCard(l);
                            return _branchCard(branches[i], i, l);
                          },
                        ),
                ),
    );
  }

  Widget _branchCard(dynamic branch, int index, AppLocalizations l) {
    final name = branch['name']?.toString() ?? '';
    final address = branch['address']?.toString() ?? '';
    final phone = branch['phone']?.toString() ?? '';
    final videoUrl = branch['video_url']?.toString() ?? '';
    final practiceDays = branch['practice_days']?.toString() ?? '';

    return FadeSlideIn(
      delay: index * 60,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.location_city_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(address, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                    ]),
                  ],
                ])),
              ]),

              // Practice schedule
              if (practiceDays.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.schedule_rounded, size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(l.translate('practice_schedule'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
                    ]),
                    const SizedBox(height: 8),
                    ...practiceDays.split(',').map((line) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(children: [
                        Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(line.trim(), style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3))),
                      ]),
                    )),
                  ]),
                ),
              ],

              // Phone
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 10),
                ScaleOnTap(
                  onTap: () => _callPhone(phone),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.phone_rounded, size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(phone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
                    ]),
                  ),
                ),
              ],

              // Video link
              if (videoUrl.isNotEmpty) ...[
                const SizedBox(height: 10),
                ScaleOnTap(
                  onTap: () => _openUrl(videoUrl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.play_circle_rounded, size: 20, color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.translate('branch_tour'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.info)),
                        const SizedBox(height: 2),
                        Text(l.translate('watch_video'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ])),
                      const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.info),
                    ]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _ctaCard(AppLocalizations l) {
    return FadeSlideIn(
      delay: branches.length * 60,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        child: AppCard(
          child: Column(children: [
            const SizedBox(height: 4),
            Text(l.translate('ready_to_join'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => context.push('/login'),
              child: Text(l.translate('login')),
            )),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: () => context.push('/register'),
              child: Text(l.translate('register')),
            )),
            const SizedBox(height: 4),
          ]),
        ),
      ),
    );
  }
}
