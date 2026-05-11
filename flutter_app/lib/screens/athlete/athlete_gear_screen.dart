import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../services/api_service.dart';

class AthleteGearScreen extends StatefulWidget {
  const AthleteGearScreen({super.key});
  @override
  State<AthleteGearScreen> createState() => _AthleteGearScreenState();
}

class _AthleteGearScreenState extends State<AthleteGearScreen> {
  String? gearMessage;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchGear();
  }

  Future<void> _fetchGear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored == null) throw Exception('No stored user');
      final user = jsonDecode(stored);
      final headers = {'Authorization': 'Bearer ${user['token']}'};
      final dio = Dio();

      final userRes = await dio.get('${ApiService.baseUrl}/users/me', options: Options(headers: headers));
      final branchId = userRes.data['branch_id'];
      if (branchId == null) throw Exception('Branch ID missing');

      final res = await dio.get('${ApiService.baseUrl}/gear/$branchId', options: Options(headers: headers));
      gearMessage = res.data?['message'] ?? 'No gear updates posted yet.';
    } catch (e) {
      gearMessage = 'Error loading gear information.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE6F2FF),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: Color(0xFF3399FF)),
            SizedBox(height: 10),
            Text('Loading gear info...', style: TextStyle(color: Color(0xFF1A73E8))),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE6F2FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFF3399FF), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))]),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('\u{1F392} Gear Update', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0E7FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA4D3FF)),
                  ),
                  child: Text(gearMessage ?? '', style: const TextStyle(fontSize: 16, color: Color(0xFF003366), height: 1.38, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
