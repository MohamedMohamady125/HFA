import 'package:flutter/material.dart';
import '../../services/api_service.dart';
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
      final api = ApiService();
      final me = await api.get('/users/me');
      final res = await api.get('/gear/${me.data['branch_id']}');
      gearMessage = res.data?['message'];
      _fetched = true;
    } catch (_) { gearMessage = null; }
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
                    ? EmptyState(
                        icon: Icons.backpack_outlined,
                        title: l.translate('gear_update'),
                        message: l.translate('no_gear_posted'),
                      )
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
