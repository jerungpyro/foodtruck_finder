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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange), // Better theming
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

  static const LatLng _defaultInitialPosition = LatLng(37.4219983, -122.084);
  LatLng _currentMapPosition = _defaultInitialPosition;
  bool _isLoadingLocation = true;

  final Set<Marker> _markers = {};
  late List<FoodTruck> _mockFoodTrucks;

  @override
  void initState() {
    super.initState();
    _initializeMockFoodTrucks();
    _getUserLocationAndCenterMap();
  }

  void _initializeMockFoodTrucks() {
    _mockFoodTrucks = [
      FoodTruck(
        id: "ft1",
        name: "Speedy Tacos",
        type: "Tacos",
        position: const LatLng(37.785834, -122.406417),
        reportedBy: "UserA",
        lastReported: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      FoodTruck(
        id: "ft2",
        name: "Java Express",
        type: "Coffee",
        position: const LatLng(37.774929, -122.419416),
        reportedBy: "UserB",
        lastReported: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      FoodTruck(
        id: "ft3",
        name: "BBQ Bonanza",
        type: "BBQ",
        position: const LatLng(37.795213, -122.394073),
        reportedBy: "UserC",
        lastReported: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      ),
      FoodTruck(
        id: "ft4",
        name: "Curry Up Now",
        type: "Indian",
        position: const LatLng(37.4239999, -122.0860575),
        reportedBy: "UserD",
        lastReported: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    _createMarkersFromMockData();
  }

  void _createMarkersFromMockData() {
    Set<Marker> tempMarkers = {};
    for (var truck in _mockFoodTrucks) {
      tempMarkers.add(
        Marker(
          markerId: MarkerId(truck.id),
          position: truck.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: truck.name,
            snippet: 'Type: ${truck.type}',
          ),
          onTap: () {
            _showFoodTruckDetailsBottomSheet(truck);
          },
        ),
      );
    }
    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(tempMarkers);
      });
    }
  }

  void _showFoodTruckDetailsBottomSheet(FoodTruck truck) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white, // Or Theme.of(context).cardColor
      isScrollControlled: true, // Allows sheet to take more height if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (context) {
        String formattedDateTime =
            "${truck.lastReported.toLocal().day.toString().padLeft(2, '0')}/${truck.lastReported.toLocal().month.toString().padLeft(2, '0')}/${truck.lastReported.toLocal().year} at ${truck.lastReported.toLocal().hour.toString().padLeft(2, '0')}:${truck.lastReported.toLocal().minute.toString().padLeft(2, '0')}";

        return Padding(
          padding: EdgeInsets.only(
            top: 20.0,
            left: 20.0,
            right: 20.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.0, // Adjust for keyboard
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                truck.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.category_outlined, "Type", truck.type),
              _buildDetailRow(Icons.person_pin_circle_outlined, "Reported by", truck.reportedBy),
              _buildDetailRow(Icons.timer_outlined, "Last Reported", formattedDateTime),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)
                  ),
                  child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22.0, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 16.0),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
              // softWrap: true, // Already default
            ),
          ),
        ],
      ),
    );
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
      if (_controllerCompleter.isCompleted) _animateToPosition(_currentMapPosition);
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
        if (_controllerCompleter.isCompleted) _animateToPosition(_currentMapPosition);
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
      if (_controllerCompleter.isCompleted) _animateToPosition(_currentMapPosition);
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
      if (_controllerCompleter.isCompleted) _animateToPosition(_currentMapPosition);
    }
  }

  Future<void> _animateToPosition(LatLng position) async {
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              if (!_controllerCompleter.isCompleted) {
                _controllerCompleter.complete(controller);
                _mapController = controller;
              }
              // If location was determined before map was ready, move camera now
              if (!_isLoadingLocation) {
                 _animateToPosition(_currentMapPosition);
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentMapPosition,
              zoom: 11.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),
          if (_isLoadingLocation)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getUserLocationAndCenterMap,
        tooltip: 'My Location',
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        child: _isLoadingLocation && !_controllerCompleter.isCompleted
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.my_location),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}