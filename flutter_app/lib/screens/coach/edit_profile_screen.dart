import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/offline/offline_repository.dart';
import '../../widgets/app_feedback.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl, _emailCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.userName ?? '');
    _emailCtrl = TextEditingController(text: auth.userEmail ?? '');
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      final r = await OfflineRepository.updateCoachProfile({'name': _nameCtrl.text, 'email': _emailCtrl.text});
      if (!mounted) return;
      if (r.synced) {
        // Refresh only when the server actually accepted the change.
        try { await context.read<AuthProvider>().refreshUser(); } catch (_) {}
      }
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      AppFeedback.showWriteResult(context, r, successMessage: l.translate('profile_updated'));
      context.pop();
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(l.translate('edit_profile')), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 30),
        child: Column(
          children: [
            FadeSlideIn(child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: GradientAvatar(name: auth.userName ?? 'C', size: 80),
              ),
            )),
            FadeSlideIn(delay: 50, child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppFormField(label: l.translate('name'), controller: _nameCtrl, prefixIcon: Icons.person_outline_rounded),
                  AppFormField(label: l.translate('email'), controller: _emailCtrl, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined),
                ],
              ),
            )),
            const SizedBox(height: AppSpacing.lg),
            FadeSlideIn(delay: 100, child: PrimaryButton(
              label: l.translate('save_changes'),
              icon: Icons.check_rounded,
              loading: _saving,
              onPressed: _saving ? null : _handleSave,
            )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }
}
