import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_truck_model.dart';
import 'profile_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.title});
  final String title;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer<GoogleMapController>();

  static const LatLng _defaultInitialPosition = LatLng(37.4219983, -122.084); // Googleplex
  LatLng _currentMapPosition = _defaultInitialPosition;

  bool _isLoadingLocation = true;
  // _isLoadingFoodTrucks might still be useful for the *initial* load indication from the stream
  // or can be implicitly handled by StreamBuilder's ConnectionState.waiting
  // Let's keep it for now for consistency with the overall loading indicator.
  bool _isLoadingFoodTrucks = true;

  final Set<Marker> _markers = {};
  StreamSubscription? _foodTrucksSubscription; // To manage the stream subscription

  @override
  void initState() {
    super.initState();
    _listenToFoodTruckUpdates(); // Changed from one-time fetch
    _getUserLocationAndCenterMap();
  }

  @override
  void dispose() {
    _foodTrucksSubscription?.cancel(); // Cancel subscription when widget is disposed
    super.dispose();
  }

  void _listenToFoodTruckUpdates() {
    print("[MapScreen] Subscribing to food truck updates...");
    if (mounted) {
      setState(() {
        _isLoadingFoodTrucks = true; // Indicate loading for the initial stream data
      });
    }

    _foodTrucksSubscription = FirebaseFirestore.instance
        .collection('foodTrucks')
        // Optional: Add .where('isVerified', isEqualTo: true) if you have such a field
        // and only want to display verified trucks from the main stream.
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      print("[MapScreen] Received food truck data snapshot. Docs: ${snapshot.docs.length}");
      List<FoodTruck> fetchedTrucks = [];
      if (snapshot.docs.isNotEmpty) {
        fetchedTrucks = snapshot.docs
            .map((doc) => FoodTruck.fromFirestore(doc))
            .toList();
      } else {
        print("[MapScreen] No food trucks found in snapshot.");
        // Optionally show a message if needed, but stream will keep listening
      }
      _createMarkersFromData(fetchedTrucks); // Update markers with new data

      if (mounted) {
        setState(() {
          _isLoadingFoodTrucks = false; // Stop loading indicator after first data arrives
        });
      }
    }, onError: (error) {
      print("[MapScreen] Error listening to food truck updates: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Error loading food trucks in real-time: ${error.toString().substring(0, (error.toString().length > 100) ? 100 : error.toString().length)}...')));
        setState(() {
          _isLoadingFoodTrucks = false;
          _markers.clear(); // Clear markers on error if desired
        });
      }
    });
  }

  // _fetchFoodTrucksAndCreateMarkers() is now replaced by _listenToFoodTruckUpdates()

  void _createMarkersFromData(List<FoodTruck> trucks) {
    Set<Marker> tempMarkers = {};
    for (var truck in trucks) {
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
        _markers.clear(); // Clear old markers
        _markers.addAll(tempMarkers); // Add new/updated markers
      });
    }
  }

  void _showFoodTruckDetailsBottomSheet(FoodTruck truck) {
    // ... (this method remains the same)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
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
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0)),
                  child: const Text("CLOSE",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    // ... (this method remains the same)
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
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getUserLocationAndCenterMap() async {
    // ... (this method remains the same)
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location services are disabled. Please enable them.')));
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
            content: Text('Location permissions are permanently denied.')));
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
      print("[MapScreen] Error getting location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error getting location: $e')));
        setState(() {
          _currentMapPosition = _defaultInitialPosition;
          _isLoadingLocation = false;
        });
      }
      if (_controllerCompleter.isCompleted) _animateToPosition(_currentMapPosition);
    }
  }

  Future<void> _animateToPosition(LatLng position) async {
    // ... (this method remains the same)
    final GoogleMapController controller = await _controllerCompleter.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: position, zoom: 15.0),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // The FloatingActionButton no longer needs to call _fetchFoodTrucksAndCreateMarkers
    // as data updates automatically. It can just be for centering the user's location.
    bool isOverallLoading = _isLoadingLocation || (_isLoadingFoodTrucks && _markers.isEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              if (!_controllerCompleter.isCompleted) {
                _controllerCompleter.complete(controller);
              }
              if (!_isLoadingLocation && _currentMapPosition != _defaultInitialPosition) {
                 _animateToPosition(_currentMapPosition);
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentMapPosition,
              zoom: 11.0,
            ),
            markers: _markers, // These will update based on the stream
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),
          if (isOverallLoading) // Handles initial loading of location and first batch of trucks
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getUserLocationAndCenterMap, // Now only centers user location
        tooltip: 'My Location', // Updated tooltip
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        child: _isLoadingLocation // Show progress only if fetching user location
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.my_location), // Changed icon back
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}