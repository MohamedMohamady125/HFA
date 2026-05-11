import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CoachGearScreen extends StatefulWidget {
  const CoachGearScreen({super.key});
  @override
  State<CoachGearScreen> createState() => _CoachGearScreenState();
}

class _CoachGearScreenState extends State<CoachGearScreen> {
  int? branchId;
  String branchName = '';
  final _msgCtrl = TextEditingController();
  bool loading = true, submitting = false;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    try {
      final api = ApiService();
      final u = await api.get('/users/me'); branchId = u.data['branch_id'];
      final b = await api.get('/branches/$branchId'); branchName = b.data['name'] ?? '';
      final g = await api.get('/gear/$branchId'); if (g.data?['message'] != null) _msgCtrl.text = g.data['message'];
    } catch (_) {} finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _handlePost() async {
    if (_msgCtrl.text.isEmpty || branchId == null) return;
    setState(() => submitting = true);
    try {
      await ApiService().post('/gear/$branchId', data: {'content': _msgCtrl.text});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gear info saved!'), backgroundColor: AppColors.success));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to post gear.'), backgroundColor: AppColors.error));
    } finally { if (mounted) setState(() => submitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const AppLoadingScreen();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'Gear Update', subtitle: 'Branch: $branchName'),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _msgCtrl, maxLines: 8,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                      decoration: const InputDecoration(hintText: 'Enter gear requirements for your athletes...', border: InputBorder.none, fillColor: Colors.transparent),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting || _msgCtrl.text.isEmpty ? null : _handlePost,
                        child: Text(submitting ? 'Saving...' : 'Save Gear Info'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }
}
