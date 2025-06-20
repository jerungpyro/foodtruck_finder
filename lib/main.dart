import 'dart:async'; // For Completer

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'firebase_options.dart'; // Import generated options

// --- Simple Food Truck Model for Mock Data ---
class FoodTruck {
  final String id;
  final String name;
  final String type; // e.g., "Mee Goreng", "Coffee", "BBQ"
  final LatLng position;
  final String reportedBy;
  final DateTime lastReported;

  FoodTruck({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    required this.reportedBy,
    required this.lastReported,
  });
}
// --- End of Food Truck Model ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for Firebase.initializeApp
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use generated options
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
        useMaterial3: true, // Optional: for modern Material Design components
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
  final Completer<GoogleMapController> _controllerCompleter = Completer<GoogleMapController>();
  GoogleMapController? _mapController;

  static const LatLng _defaultInitialPosition = LatLng(37.4219983, -122.084); // Googleplex as a fallback
  LatLng _currentMapPosition = _defaultInitialPosition;
  bool _isLoadingLocation = true;

  // Set to store the map markers
  final Set<Marker> _markers = {};
  // List of mock food trucks
  late List<FoodTruck> _mockFoodTrucks;

  @override
  void initState() {
    super.initState();
    _initializeMockFoodTrucks(); // Initialize mock data and create markers
    _getUserLocationAndCenterMap(); // Get user location
  }

  void _initializeMockFoodTrucks() {
    _mockFoodTrucks = [
      FoodTruck(
        id: "ft1",
        name: "Speedy Tacos",
        type: "Tacos",
        position: const LatLng(37.785834, -122.406417), // Near Moscone Center, SF
        reportedBy: "UserA",
        lastReported: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      FoodTruck(
        id: "ft2",
        name: "Java Express",
        type: "Coffee",
        position: const LatLng(37.774929, -122.419416), // Near Civic Center, SF
        reportedBy: "UserB",
        lastReported: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      FoodTruck(
        id: "ft3",
        name: "BBQ Bonanza",
        type: "BBQ",
        position: const LatLng(37.795213, -122.394073), // Near Ferry Building, SF
        reportedBy: "UserC",
        lastReported: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      ),
      FoodTruck(
        id: "ft4",
        name: "Curry Up Now",
        type: "Indian",
        position: const LatLng(37.4239999, -122.0860575), // Near Googleplex
        reportedBy: "UserD",
        lastReported: DateTime.now().subtract(const Duration(days:1)),
      ),
    ];

    _createMarkersFromMockData();
  }

  void _createMarkersFromMockData() {
    Set<Marker> tempMarkers = {};
    for (var truck in _mockFoodTrucks) {
      // Format DateTime for snippet
      String formattedTime = "${truck.lastReported.toLocal().hour.toString().padLeft(2, '0')}:${truck.lastReported.toLocal().minute.toString().padLeft(2, '0')} ${truck.lastReported.toLocal().day}/${truck.lastReported.toLocal().month}";

      tempMarkers.add(
        Marker(
          markerId: MarkerId(truck.id),
          position: truck.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: truck.name,
            snippet: 'Type: ${truck.type} | By: ${truck.reportedBy} @ $formattedTime',
          ),
        ),
      );
    }
    // Check if the widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        _markers.addAll(tempMarkers);
      });
    }
  }

  Future<void> _getUserLocationAndCenterMap() async {
    if (mounted) {
      setState(() {
        _isLoadingLocation = true;
      });
    }


    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location services are disabled. Please enable them.')));
        setState(() {
          _currentMapPosition = _defaultInitialPosition;
          _isLoadingLocation = false;
        });
      }
      _animateToPosition(_currentMapPosition);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')));
          setState(() {
            _currentMapPosition = _defaultInitialPosition;
            _isLoadingLocation = false;
          });
        }
        _animateToPosition(_currentMapPosition);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location permissions are permanently denied.')));
        setState(() {
          _currentMapPosition = _defaultInitialPosition;
          _isLoadingLocation = false;
        });
      }
      _animateToPosition(_currentMapPosition);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentMapPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
      }
      _animateToPosition(_currentMapPosition);
    } catch (e) {
      print("Error getting location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error getting location: $e')));
        setState(() {
          _currentMapPosition = _defaultInitialPosition;
          _isLoadingLocation = false;
        });
      }
      _animateToPosition(_currentMapPosition);
    }
  }

  Future<void> _animateToPosition(LatLng position) async {
    // Ensure _mapController is initialized (it might not be if map creation is slow or fails)
    final GoogleMapController controller = await _controllerCompleter.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: position,
        zoom: 15.0,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer, // Using theme color
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              if (!_controllerCompleter.isCompleted) {
                _controllerCompleter.complete(controller);
                 _mapController = controller; // Also assign to _mapController for direct access if needed
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentMapPosition, // Use the potentially updated position
              zoom: 11.0, // Initial zoom before centering on user
            ),
            markers: _markers, // Display the mock markers
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Using custom FAB
            zoomControlsEnabled: true,
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
        onPressed: _getUserLocationAndCenterMap,
        tooltip: 'My Location',
        backgroundColor: Colors.orange,
        child: _isLoadingLocation && !_controllerCompleter.isCompleted // Show progress only if map is also not ready
            ? const SizedBox(
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