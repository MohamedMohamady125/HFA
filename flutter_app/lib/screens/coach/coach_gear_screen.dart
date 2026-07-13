import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/offline/offline_repository.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class CoachGearScreen extends StatefulWidget {
  const CoachGearScreen({super.key});
  @override
  State<CoachGearScreen> createState() => CoachGearScreenState();
}

class CoachGearScreenState extends State<CoachGearScreen> with SingleTickerProviderStateMixin {
  int? branchId;
  String branchName = '';
  final _msgCtrl = TextEditingController();
  bool loading = true, submitting = false;
  bool _saved = false;
  late AnimationController _checkAnim;

  void silentRefresh() { _loadData(); }

  @override
  void initState() {
    super.initState();
    _checkAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    // Sync cache
    final cachedMe = OfflineRepository.getCached('/users/me');
    if (cachedMe is Map && cachedMe['branch_id'] != null) {
      branchId = cachedMe['branch_id'];
      final cachedBranch = OfflineRepository.getCached('/branches/$branchId');
      if (cachedBranch is Map) branchName = cachedBranch['name']?.toString() ?? '';
      final cachedGear = OfflineRepository.getCached('/gear/$branchId');
      if (cachedGear is Map && cachedGear['message'] != null) _msgCtrl.text = cachedGear['message'];
      if (branchName.isNotEmpty) loading = false;
    }
    _loadData();
  }

  @override
  void dispose() { _msgCtrl.dispose(); _checkAnim.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    try {
      final u = await OfflineRepository.getUserMe(); branchId = u['branch_id'];
      final results = await Future.wait([OfflineRepository.cachedGet('/branches/$branchId'), OfflineRepository.getGear(branchId!)]);
      branchName = results[0]['name'] ?? '';
      if (results[1]?['message'] != null) _msgCtrl.text = results[1]['message'];
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _handlePost() async {
    if (_msgCtrl.text.isEmpty || branchId == null) return;
    setState(() { submitting = true; _saved = false; });
    try {
      await OfflineRepository.postGear(branchId!, _msgCtrl.text);
      setState(() => _saved = true);
      _checkAnim.forward(from: 0);
      Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _saved = false); });
    } catch (_) {
      if (mounted) { final l = AppLocalizations.of(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.translate('gear_failed')), backgroundColor: AppColors.error)); }
    } finally { if (mounted) setState(() => submitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (loading) return const Scaffold(body: ShimmerList(count: 2));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            FadeSlideIn(
              child: HeroHeader(
                title: l.translate('weekly_gear_update'),
                subtitle: '${l.translate('branch_label')}: $branchName',
                trailing: const HeaderIconButton(icon: Icons.backpack_rounded),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 30),
                child: FadeSlideIn(delay: 100, child: AppCard(
                  child: Column(children: [
                    TextField(
                      controller: _msgCtrl, maxLines: 8,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.textPrimary),
                      decoration: InputDecoration(hintText: l.translate('enter_gear'), border: InputBorder.none, fillColor: Colors.transparent),
                    ),
                    const AppDivider(),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _saved
                            ? ScaleTransition(
                                scale: CurvedAnimation(parent: _checkAnim, curve: Curves.elasticOut),
                                child: Container(
                                  key: const ValueKey('saved'),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(AppRadius.md)),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                                    const SizedBox(width: 8),
                                    Text(l.translate('gear_saved'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.success)),
                                  ]),
                                ),
                              )
                            : PrimaryButton(
                                key: const ValueKey('btn'),
                                label: l.translate('save_gear'),
                                icon: Icons.save_rounded,
                                loading: submitting,
                                onPressed: submitting || _msgCtrl.text.isEmpty ? null : _handlePost,
                              ),
                      ),
                    ),
                  ]),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
