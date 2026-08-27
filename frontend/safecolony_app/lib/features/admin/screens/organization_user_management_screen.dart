import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../scopes/block_admin_service.dart';
import '../services/organization_user_service.dart';
import '../services/admin_service.dart';
import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizationUserManagementScreen extends ConsumerStatefulWidget {
  const OrganizationUserManagementScreen({super.key});

  @override
  ConsumerState<OrganizationUserManagementScreen> createState() =>
      _OrganizationUserManagementScreenState();
}

class _OrganizationUserManagementScreenState
    extends ConsumerState<OrganizationUserManagementScreen> {
  final _service = OrganizationUserService();
  final _residentService = AdminService();
  final _blockService = BlockAdminService();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _blocks = [];
  bool _loading = true;

  static const _roles = <String, String>{
    'BLOCK_ADMIN': 'Block Administrator',
    'COMMUNITY_FINANCE_ADMIN': 'Community Finance Admin',
    'PROPERTY_MANAGER': 'Property Manager',
    'SECURITY_MANAGER': 'Security Manager',
    'SECURITY_GUARD': 'Security Guard',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await _service.getUsers();
      final blocks = await _blockService.getBlocks();

      if (!mounted) return;
      setState(() {
        _users = users;
        _blocks = blocks;
      });
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _roleLabel(String role) {
    return _roles[role] ??
        role
            .toLowerCase()
            .split('_')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
  }

  Future<void> _createUser() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController(text: 'ChangeMe@123');
    String role = _roles.keys.first;
    final selectedBlocks = <int>{};
    bool obscurePassword = true;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isBlockAdmin = role == 'BLOCK_ADMIN';

            return AlertDialog(
              title: const Text('Add User'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: password,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Temporary password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setDialogState(
                              () => obscurePassword = !obscurePassword,
                            ),
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          prefixIcon:
                              Icon(Icons.admin_panel_settings_outlined),
                        ),
                        items: _roles.entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            role = value;
                            if (role != 'BLOCK_ADMIN') {
                              selectedBlocks.clear();
                            }
                          });
                        },
                      ),
                      if (isBlockAdmin) ...[
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Assign blocks',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Select at least one block for a Block Administrator.',
                            style: TextStyle(
                              color: Color(0xff64748B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ..._blocks.map(
                          (block) {
                            final id = block['section_id'] as int;
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: selectedBlocks.contains(id),
                              title: Text(
                                block['section_name'].toString(),
                              ),
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    selectedBlocks.add(id);
                                  } else {
                                    selectedBlocks.remove(id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Residents should continue to use the normal registration and approval flow.',
                          style: TextStyle(
                            color: Color(0xff64748B),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (name.text.trim().length < 3 ||
                        !email.text.contains('@') ||
                        phone.text.trim().length < 10 ||
                        password.text.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter valid user details and a password of at least 8 characters.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (role == 'BLOCK_ADMIN' &&
                        selectedBlocks.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Select at least one block for a Block Administrator.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Create User'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created != true) return;

    try {
      await _service.createUser(
        fullName: name.text,
        email: email.text,
        phone: phone.text,
        password: password.text,
        role: role,
        sectionIds: selectedBlocks.toList(),
      );

      if (!mounted) return;
      _showSuccess('User created successfully.');
      await _load();
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      name.dispose();
      email.dispose();
      phone.dispose();
      password.dispose();
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    if (user['role']?.toString() == 'RESIDENT') {
      final name = TextEditingController(text: user['full_name']?.toString() ?? '');
      final email = TextEditingController(text: user['email']?.toString() ?? '');
      final phone = TextEditingController(text: user['phone']?.toString() ?? '');
      final saved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Resident'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save Changes')),
          ],
        ),
      );
      if (saved == true) {
        try {
          await _residentService.updateResident(
            residentId: user['resident_id'] as int,
            fullName: name.text,
            email: email.text,
            phone: phone.text,
          );
          if (mounted) {
            _showSuccess('Resident updated successfully.');
            await _load();
          }
        } catch (e) {
          if (mounted) _showError(e);
        }
      }
      name.dispose(); email.dispose(); phone.dispose();
      return;
    }
    final name = TextEditingController(text: user['full_name']?.toString() ?? '');
    final email = TextEditingController(text: user['email']?.toString() ?? '');
    final phone = TextEditingController(text: user['phone']?.toString() ?? '');
    final password = TextEditingController();
    String role = user['role']?.toString() ?? _roles.keys.first;
    final selectedBlocks = <int>{...(user['section_ids'] as List? ?? []).whereType<int>()};

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isBlockAdmin = role == 'BLOCK_ADMIN';
          return AlertDialog(
            title: Text('Edit ${_roleLabel(user['role'].toString())}'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
                    const SizedBox(height: 12),
                    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 12),
                    TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New password (leave blank to keep current)',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _roles.containsKey(role) ? role : null,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: _roles.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setDialogState(() {
                          role = v;
                          if (role != 'BLOCK_ADMIN') selectedBlocks.clear();
                        });
                      },
                    ),
                    if (isBlockAdmin) ...[
                      const SizedBox(height: 12),
                      const Align(alignment: Alignment.centerLeft, child: Text('Assign blocks', style: TextStyle(fontWeight: FontWeight.w800))),
                      ..._blocks.map((block) {
                        final id = block['section_id'] as int;
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: selectedBlocks.contains(id),
                          title: Text(block['section_name'].toString()),
                          onChanged: (v) => setDialogState(() => v == true ? selectedBlocks.add(id) : selectedBlocks.remove(id)),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (name.text.trim().length < 3 || !email.text.contains('@') || phone.text.trim().length < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid user details.')));
                    return;
                  }
                  if (role == 'BLOCK_ADMIN' && selectedBlocks.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one block.')));
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true) return;
    try {
      await _service.updateUser(
        userId: user['id'] as int,
        fullName: name.text,
        email: email.text,
        phone: phone.text,
        role: role,
        sectionIds: selectedBlocks.toList(),
        password: password.text.trim().isEmpty ? null : password.text,
      );
      if (!mounted) return;
      _showSuccess('User updated successfully.');
      await _load();
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      name.dispose(); email.dispose(); phone.dispose(); password.dispose();
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final currentUserId = ref.read(authProvider).user?.id;
    final userId = user['id'] as int;

    if (currentUserId == userId) {
      _showError(
        const ApiException('You cannot delete your own account.'),
      );
      return;
    }

    final name = user['full_name'].toString();
    final role = user['role'].toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
          'Delete $name (${_roleLabel(role)})?\n\n'
          'This removes the user\'s login access while preserving historical '
          'maintenance, payment, finance and community records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffDC2626),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete User'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteUser(userId);
      if (!mounted) return;
      _showSuccess('User deleted successfully.');
      await _load();
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _restoreUser(Map<String, dynamic> user) async {
    try {
      await _service.restoreUser(user['id'] as int);
      if (!mounted) return;
      _showSuccess('User restored successfully.');
      await _load();
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xff059669),
        content: Text(message),
      ),
    );
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xffDC2626),
        content: Text(ApiClient.errorMessage(error)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount =
        _users.where((user) => user['is_active'] == true).length;
    final inactiveCount =
        _users.where((user) => user['is_active'] != true).length;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _createUser,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add User'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  _summaryCard(
                    activeCount,
                    inactiveCount,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Organization Users',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage operational users and their access. '
                    'Resident registration remains approval-based.',
                    style: TextStyle(
                      color: Color(0xff64748B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_users.isEmpty)
                    _emptyCard()
                  else
                    ..._users.map(_userCard),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard(int activeCount, int inactiveCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              'Active users',
              '$activeCount',
              Icons.people_alt_rounded,
              const Color(0xff059669),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryItem(
              'Inactive users',
              '$inactiveCount',
              Icons.person_off_rounded,
              const Color(0xffDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xff64748B),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user) {
    final active = user['is_active'] == true;
    final currentUserId = ref.read(authProvider).user?.id;
    final isCurrentUser = currentUserId == user['id'];

    final sectionNames = (user['section_names'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xffE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: active
                  ? const Color(0xffEEF2FF)
                  : const Color(0xffF1F5F9),
              foregroundColor: active
                  ? const Color(0xff4F46E5)
                  : const Color(0xff94A3B8),
              child: Text(
                user['full_name']
                    .toString()
                    .trim()
                    .substring(0, 1)
                    .toUpperCase(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user['full_name'].toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 8),
                        _badge('YOU', const Color(0xff4F46E5)),
                      ],
                      if (!active) ...[
                        const SizedBox(width: 8),
                        _badge('INACTIVE', const Color(0xffDC2626)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _roleLabel(user['role'].toString()),
                    style: const TextStyle(
                      color: Color(0xff4F46E5),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user['email']} • ${user['phone']}',
                    style: const TextStyle(
                      color: Color(0xff64748B),
                      fontSize: 12,
                    ),
                  ),
                  if (sectionNames.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Blocks: ${sectionNames.join(', ')}',
                      style: const TextStyle(
                        color: Color(0xff64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!isCurrentUser) ...[
              IconButton(
                tooltip: 'Edit user',
                onPressed: () => _editUser(user),
                icon: const Icon(Icons.edit_outlined, color: Color(0xff4F46E5)),
              ),
              active
                  ? IconButton(
                      tooltip: 'Delete user',
                      onPressed: () => _deleteUser(user),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xffDC2626),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Restore user',
                      onPressed: () => _restoreUser(user),
                      icon: const Icon(
                        Icons.restore_rounded,
                        color: Color(0xff059669),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: const Text(
        'No users found for this organization.',
        style: TextStyle(
          color: Color(0xff64748B),
        ),
      ),
    );
  }
}
