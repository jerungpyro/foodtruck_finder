// lib/widgets/admin_auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart'; // We will create this next

class AdminAuthWrapper extends StatefulWidget {
  const AdminAuthWrapper({super.key});

  @override
  State<AdminAuthWrapper> createState() => _AdminAuthWrapperState();
}

class _AdminAuthWrapperState extends State<AdminAuthWrapper> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    print("[AdminAuthWrapper] Build method called.");

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        print("[AdminAuthWrapper] Auth StreamBuilder REBUILT. ConnectionState: ${authSnapshot.connectionState}, User: ${authSnapshot.data?.uid}");

        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasError) {
          return Scaffold(body: Center(child: Text("Auth Error: ${authSnapshot.error}")));
        }

        final User? user = authSnapshot.data;
        if (user == null) {
          print("[AdminAuthWrapper] User is null. Showing AdminLoginScreen.");
          return AdminLoginScreen(onLoginSuccess: () {
            // When AdminLoginScreen reports success, it means auth state has changed.
            // This StreamBuilder will pick it up. We can call setState to be sure.
            setState(() {});
            print("[AdminAuthWrapper] AdminLoginScreen reported success. Rebuilding.");
          });
        }

        // User is authenticated, now check if they are an admin
        // This future builder fetches the role.
        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(user.uid).get(),
          builder: (context, userDocSnapshot) {
            print("[AdminAuthWrapper] UserDoc FutureBuilder REBUILT. ConnectionState: ${userDocSnapshot.connectionState}, HasData: ${userDocSnapshot.hasData}");

            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: Text("Verifying admin status...")));
            }

            if (userDocSnapshot.hasError) {
              print("[AdminAuthWrapper] Error fetching user document: ${userDocSnapshot.error}");
              // Sign out if user doc can't be fetched, as we can't verify role.
              // Consider what to do here - maybe an error screen.
              _authService.signOut();
              return AdminLoginScreen(onLoginSuccess: () => setState(() {})); // Show login again
            }

            if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
              final String role = userDocSnapshot.data!.get('role') ?? 'user';
              if (role == 'admin') {
                print("[AdminAuthWrapper] User is ADMIN. Showing AdminDashboardScreen.");
                return AdminDashboardScreen(adminUser: user); // Pass the admin user
              } else {
                print("[AdminAuthWrapper] User is NOT ADMIN. Signing out and showing AdminLoginScreen.");
                _authService.signOut(); // Important: Sign out non-admin trying to access admin panel
                return AdminLoginScreen(onLoginSuccess: () => setState(() {}));
              }
            } else {
              // User document doesn't exist, or no role field. Treat as non-admin.
              print("[AdminAuthWrapper] User document does not exist or no role. Signing out.");
              _authService.signOut();
              return AdminLoginScreen(onLoginSuccess: () => setState(() {}));
            }
          },
        );
      },
    );
  }
}