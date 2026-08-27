import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/guard_provider.dart';

class GuardListScreen extends ConsumerStatefulWidget {
  const GuardListScreen({super.key});

  @override
  ConsumerState<GuardListScreen> createState() =>
      _GuardListScreenState();
}

class _GuardListScreenState
    extends ConsumerState<GuardListScreen> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(guardProvider.notifier).loadGuards();
    });
  }

  @override
  Widget build(BuildContext context) {

    final state = ref.watch(guardProvider);

    return Scaffold(

      appBar: AppBar(
        title: const Text("Security Guards"),
      ),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Add Guard"),
        onPressed: _showAddGuardDialog,
      ),

      body: RefreshIndicator(

        onRefresh: () async {
          await ref
              .read(guardProvider.notifier)
              .loadGuards();
        },

        child: Builder(

          builder: (_) {

            if (state.loading) {

              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.error != null) {

              return Center(
                child: Text(state.error!),
              );
            }

            if (state.guards.isEmpty) {

              return const Center(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [

                    Icon(
                      Icons.security,
                      size: 70,
                      color: Colors.grey,
                    ),

                    SizedBox(height: 20),

                    Text(
                      "No Security Guards",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10),

                    Text(
                      "Tap + to create your first guard.",
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(

              padding:
                  const EdgeInsets.all(16),

              itemCount:
                  state.guards.length,

              separatorBuilder:
                  (_, __) =>
                      const SizedBox(height: 12),

              itemBuilder: (_, index) {

                final guard =
                    state.guards[index];

                return Card(

                  elevation: 3,

                  child: ListTile(

                    leading: CircleAvatar(
                      child: Text(
                        guard.fullName
                            .substring(0, 1)
                            .toUpperCase(),
                      ),
                    ),

                    title: Text(
                      guard.fullName,
                    ),

                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        const SizedBox(height: 4),

                        Text(guard.email),

                        Text(guard.phone),
                      ],
                    ),

                    trailing: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         IconButton(
                           tooltip: 'Edit guard',
                           icon: const Icon(Icons.edit_outlined, color: Colors.indigo),
                           onPressed: () => _editGuard(guard),
                         ),
                         const Icon(Icons.verified_user, color: Colors.green),
                       ],
                     ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  //============================================================

  Future<void> _editGuard(dynamic guard) async {
    final nameController = TextEditingController(text: guard.fullName);
    final emailController = TextEditingController(text: guard.email);
    final phoneController = TextEditingController(text: guard.phone);
    final passwordController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Security Guard'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 12),
                TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'New password (optional)')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save Changes')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(guardProvider.notifier).updateGuard(
        userId: guard.id,
        fullName: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        password: passwordController.text.trim().isEmpty ? null : passwordController.text,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guard updated successfully.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      nameController.dispose(); emailController.dispose(); phoneController.dispose(); passwordController.dispose();
    }
  }

  void _showAddGuardDialog() {

    final nameController =
        TextEditingController();

    final emailController =
        TextEditingController();

    final phoneController =
        TextEditingController();

    final passwordController =
        TextEditingController();

    final formKey =
        GlobalKey<FormState>();

    showDialog(

      context: context,

      builder: (_) {

        return AlertDialog(

          title: const Text(
            "Create Security Guard",
          ),

          content: Form(

            key: formKey,

            child: SizedBox(

              width: 420,

              child: SingleChildScrollView(

                child: Column(

                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    TextFormField(
                      controller:
                          nameController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Full Name",
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty
                              ? "Required"
                              : null,
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      controller:
                          emailController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Email",
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty
                              ? "Required"
                              : null,
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      controller:
                          phoneController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Phone",
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty
                              ? "Required"
                              : null,
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      controller:
                          passwordController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Password",
                      ),
                      validator: (v) =>
                          v == null || v.length < 6
                              ? "Minimum 6 characters"
                              : null,
                    ),
                  ],
                ),
              ),
            ),
          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(context);

              },

              child: const Text(
                "Cancel",
              ),
            ),

            ElevatedButton(

              child: const Text(
                "Create",
              ),

              onPressed: () async {

                if (!formKey.currentState!
                    .validate()) {
                  return;
                }

                try {

                  await ref
                      .read(
                          guardProvider.notifier)
                      .createGuard(

                        fullName:
                            nameController.text,

                        email:
                            emailController.text,

                        phone:
                            phoneController.text,

                        password:
                            passwordController.text,
                      );

                  if (!mounted) return;

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Guard created successfully.",
                      ),
                    ),
                  );

                } catch (e) {

                  if (!mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString(),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}