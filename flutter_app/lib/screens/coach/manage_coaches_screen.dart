import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ManageCoachesScreen extends StatefulWidget {
  const ManageCoachesScreen({super.key});
  @override
  State<ManageCoachesScreen> createState() => _ManageCoachesScreenState();
}

class _ManageCoachesScreenState extends State<ManageCoachesScreen> {
  List<dynamic> coaches = [];
  List<dynamic> branches = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        ApiService().get('/head-coach/coaches'),
        ApiService().get('/head-coach/branches'),
      ]);
      coaches = results[0].data;
      branches = results[1].data;
    } catch (_) {
      if (mounted) _showError('Failed to load data');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.success));

  Future<void> _deleteCoach(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Coach'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService().delete('/head-coach/coaches/$id');
      _showSuccess('Coach deleted');
      _loadData();
    } catch (_) {
      _showError('Failed to delete coach');
    }
  }

  Future<void> _showCreateDialog() async {
    if (branches.isEmpty) { _showError('No branches available'); return; }
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    int selectedBranch = branches.first['id'];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Coach', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField('Name', nameCtrl),
                _dialogField('Email', emailCtrl, type: TextInputType.emailAddress),
                _dialogField('Phone', phoneCtrl, type: TextInputType.phone),
                _dialogField('Password', passCtrl, obscure: true),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedBranch,
                  decoration: const InputDecoration(labelText: 'Branch'),
                  items: branches.map<DropdownMenuItem<int>>((b) =>
                    DropdownMenuItem(value: b['id'] as int, child: Text(b['name'] ?? ''))).toList(),
                  onChanged: (v) { if (v != null) setDialogState(() => selectedBranch = v); },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      ),
    );

    if (result != true) return;
    if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
      _showError('Name, email, and password are required');
      return;
    }

    try {
      await ApiService().post('/head-coach/coaches', data: {
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'password': passCtrl.text.trim(),
        'branch_id': selectedBranch,
      });
      _showSuccess('Coach created');
      _loadData();
    } catch (e) {
      final msg = _extractError(e, 'Failed to create coach');
      _showError(msg);
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> coach) async {
    final nameCtrl = TextEditingController(text: coach['name'] ?? '');
    final emailCtrl = TextEditingController(text: coach['email'] ?? '');
    final phoneCtrl = TextEditingController(text: coach['phone'] ?? '');
    int selectedBranch = coach['branch_id'] ?? (branches.isNotEmpty ? branches.first['id'] : 0);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Coach', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField('Name', nameCtrl),
                _dialogField('Email', emailCtrl, type: TextInputType.emailAddress),
                _dialogField('Phone', phoneCtrl, type: TextInputType.phone),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: branches.any((b) => b['id'] == selectedBranch) ? selectedBranch : null,
                  decoration: const InputDecoration(labelText: 'Branch'),
                  items: branches.map<DropdownMenuItem<int>>((b) =>
                    DropdownMenuItem(value: b['id'] as int, child: Text(b['name'] ?? ''))).toList(),
                  onChanged: (v) { if (v != null) setDialogState(() => selectedBranch = v); },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (result != true) return;
    try {
      await ApiService().put('/head-coach/coaches/${coach['id']}', data: {
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'branch_id': selectedBranch,
      });
      _showSuccess('Coach updated');
      _loadData();
    } catch (e) {
      _showError(_extractError(e, 'Failed to update coach'));
    }
  }

  Future<void> _showResetPasswordDialog(Map<String, dynamic> coach) async {
    final passCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password for ${coach['name']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: _dialogField('New Password', passCtrl, obscure: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (result != true || passCtrl.text.trim().isEmpty) return;
    try {
      await ApiService().post('/head-coach/coaches/${coach['id']}/reset-password', data: {'new_password': passCtrl.text.trim()});
      _showSuccess('Password reset');
    } catch (_) {
      _showError('Failed to reset password');
    }
  }

  Widget _dialogField(String label, TextEditingController ctrl, {TextInputType? type, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label, hintText: 'Enter ${label.toLowerCase()}'),
      ),
    );
  }

  String _extractError(dynamic e, String fallback) {
    if (e is Exception) {
      try {
        final dynamic dioErr = e;
        return dioErr.response?.data?['detail']?.toString() ?? fallback;
      } catch (_) {}
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const AppLoadingScreen(message: 'Loading coaches...');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/head-coach-branches'),
        ),
        title: const Text('Manage Coaches'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Coach'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: coaches.isEmpty
            ? ListView(children: const [
                SizedBox(height: 120),
                Center(child: Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textTertiary)),
                SizedBox(height: 16),
                Center(child: Text('No coaches yet', style: TextStyle(fontSize: 16, color: AppColors.textSecondary))),
                Center(child: Text('Tap + to add one', style: TextStyle(fontSize: 14, color: AppColors.textTertiary))),
              ])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: coaches.length,
                itemBuilder: (_, i) {
                  final c = Map<String, dynamic>.from(coaches[i]);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    (c['name'] ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(c['email'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (action) {
                                  switch (action) {
                                    case 'edit': _showEditDialog(c);
                                    case 'password': _showResetPasswordDialog(c);
                                    case 'delete': _deleteCoach(c['id'], c['name'] ?? 'this coach');
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit')])),
                                  const PopupMenuItem(value: 'password', child: Row(children: [Icon(Icons.lock_reset_rounded, size: 18), SizedBox(width: 8), Text('Reset Password')])),
                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.location_city_rounded, size: 16, color: AppColors.textTertiary),
                              const SizedBox(width: 6),
                              Text(c['branch_name'] ?? 'No branch', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              if (c['phone'] != null && c['phone'].toString().isNotEmpty) ...[
                                const SizedBox(width: 16),
                                const Icon(Icons.phone_rounded, size: 16, color: AppColors.textTertiary),
                                const SizedBox(width: 6),
                                Text(c['phone'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
