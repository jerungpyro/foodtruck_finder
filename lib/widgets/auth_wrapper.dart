// lib/widgets/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/map_screen.dart';
import '../screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    print("[AuthWrapper] Build method called. Listening to authStateChanges from singleton AuthService.");

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) { // Explicitly type AsyncSnapshot
        print("[AuthWrapper] StreamBuilder REBUILT. ConnectionState: ${snapshot.connectionState}, HasData: ${snapshot.hasData}, User: ${snapshot.data?.uid}, Error: ${snapshot.hasError}");

        if (snapshot.hasError) {
          print("[AuthWrapper] StreamBuilder error: ${snapshot.error}");
          return Scaffold(
            body: Center(child: Text("Auth Stream Error: ${snapshot.error}")),
          );
        }

        switch (snapshot.connectionState) {
          case ConnectionState.none:
            print("[AuthWrapper] ConnectionState.none");
            return const Scaffold(body: Center(child: Text("Auth Stream not yet connected.")));
          case ConnectionState.waiting:
            print("[AuthWrapper] ConnectionState.waiting. Returning Loading Indicator.");
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case ConnectionState.active:
            print("[AuthWrapper] ConnectionState.active. User data: ${snapshot.data?.uid}");
            final User? user = snapshot.data;
            if (user != null) {
              print("[AuthWrapper] User IS Authenticated (uid: ${user.uid}). Returning MapScreen.");
              return const MapScreen(title: 'FoodTruck Finder - Map');
            } else {
              print("[AuthWrapper] User IS NOT Authenticated. Returning LoginScreen.");
              return const LoginScreen();
            }
          case ConnectionState.done:
            print("[AuthWrapper] ConnectionState.done (Stream has closed - should not happen for authStateChanges). Returning LoginScreen as fallback.");
             // authStateChanges should not complete, but handle defensively
            return const LoginScreen();
        }
      },
    );
  }
}