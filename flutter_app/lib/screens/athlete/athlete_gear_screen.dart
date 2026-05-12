import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class AthleteGearScreen extends StatefulWidget {
  const AthleteGearScreen({super.key});
  @override
  State<AthleteGearScreen> createState() => _AthleteGearScreenState();
}

class _AthleteGearScreenState extends State<AthleteGearScreen> {
  String? gearMessage;
  bool loading = true;

  @override
  void initState() { super.initState(); _fetchGear(); }

  Future<void> _fetchGear() async {
    try {
      final api = ApiService();
      final me = await api.get('/users/me');
      final res = await api.get('/gear/${me.data['branch_id']}');
      gearMessage = res.data?['message'] ?? 'No gear updates posted yet.';
    } catch (_) { gearMessage = 'Error loading gear information.'; }
    finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (loading) return AppLoadingScreen(message: l.translate('loading_gear'));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: l.translate('gear_update'), subtitle: l.translate('gear_subtitle')),
              const SizedBox(height: 8),
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.backpack_rounded, color: AppColors.warning),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(gearMessage ?? '', style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
