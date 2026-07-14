import 'package:flutter/material.dart';
import '../../services/offline/offline_repository.dart';
import '../../services/offline/connectivity_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class AthleteGearScreen extends StatefulWidget {
  const AthleteGearScreen({super.key});
  @override
  State<AthleteGearScreen> createState() => AthleteGearScreenState();
}

class AthleteGearScreenState extends State<AthleteGearScreen> {
  String? gearMessage;
  bool loading = true;
  bool _fetched = false;

  @override
  void initState() { super.initState(); _fetchGear(); }

  void silentRefresh() { if (_fetched) _fetchGear(silent: true); }

  Future<void> _fetchGear({bool silent = false}) async {
    try {
      // Instant cache reads — show data before any network round-trip
      final cachedMe = OfflineRepository.getCached('/users/me');
      final cachedBranchId = cachedMe is Map ? cachedMe['branch_id'] : null;
      if (cachedBranchId != null) {
        final cachedGear = OfflineRepository.getCached('/gear/$cachedBranchId');
        if (cachedGear is Map) {
          gearMessage = cachedGear['message']?.toString();
          if (mounted) setState(() => loading = false);
        }
      }

      // Cache-first fetch with background refresh
      final me = await OfflineRepository.getUserMe();
      final branchId = me['branch_id'];
      if (branchId != null) {
        final gear = await OfflineRepository.getGear(branchId, onFresh: (d) {
          if (mounted && d is Map) setState(() => gearMessage = d['message']?.toString());
        });
        gearMessage = gear['message']?.toString();
      }
      _fetched = true;
    } catch (_) {}
    finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlideIn(
            child: HeroHeader(
              title: l.translate('gear_update'),
              subtitle: l.translate('gear_subtitle'),
              trailing: const HeaderIconButton(icon: Icons.backpack_rounded),
            ),
          ),
          Expanded(
            child: loading
                ? const ShimmerList(count: 3)
                : (gearMessage == null || gearMessage!.isEmpty)
                    ? (!ConnectivityService.isOnline
                        ? EmptyState(
                            icon: Icons.cloud_off_rounded,
                            title: l.translate('no_connection'),
                            message: l.translate('no_connection_data'),
                          )
                        : EmptyState(
                            icon: Icons.backpack_outlined,
                            title: l.translate('gear_update'),
                            message: l.translate('no_gear_posted'),
                          ))
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeSlideIn(delay: 50, child: SectionHeader(title: l.translate('gear_check'))),
                            FadeSlideIn(
                              delay: 100,
                              child: AppCard(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const IconBadge(icon: Icons.backpack_rounded, color: AppColors.warning),
                                    const SizedBox(width: AppSpacing.lg),
                                    Expanded(child: Text(gearMessage!, style: AppTypography.bodyLarge)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
