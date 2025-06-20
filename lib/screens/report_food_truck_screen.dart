import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // For getting current location
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng

import '../services/auth_service.dart'; // To get current user info

class ReportFoodTruckScreen extends StatefulWidget {
  // Optional: Pass initial coordinates if user taps on map to report
  final LatLng? initialCoordinates;

  const ReportFoodTruckScreen({super.key, this.initialCoordinates});

  @override
  State<ReportFoodTruckScreen> createState() => _ReportFoodTruckScreenState();
}

class _ReportFoodTruckScreenState extends State<ReportFoodTruckScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form field controllers
  final TextEditingController _truckNameController = TextEditingController();
  final TextEditingController _truckTypeController = TextEditingController();
  final TextEditingController _locationDescriptionController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _userNotesController = TextEditingController();

  bool _isNewTruck = true; // Default to reporting a new truck
  bool _isLoading = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCoordinates != null) {
      _latitudeController.text = widget.initialCoordinates!.latitude.toStringAsFixed(7);
      _longitudeController.text = widget.initialCoordinates!.longitude.toStringAsFixed(7);
    }
  }

  @override
  void dispose() {
    _truckNameController.dispose();
    _truckTypeController.dispose();
    _locationDescriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _userNotesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (mounted) setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        if (mounted) setState(() => _isFetchingLocation = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
          if (mounted) setState(() => _isFetchingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
        if (mounted) setState(() => _isFetchingLocation = false);
        return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _latitudeController.text = position.latitude.toStringAsFixed(7);
          _longitudeController.text = position.longitude.toStringAsFixed(7);
          _isFetchingLocation = false;
        });
      }
    } catch (e) {
      print("Error getting current location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not get current location: $e')));
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }
    if (mounted) setState(() => _isLoading = true);

    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in to submit a report.')));
        setState(() => _isLoading = false);
      }
      return;
    }

    double? latitude = double.tryParse(_latitudeController.text);
    double? longitude = double.tryParse(_longitudeController.text);

    if (latitude == null || longitude == null) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid latitude or longitude values.')));
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      await _firestore.collection('reports').add({
        'truckNameOrType': _truckNameController.text.trim(),
        'truckTypeSuggestion': _truckTypeController.text.trim(), // User's suggestion for type
        'locationDescription': _locationDescriptionController.text.trim(),
        'coordinates': GeoPoint(latitude, longitude),
        'userNotes': _userNotesController.text.trim(),
        'isNewTruck': _isNewTruck,
        'status': 'pending', // Initial status
        'reportedByUserId': currentUser.uid,
        'reportedByDisplayName': currentUser.displayName ?? 'Anonymous User',
        'reportedAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully for review!')));
        Navigator.of(context).pop(); // Go back after successful submission
      }
    } catch (e) {
      print("Error submitting report: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit report: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Food Truck'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _truckNameController,
                decoration: const InputDecoration(labelText: 'Food Truck Name / Brand*', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter the truck name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _truckTypeController,
                decoration: const InputDecoration(labelText: 'Food Type (e.g., Tacos, Coffee, BBQ)*', border: OutlineInputBorder()),
                 validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter the food type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationDescriptionController,
                decoration: const InputDecoration(labelText: 'Location Description (e.g., near park entrance)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Text("Location Coordinates*", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(labelText: 'Latitude*', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final num = double.tryParse(value);
                        if (num == null) return 'Invalid number';
                        if (num < -90 || num > 90) return 'Range: -90 to 90';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(labelText: 'Longitude*', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final num = double.tryParse(value);
                        if (num == null) return 'Invalid number';
                        if (num < -180 || num > 180) return 'Range: -180 to 180';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: _isFetchingLocation
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
                label: const Text('Use My Current Location'),
                onPressed: _isFetchingLocation ? null : _getCurrentLocation,
              ),
              // TODO: Add a small map to tap/drag pin for location selection (Advanced)
              const SizedBox(height: 16),
              TextFormField(
                controller: _userNotesController,
                decoration: const InputDecoration(labelText: 'Additional Notes (e.g., operating hours, specialty)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              // Option for new truck vs update (simplified for now)
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     const Text("Is this a new truck? "),
              //     Switch(
              //       value: _isNewTruck,
              //       onChanged: (value) {
              //         setState(() {
              //           _isNewTruck = value;
              //         });
              //       },
              //     ),
              //   ],
              // ),
              // For now, all reports are treated as potentially new by admin.
              // isNewTruck field is still sent.
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Submit Report'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: _submitReport,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}