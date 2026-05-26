import 'package:flutter/material.dart';
import '../../services/api_service.dart';
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(child: SectionHeader(title: l.translate('weekly_gear_update'), subtitle: 'Branch: $branchName')),
              const SizedBox(height: 8),
              FadeSlideIn(delay: 100, child: AppCard(
                child: Column(children: [
                  TextField(
                    controller: _msgCtrl, maxLines: 8,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                    decoration: InputDecoration(hintText: l.translate('enter_gear'), border: InputBorder.none, fillColor: Colors.transparent),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _saved
                          ? ScaleTransition(
                              scale: CurvedAnimation(parent: _checkAnim, curve: Curves.elasticOut),
                              child: Container(
                                key: const ValueKey('saved'),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                                  const SizedBox(width: 8),
                                  Text(l.translate('gear_saved'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.success)),
                                ]),
                              ),
                            )
                          : ElevatedButton(
                              key: const ValueKey('btn'),
                              onPressed: submitting || _msgCtrl.text.isEmpty ? null : _handlePost,
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: submitting
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : Text(l.translate('save_gear')),
                            ),
                    ),
                  ),
                ]),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
