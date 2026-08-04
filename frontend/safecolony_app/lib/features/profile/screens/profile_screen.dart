import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final auth = ref.watch(authProvider);

    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const CircleAvatar(
              radius: 45,
              child: Icon(Icons.person,size:40),
            ),

            const SizedBox(height:20),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Name"),
              subtitle: Text(user?.fullName ?? ""),
            ),

            ListTile(
              leading: const Icon(Icons.email),
              title: const Text("Email"),
              subtitle: Text(user?.email ?? ""),
            ),

            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text("Phone"),
              subtitle: Text(user?.phone ?? ""),
            ),

            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text("Role"),
              subtitle: Text(user?.role ?? ""),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                onPressed: () async {

                  await ref
                      .read(authProvider.notifier)
                      .logout();

                  if(context.mounted){
                    Navigator.popUntil(
                      context,
                      (route)=>route.isFirst,
                    );
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}