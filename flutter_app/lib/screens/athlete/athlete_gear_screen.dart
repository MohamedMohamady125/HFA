import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

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
      final prefs = await SharedPreferences.getInstance();
      final user = jsonDecode(prefs.getString('authUser')!);
      final headers = {'Authorization': 'Bearer ${user['token']}'};
      final dio = Dio();
      final base = ApiService.baseUrl;
      final me = await dio.get('$base/users/me', options: Options(headers: headers));
      final res = await dio.get('$base/gear/${me.data['branch_id']}', options: Options(headers: headers));
      gearMessage = res.data?['message'] ?? 'No gear updates posted yet.';
    } catch (_) { gearMessage = 'Error loading gear information.'; }
    finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const AppLoadingScreen(message: 'Loading gear...');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Gear Update', subtitle: 'Latest gear requirements from your coach'),
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
