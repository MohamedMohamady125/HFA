import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/offline/connectivity_service.dart';
import '../../services/offline/offline_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/web_video_embed.dart';
import '../../l10n/app_localizations.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});
  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  List<dynamic> branches = [];
  bool loading = true;
  bool offlineNoData = false;

  /// Lazily-created inline video controllers, keyed by branch index.
  final Map<int, WebViewController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    // Cache-first: show cached branches instantly (works offline once visited).
    final cached = OfflineRepository.getCached('branches_public_list');
    if (cached is List) {
      branches = cached;
      loading = false;
    }
    _fetchBranches();
  }

  void _applyBranches(List fresh) {
    // Only reset video controllers when the list actually changed, so an
    // in-progress inline video isn't reloaded by a silent background refresh.
    if (fresh.length != branches.length) _videoControllers.clear();
    branches = fresh;
  }

  Future<void> _fetchBranches() async {
    if (branches.isEmpty && mounted) {
      setState(() { loading = true; offlineNoData = false; });
    }
    final data = await OfflineRepository.getPublicBranches(onFresh: (fresh) {
      if (mounted && fresh is List) setState(() => _applyBranches(fresh));
    });
    if (!mounted) return;
    setState(() {
      if (data.isNotEmpty) _applyBranches(data);
      loading = false;
      offlineNoData = branches.isEmpty && !ConnectivityService.isOnline;
    });
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

  Future<void> _openWhatsApp(String number) async {
    var digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    // All numbers are Egyptian — normalize to the +20 international format.
    if (digits.startsWith('0')) {
      digits = '2$digits'; // 010... -> 2010...
    } else if (digits.startsWith('1') && digits.length == 10) {
      digits = '20$digits'; // 10... -> 2010...
    }
    final uri = Uri.parse('https://wa.me/$digits');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Converts a YouTube URL (watch / youtu.be / shorts) into an embed URL.
  /// Returns null for non-YouTube links.
  String? _youtubeEmbedUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase().replaceFirst('www.', '');
    String? id;
    if (host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
      id = uri.pathSegments.first;
    } else if (host == 'youtube.com' || host == 'm.youtube.com') {
      if (uri.path == '/watch') {
        id = uri.queryParameters['v'];
      } else if (uri.pathSegments.length >= 2 &&
          (uri.pathSegments.first == 'shorts' || uri.pathSegments.first == 'embed')) {
        id = uri.pathSegments[1];
      }
    }
    if (id == null || id.isEmpty) return null;
    return 'https://www.youtube.com/embed/$id';
  }

  WebViewController _videoController(int index, String embedUrl) {
    return _videoControllers.putIfAbsent(index, () {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.primaryDark)
        ..loadRequest(Uri.parse(embedUrl));
      return controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          HeroHeader(
            title: l.translate('our_branches'),
            subtitle: l.translate('branch_count'),
            leading: HeaderIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.pop(),
            ),
          ),
          Expanded(
            child: loading
                ? const ShimmerList(count: 4)
                : offlineNoData
                    ? EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: l.translate('failed_load_branches'),
                        message: l.translate('offline_branches'),
                        actionLabel: l.translate('retry'),
                        onAction: _fetchBranches,
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchBranches,
                        color: AppColors.accent,
                        child: branches.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 80),
                                  EmptyState(
                                    icon: Icons.location_city_rounded,
                                    title: l.translate('no_branches_found'),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
                                itemCount: branches.length + 1, // +1 for CTA card at bottom
                                itemBuilder: (_, i) {
                                  if (i == branches.length) return _ctaCard(l);
                                  return _branchCard(branches[i], i, l);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _branchCard(dynamic branch, int index, AppLocalizations l) {
    final name = branch['name']?.toString() ?? '';
    final address = branch['address']?.toString() ?? '';
    final phone = branch['phone']?.toString() ?? '';
    final whatsapp = branch['whatsapp']?.toString() ?? '';
    final videoUrl = branch['video_url']?.toString() ?? '';
    final practiceDays = branch['practice_days']?.toString() ?? '';

    return FadeSlideIn(
      delay: index * 50,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              const IconBadge(icon: Icons.location_on_rounded, color: AppColors.accent, size: 48, radius: 14),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: AppTypography.titleLarge),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(address, style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
                ],
              ])),
            ]),

            // Practice schedule
            if (practiceDays.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.schedule_rounded, size: 16, color: AppColors.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l.translate('practice_schedule'), style: AppTypography.label.copyWith(color: AppColors.accent)),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  ...practiceDays.split(',').map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(children: [
                      Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(line.trim(), style: AppTypography.bodyLarge.copyWith(fontSize: 13, height: 1.3))),
                    ]),
                  )),
                ]),
              ),
            ],

            // Contact — phone call + WhatsApp
            if (phone.isNotEmpty || whatsapp.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                if (phone.isNotEmpty)
                  Expanded(child: _contactButton(
                    icon: Icons.phone_rounded,
                    label: phone,
                    onTap: () => _callPhone(phone),
                  )),
                if (phone.isNotEmpty && whatsapp.isNotEmpty)
                  const SizedBox(width: AppSpacing.sm),
                if (whatsapp.isNotEmpty)
                  Expanded(child: _contactButton(
                    icon: Icons.chat_rounded,
                    label: l.translate('whatsapp'),
                    onTap: () => _openWhatsApp(whatsapp),
                  )),
              ]),
            ],

            // Video — embedded player for YouTube links, external tile otherwise
            if (videoUrl.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _videoSection(videoUrl, index, l),
            ],
          ],
        ),
      ),
    );
  }

  Widget _contactButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(fontSize: 14, color: AppColors.success),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _videoSection(String videoUrl, int index, AppLocalizations l) {
    final embedUrl = _youtubeEmbedUrl(videoUrl);
    if (embedUrl == null) {
      // Non-YouTube link — open externally.
      return ScaleOnTap(
        onTap: () => _openUrl(videoUrl),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Row(children: [
            const Icon(Icons.play_circle_rounded, size: 20, color: AppColors.info),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.translate('branch_tour'), style: AppTypography.label.copyWith(color: AppColors.info)),
              const SizedBox(height: 2),
              Text(l.translate('watch_video'), style: AppTypography.caption),
            ])),
            const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.info),
          ]),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.play_circle_rounded, size: 16, color: AppColors.info),
        const SizedBox(width: AppSpacing.sm),
        Text(l.translate('branch_tour'), style: AppTypography.label.copyWith(color: AppColors.info)),
      ]),
      const SizedBox(height: AppSpacing.sm),
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: kIsWeb
              ? buildWebVideoEmbed(embedUrl)
              : WebViewWidget(controller: _videoController(index, embedUrl)),
        ),
      ),
    ]);
  }

  Widget _ctaCard(AppLocalizations l) {
    return FadeSlideIn(
      delay: branches.length * 50,
      child: AppCard(
        margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xl),
        child: Column(children: [
          const SizedBox(height: AppSpacing.xs),
          Text(l.translate('ready_to_join'), style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: l.translate('login'),
            onPressed: () => context.push('/login'),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: () => context.push('/register'),
            child: Text(l.translate('register')),
          )),
          const SizedBox(height: AppSpacing.xs),
        ]),
      ),
    );
  }
}
