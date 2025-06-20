import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'about_us_screen.dart'; // Import the AboutUsScreen

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final User? currentUser = authService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView( // Changed to ListView to accommodate more items
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              size: 50,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              currentUser?.displayName ?? 'Not set',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              currentUser?.email ?? 'Not available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'UID: ${currentUser?.uid ?? 'Not available'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 30),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About App'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsScreen()),
              );
            },
          ),
          // You can add more ListTiles here for other options like:
          // ListTile(
          //   leading: const Icon(Icons.settings_outlined),
          //   title: const Text('Settings'),
          //   onTap: () { /* Navigate to SettingsScreen */ },
          // ),
          // ListTile(
          //   leading: const Icon(Icons.help_outline),
          //   title: const Text('Help & FAQ'),
          //   onTap: () { /* Navigate to HelpScreen */ },
          // ),
          const Divider(),
          const SizedBox(height: 30),
          Padding( // Added padding for the logout button to make it distinct
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                print("[ProfileScreen] Logout button pressed.");
                await authService.signOut();
                if (context.mounted) {
                   Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text('Logout', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 20), // Spacer at the bottom
        ],
      ),
    );
  }
}