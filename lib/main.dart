import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Import generated options

// Import the new map screen
import 'screens/map_screen.dart';

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
    return MaterialApp(
      title: 'FoodTruck Finder',
      theme: ThemeData(
        primarySwatch: Colors.orange, // You can keep this
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange), // Or use ColorScheme
      ),
      // Use MapScreen as the home screen
      home: const MapScreen(title: 'FoodTruck Finder - Map'),
    );
  }
}