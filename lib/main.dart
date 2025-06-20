import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // To check platform

// Import your wrapper widgets
import 'widgets/auth_wrapper.dart';       // For mobile app user authentication
import 'widgets/admin_auth_wrapper.dart'; // For admin web app authentication

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
      theme: ThemeData(
        primarySwatch: Colors.orange, // Or your preferred primary color
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          // Optionally, define brightness or other scheme properties
          // brightness: Brightness.light,
        ),
        // You can define specific web or mobile themes if needed later
      ),
      debugShowCheckedModeBanner: false, // Hides the debug banner
      home: initialScreen, // Directly assign the determined initial screen
      //
      // For more complex routing with named routes and URL strategies,
      // especially if you want distinct URLs like /admin for web,
      // you would use routes or onGenerateRoute.
      // For now, this direct home assignment based on kIsWeb is simpler.
      //
      // Example of named routes (for later, if needed):
      // routes: {
      //   '/': (context) => kIsWeb ? AdminAuthWrapper() : AuthWrapper(),
      //   '/login': (context) => LoginScreen(), // Example if you had direct navigation
      //   // ... other routes
      // },
      // initialRoute: '/', // if using named routes
    );
  }
}