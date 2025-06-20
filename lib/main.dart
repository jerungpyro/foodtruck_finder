import 'dart:async'; // For Completer

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'firebase_options.dart';

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
        primarySwatch: Colors.orange,
      ),
      home: const MyHomePage(title: 'FoodTruck Finder - Map'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Use Completer for the GoogleMapController as it's not available immediately
  final Completer<GoogleMapController> _controllerCompleter = Completer<GoogleMapController>();
  GoogleMapController? _mapController; // To store the controller once available

  static const LatLng _defaultInitialPosition = LatLng(37.422, -122.084); // Googleplex as a fallback
  LatLng _currentMapPosition = _defaultInitialPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getUserLocationAndCenterMap();
  }

  Future<void> _getUserLocationAndCenterMap() async {
    setState(() {
      _isLoadingLocation = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable them to see your location.')));
      setState(() {
        _currentMapPosition = _defaultInitialPosition;
        _isLoadingLocation = false;
      });
      _animateToPosition(_currentMapPosition);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')));
        setState(() {
          _currentMapPosition = _defaultInitialPosition;
          _isLoadingLocation = false;
        });
        _animateToPosition(_currentMapPosition);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      setState(() {
        _currentMapPosition = _defaultInitialPosition;
        _isLoadingLocation = false;
      });
      _animateToPosition(_currentMapPosition);
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentMapPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      _animateToPosition(_currentMapPosition);
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')));
      setState(() {
        _currentMapPosition = _defaultInitialPosition; // Fallback
        _isLoadingLocation = false;
      });
      _animateToPosition(_currentMapPosition);
    }
  }

  Future<void> _animateToPosition(LatLng position) async {
    final GoogleMapController controller = await _controllerCompleter.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: position,
        zoom: 15.0, // Zoom in a bit more when centered on user
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.orange,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              if (!_controllerCompleter.isCompleted) {
                _controllerCompleter.complete(controller); // Complete the completer
                 _mapController = controller; // Store controller
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentMapPosition, // Use the potentially updated position
              zoom: 11.0,
            ),
            markers: const {}, // Empty set of markers for now
            myLocationEnabled: true, // Shows the blue dot for user's location
            myLocationButtonEnabled: false, // We'll use our own button or auto-center
            zoomControlsEnabled: true, // Show default zoom controls
          ),
          if (_isLoadingLocation)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getUserLocationAndCenterMap, // Re-fetch and center
        tooltip: 'My Location',
        backgroundColor: Colors.orange,
        child: _isLoadingLocation
            ? const SizedBox( // Show smaller progress indicator on FAB if loading
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.my_location, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}