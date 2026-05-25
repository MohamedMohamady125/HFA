import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../services/offline/offline_repository.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class RegisterRequestsScreen extends StatefulWidget {
  const RegisterRequestsScreen({super.key});
  @override
  State<RegisterRequestsScreen> createState() => _RegisterRequestsScreenState();
}

class _RegisterRequestsScreenState extends State<RegisterRequestsScreen> {
  List<dynamic> requests = [];
  bool loading = true;
  final _listKey = GlobalKey<AnimatedListState>();
  // Track cards being processed so we can show spinners
  final Set<int> _processing = {};

  @override
  void initState() { super.initState(); _fetchRequests(); }

  Future<void> _fetchRequests() async {
    setState(() => loading = true);
    try {
      final data = await OfflineRepository.getRequests();
      requests = data;
    } catch (_) {}
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _approve(int id, int index) async {
    setState(() => _processing.add(id));
    try {
      await ApiService().post('/users/approve/$id');
      _removeItem(index, AppColors.success);
    } catch (_) {
      _msg('Failed to approve', error: true);
      setState(() => _processing.remove(id));
    }
  }

  Future<void> _reject(int id, int index) async {
    final l = AppLocalizations.of(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        decoration: const BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.warning_rounded, color: AppColors.error, size: 28)),
          const SizedBox(height: 16),
          Text(l.translate('reject_confirm'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(l.translate('reject_desc'), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.translate('cancel')))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(l.translate('reject')),
            )),
          ]),
        ]),
      ),
    );
    if (ok != true) return;

    setState(() => _processing.add(id));
    try {
      await ApiService().post('/users/reject/$id');
      _removeItem(index, AppColors.error);
    } catch (_) {
      _msg('Failed to reject', error: true);
      setState(() => _processing.remove(id));
    }
  }

  void _removeItem(int index, Color color) {
    if (index >= requests.length) return;
    final removed = requests[index];
    requests.removeAt(index);
    _processing.remove(removed['id']);

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildDismissedCard(removed, animation, color),
      duration: const Duration(milliseconds: 400),
    );

    // Show success feedback
    final isApprove = color == AppColors.success;
    final l = AppLocalizations.of(context);
    _msg(isApprove ? l.translate('athlete_approved') : l.translate('request_rejected'));

    // If list is now empty, rebuild to show empty state
    if (requests.isEmpty) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) setState(() {});
      });
    }
  }

  Widget _buildDismissedCard(dynamic req, Animation<double> animation, Color color) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(color == AppColors.success ? 1.0 : -1.0, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(color == AppColors.success ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 32),
                const SizedBox(width: 12),
                Text(
                  color == AppColors.success ? 'Approved!' : 'Rejected',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _msg(String msg, {bool error = false}) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: error ? AppColors.error : AppColors.success, behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (loading) return const Scaffold(body: ShimmerList(count: 4));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.translate('pending_requests')),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/coach/home')),
        actions: [
          if (requests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('${requests.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
              )),
            ),
        ],
      ),
      body: requests.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.surfaceLight, shape: BoxShape.circle),
                child: const Icon(Icons.how_to_reg_rounded, size: 40, color: AppColors.textTertiary)),
              const SizedBox(height: 20),
              Text(l.translate('no_requests'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              const Text('All caught up!', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
            ]))
          : AnimatedList(
              key: _listKey,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              initialItemCount: requests.length,
              itemBuilder: (context, index, animation) {
                if (index >= requests.length) return const SizedBox();
                final req = requests[index];
                final isProcessing = _processing.contains(req['id']);

                return FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isProcessing ? 0.5 : 1.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row
                              Row(children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.7)]),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(child: Text(
                                    (req['athlete_name'] ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                                  )),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(req['athlete_name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(req['email'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                ])),
                              ]),

                              // Details
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10)),
                                child: Row(children: [
                                  if (req['phone'] != null) ...[
                                    const Icon(Icons.phone_rounded, size: 14, color: AppColors.textTertiary),
                                    const SizedBox(width: 6),
                                    Text(req['phone'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  ],
                                  if (req['branch_name'] != null) ...[
                                    if (req['phone'] != null) const SizedBox(width: 16),
                                    const Icon(Icons.location_city_rounded, size: 14, color: AppColors.accent),
                                    const SizedBox(width: 6),
                                    Text(req['branch_name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                  ],
                                ]),
                              ),

                              // Action buttons
                              const SizedBox(height: 14),
                              if (isProcessing)
                                const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accent)))
                              else
                                Row(children: [
                                  Expanded(child: _actionButton(
                                    icon: Icons.close_rounded,
                                    label: l.translate('reject'),
                                    color: AppColors.error,
                                    filled: false,
                                    onTap: () => _reject(req['id'], index),
                                  )),
                                  const SizedBox(width: 12),
                                  Expanded(child: _actionButton(
                                    icon: Icons.check_rounded,
                                    label: l.translate('approve'),
                                    color: AppColors.success,
                                    filled: true,
                                    onTap: () => _approve(req['id'], index),
                                  )),
                                ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required Color color, required bool filled, required VoidCallback onTap}) {
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: filled ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: filled ? Colors.white : color)),
          ]),
        ),
      ),
    );
  }
}
