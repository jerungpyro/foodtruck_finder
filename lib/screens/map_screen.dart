import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // This line needs 'flutter pub get' to work

// Import the FoodTruck model
import '../models/food_truck_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.title});
  final String title;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer<GoogleMapController>();
  // GoogleMapController? _mapController; // REMOVED - Was unused

  static const LatLng _defaultInitialPosition = LatLng(37.4219983, -122.084); // Googleplex
  LatLng _currentMapPosition = _defaultInitialPosition;

  bool _isLoadingLocation = true;
  bool _isLoadingFoodTrucks = true;

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchFoodTrucksAndCreateMarkers();
    _getUserLocationAndCenterMap();
  }

  Future<void> _fetchFoodTrucksAndCreateMarkers() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFoodTrucks = true;
    });

    try {
      // QuerySnapshot will be defined once package is resolved
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('foodTrucks').get(); // FirebaseFirestore will be defined

      List<FoodTruck> fetchedTrucks = [];
      if (snapshot.docs.isNotEmpty) {
        fetchedTrucks = snapshot.docs
            .map((doc) => FoodTruck.fromFirestore(doc))
            .toList();
      } else {
        print("No food trucks found in Firestore."); // Lint warning: avoid print
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No food trucks found nearby right now.')));
        }
      }
      _createMarkersFromData(fetchedTrucks);

    } catch (e) {
      print("Error fetching food trucks: $e"); // Lint warning: avoid print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Error loading food trucks: ${e.toString().substring(0, (e.toString().length > 100) ? 100 : e.toString().length)}...')));
      }
      _createMarkersFromData([]);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFoodTrucks = false;
        });
      }
    }
  }

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
        _markers.clear();
        _markers.addAll(tempMarkers);
      });
    }
  }

  void _showFoodTruckDetailsBottomSheet(FoodTruck truck) {
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
          desiredAccuracy: LocationAccuracy.high); // Lint warning: desiredAccuracy deprecated
      if (mounted) {
        setState(() {
          _currentMapPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
      }
      _animateToPosition(_currentMapPosition);
    } catch (e) {
      print("Error getting location: $e"); // Lint warning: avoid print
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
    final GoogleMapController controller = await _controllerCompleter.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: position, zoom: 15.0),
    ));
  }

  @override
  Widget build(BuildContext context) {
    bool isOverallLoading = _isLoadingLocation || (_isLoadingFoodTrucks && _markers.isEmpty);

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
                // _mapController = controller; // Assignment removed
              }
              if (!_isLoadingLocation && _currentMapPosition != _defaultInitialPosition) {
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
          if (isOverallLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _getUserLocationAndCenterMap();
          _fetchFoodTrucksAndCreateMarkers();
        },
        tooltip: 'Refresh Location & Trucks',
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        child: (_isLoadingLocation || _isLoadingFoodTrucks) && !_controllerCompleter.isCompleted
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}