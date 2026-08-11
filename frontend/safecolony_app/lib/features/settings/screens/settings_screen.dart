import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final AuthService _authService = AuthService();

  bool _loading = true;
  bool _inAppNotifications = true;
  bool _visitorNotifications = true;
  bool _deliveryNotifications = true;
  bool _maintenanceNotifications = true;
  bool _securityNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final values = await Future.wait<bool>([
      _settingsService.getInAppNotifications(),
      _settingsService.getVisitorNotifications(),
      _settingsService.getDeliveryNotifications(),
      _settingsService.getMaintenanceNotifications(),
      _settingsService.getSecurityNotifications(),
    ]);

    if (!mounted) return;

    setState(() {
      _inAppNotifications = values[0];
      _visitorNotifications = values[1];
      _deliveryNotifications = values[2];
      _maintenanceNotifications = values[3];
      _securityNotifications = values[4];
      _loading = false;
    });
  }

  Future<void> _setInAppNotifications(bool value) async {
    setState(() => _inAppNotifications = value);
    await _settingsService.setInAppNotifications(value);
  }

  Future<void> _setVisitorNotifications(bool value) async {
    setState(() => _visitorNotifications = value);
    await _settingsService.setVisitorNotifications(value);
  }

  Future<void> _setDeliveryNotifications(bool value) async {
    setState(() => _deliveryNotifications = value);
    await _settingsService.setDeliveryNotifications(value);
  }

  Future<void> _setMaintenanceNotifications(bool value) async {
    setState(() => _maintenanceNotifications = value);
    await _settingsService.setMaintenanceNotifications(value);
  }

  Future<void> _setSecurityNotifications(bool value) async {
    setState(() => _securityNotifications = value);
    await _settingsService.setSecurityNotifications(value);
  }

  Future<void> _resetNotificationSettings() async {
    await _settingsService.resetNotificationSettings();
    await _loadSettings();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings restored to defaults.'),
      ),
    );
  }

  Future<void> _showChangePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;

              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('New passwords do not match.'),
                  ),
                );
                return;
              }

              setDialogState(() => saving = true);

              try {
                await _authService.changePassword(
                  currentPassword: currentController.text,
                  newPassword: newController.text,
                );

                if (!context.mounted) return;
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully.'),
                  ),
                );
              } catch (e) {
                setDialogState(() => saving = false);

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_friendlyError(e)),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('Change Password'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: currentController,
                          obscureText: obscureCurrent,
                          enabled: !saving,
                          decoration: InputDecoration(
                            labelText: 'Current password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setDialogState(
                                () => obscureCurrent = !obscureCurrent,
                              ),
                              icon: Icon(
                                obscureCurrent
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your current password.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: newController,
                          obscureText: obscureNew,
                          enabled: !saving,
                          decoration: InputDecoration(
                            labelText: 'New password',
                            helperText:
                                'Use upper/lowercase letters and a number.',
                            prefixIcon: const Icon(Icons.password_outlined),
                            suffixIcon: IconButton(
                              onPressed: () => setDialogState(
                                () => obscureNew = !obscureNew,
                              ),
                              icon: Icon(
                                obscureNew
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'Password must be at least 8 characters.';
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              return 'Add at least one uppercase letter.';
                            }
                            if (!RegExp(r'[a-z]').hasMatch(value)) {
                              return 'Add at least one lowercase letter.';
                            }
                            if (!RegExp(r'\d').hasMatch(value)) {
                              return 'Add at least one number.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: confirmController,
                          obscureText: obscureConfirm,
                          enabled: !saving,
                          decoration: InputDecoration(
                            labelText: 'Confirm new password',
                            prefixIcon: const Icon(Icons.verified_user_outlined),
                            suffixIcon: IconButton(
                              onPressed: () => setDialogState(
                                () => obscureConfirm = !obscureConfirm,
                              ),
                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm the new password.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : submit,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Saving...' : 'Change Password'),
                ),
              ],
            );
          },
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('401')) {
      return 'Current password is incorrect.';
    }
    if (text.contains('400')) {
      return 'Unable to change password. Check the password requirements.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              children: [
                _accountCard(user),
                const SizedBox(height: 18),
                _section(
                  title: 'Notifications',
                  subtitle: 'Choose which alerts appear in the app.',
                  icon: Icons.notifications_active_rounded,
                  children: [
                    SwitchListTile.adaptive(
                      value: _inAppNotifications,
                      onChanged: _setInAppNotifications,
                      title: const Text('In-app notifications'),
                      subtitle: const Text(
                        'Show notification alerts and unread counts.',
                      ),
                      secondary: const Icon(Icons.notifications_outlined),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      value: _visitorNotifications,
                      onChanged: _inAppNotifications
                          ? _setVisitorNotifications
                          : null,
                      title: const Text('Visitor alerts'),
                      subtitle: const Text(
                        'Visitor approvals and visitor activity.',
                      ),
                      secondary: const Icon(Icons.people_outline),
                    ),
                    SwitchListTile.adaptive(
                      value: _deliveryNotifications,
                      onChanged: _inAppNotifications
                          ? _setDeliveryNotifications
                          : null,
                      title: const Text('Delivery alerts'),
                      subtitle: const Text(
                        'Package arrival and delivery updates.',
                      ),
                      secondary: const Icon(Icons.local_shipping_outlined),
                    ),
                    SwitchListTile.adaptive(
                      value: _maintenanceNotifications,
                      onChanged: _inAppNotifications
                          ? _setMaintenanceNotifications
                          : null,
                      title: const Text('Maintenance alerts'),
                      subtitle: const Text(
                        'Maintenance due and payment reminders.',
                      ),
                      secondary: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                    SwitchListTile.adaptive(
                      value: _securityNotifications,
                      onChanged: _inAppNotifications
                          ? _setSecurityNotifications
                          : null,
                      title: const Text('Security alerts'),
                      subtitle: const Text(
                        'Security and emergency notifications.',
                      ),
                      secondary: const Icon(Icons.security_outlined),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _resetNotificationSettings,
                        icon: const Icon(Icons.restore),
                        label: const Text('Restore notification defaults'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _section(
                  title: 'Security',
                  subtitle: 'Keep your SafeColony account protected.',
                  icon: Icons.security_rounded,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.password_outlined),
                      title: const Text('Change password'),
                      subtitle: const Text(
                        'Update your account password securely.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showChangePassword,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _section(
                  title: 'About SafeColony',
                  subtitle: 'Application information.',
                  icon: Icons.info_outline_rounded,
                  children: const [
                    ListTile(
                      leading: Icon(Icons.verified_rounded),
                      title: Text('SafeColony AI'),
                      subtitle: Text('Smart communities. Safer together.'),
                    ),
                    ListTile(
                      leading: Icon(Icons.tag),
                      title: Text('Version'),
                      subtitle: Text('1.0.0'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xffDC2626),
                    side: const BorderSide(color: Color(0xffFCA5A5)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _accountCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff312E81), Color(0xff4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.role ?? '',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xffEEF2FF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xff4F46E5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xff64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
