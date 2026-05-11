import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<dynamic> records = [];
  List<String> sessionDates = [];
  bool loading = true;
  String search = '';

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    final auth = context.read<AuthProvider>();
    final branchId = auth.branchId;
    try {
      final res = await ApiService().get('/payments/summary/$branchId');
      records = res.data['records'] ?? [];
      sessionDates = List<String>.from(res.data['session_dates'] ?? []);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load payment summary.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _markPayment(int athleteId, String date, String status) async {
    try {
      await ApiService().post('/payments/mark', data: {'athlete_id': athleteId, 'session_date': date, 'status': status});
      _fetchSummary();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update payment status.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF007AFF))));

    final sorted = List.from(records)..sort((a, b) => (a['athlete_name'] as String).compareTo(b['athlete_name']));
    final filtered = sorted.where((r) => (r['athlete_name'] as String).toLowerCase().contains(search.toLowerCase())).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF007AFF), size: 26), onPressed: () => context.go('/coach/home')),
              const SizedBox(height: 10),
              const Text('\u{1F4B5} Payment Tracking', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                onChanged: (v) => setState(() => search = v),
                decoration: InputDecoration(
                  hintText: 'Search athlete...',
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No athletes found.', style: TextStyle(color: Color(0xFF999999))))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['athlete_name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                  const SizedBox(height: 8),
                                  ...sessionDates.map((date) {
                                    final currentStatus = (item['statuses'] ?? {})[date] ?? 'pending';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(date, style: const TextStyle(fontSize: 14, color: Color(0xFF555555))),
                                          Row(
                                            children: ['paid', 'pending', 'late'].map((status) {
                                              final isActive = currentStatus == status;
                                              return Padding(
                                                padding: const EdgeInsets.only(left: 6),
                                                child: GestureDetector(
                                                  onTap: () => _markPayment(item['athlete_id'], date, status),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    constraints: const BoxConstraints(minWidth: 40),
                                                    decoration: BoxDecoration(
                                                      color: isActive ? const Color(0xFF007AFF) : const Color(0xFFEEEEEE),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Center(child: Text(status[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
