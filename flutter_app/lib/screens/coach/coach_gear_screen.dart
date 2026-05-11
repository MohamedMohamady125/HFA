import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CoachGearScreen extends StatefulWidget {
  const CoachGearScreen({super.key});
  @override
  State<CoachGearScreen> createState() => _CoachGearScreenState();
}

class _CoachGearScreenState extends State<CoachGearScreen> {
  int? branchId;
  String branchName = '';
  final _messageController = TextEditingController();
  bool loading = true;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = ApiService();
      final userRes = await api.get('/users/me');
      branchId = userRes.data['branch_id'];

      final branchRes = await api.get('/branches/$branchId');
      branchName = branchRes.data['name'] ?? '';

      final gearRes = await api.get('/gear/$branchId');
      if (gearRes.data?['message'] != null) {
        _messageController.text = gearRes.data['message'];
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load gear or branch info.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _handlePost() async {
    if (_messageController.text.isEmpty || branchId == null) return;
    setState(() => submitting = true);
    try {
      await ApiService().post('/gear/$branchId', data: {'content': _messageController.text});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gear info has been saved.'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to post gear.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF007AFF))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeAreaScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text('\u{1F9E2} Weekly Gear Update', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
            const SizedBox(height: 10),
            Center(child: RichText(text: TextSpan(style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)), children: [
              const TextSpan(text: 'Branch: '),
              TextSpan(text: branchName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]))),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Enter or edit gear info...',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitting || _messageController.text.isEmpty ? null : _handlePost,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text(submitting ? 'Saving...' : 'Save Gear Info'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class SafeAreaScrollView extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;
  const SafeAreaScrollView({super.key, required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: SingleChildScrollView(padding: padding, child: child));
  }
}
