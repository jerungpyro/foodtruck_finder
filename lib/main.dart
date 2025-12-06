import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // To check platform

// Import your wrapper widgets
import 'widgets/auth_wrapper.dart';       // For mobile app user authentication
import 'widgets/admin_auth_wrapper.dart'; // For admin web app authentication
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Widget initialScreen;

    if (kIsWeb) {
      print("[MyApp] Platform is Web. Setting AdminAuthWrapper as initial screen.");
      initialScreen = const AdminAuthWrapper();
    } else {
      print("[MyApp] Platform is Mobile. Setting AuthWrapper as initial screen.");
      initialScreen = const AuthWrapper();
    }

    return MaterialApp(
      title: kIsWeb ? 'FoodTruck Admin Panel' : 'FoodTruck Finder',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}