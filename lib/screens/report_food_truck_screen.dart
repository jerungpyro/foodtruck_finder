import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/auth_service.dart';
import '../models/food_truck_model.dart'; // Import FoodTruck model

class ReportFoodTruckScreen extends StatefulWidget {
  final LatLng? initialCoordinates;
  final FoodTruck? existingTruck; // New parameter for updates

  const ReportFoodTruckScreen({
    super.key,
    this.initialCoordinates,
    this.existingTruck,
  });

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

  bool _isLoading = false;
  bool _isFetchingLocation = false;

  bool get _isUpdating => widget.existingTruck != null;

  @override
  void initState() {
    super.initState();
    if (_isUpdating) {
      _truckNameController.text = widget.existingTruck!.name;
      _truckTypeController.text = widget.existingTruck!.type;
      _locationDescriptionController.text = widget.existingTruck!.locationDescription ?? '';
      _latitudeController.text = widget.existingTruck!.position.latitude.toStringAsFixed(7);
      _longitudeController.text = widget.existingTruck!.position.longitude.toStringAsFixed(7);
    } else if (widget.initialCoordinates != null) {
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
        if (mounted) setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
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

    Map<String, dynamic> reportData = {
      'truckNameOrType': _truckNameController.text.trim(),
      'truckTypeSuggestion': _truckTypeController.text.trim(),
      'locationDescription': _locationDescriptionController.text.trim(),
      'coordinates': GeoPoint(latitude, longitude),
      'userNotes': _userNotesController.text.trim(),
      'status': 'pending',
      'reportedByUserId': currentUser.uid,
      'reportedByDisplayName': currentUser.displayName ?? 'Anonymous User',
      'reportedAt': Timestamp.now(),
      'reportType': _isUpdating ? 'update_suggestion' : 'new_submission',
      if (_isUpdating) 'existingFoodTruckId': widget.existingTruck!.id,
      'isNewTruck': !_isUpdating, // This field helps admin differentiate if not checking reportType
    };

    try {
      await _firestore.collection('reports').add(reportData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isUpdating ? 'Update suggestion submitted for review!' : 'New truck report submitted for review!')));
        Navigator.of(context).pop();
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
        title: Text(_isUpdating ? 'Suggest Update for Truck' : 'Report New Food Truck'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_isUpdating)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "Suggesting update for: ${widget.existingTruck!.name}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextFormField(
                controller: _truckNameController,
                decoration: InputDecoration(labelText: 'Food Truck Name / Brand${_isUpdating ? " (Suggested)" : "*"}', border: const OutlineInputBorder()),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter the truck name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _truckTypeController,
                decoration: InputDecoration(labelText: 'Food Type (e.g., Tacos, Coffee)${_isUpdating ? " (Suggested)" : "*"}', border: const OutlineInputBorder()),
                 validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter the food type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationDescriptionController,
                decoration: InputDecoration(labelText: 'Location Description${_isUpdating ? " (Suggested)" : ""}', border: const OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Text("Location Coordinates${_isUpdating ? " (Suggested New)" : "*"}", style: Theme.of(context).textTheme.titleMedium),
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
                        final numval = double.tryParse(value);
                        if (numval == null) return 'Invalid number';
                        if (numval < -90 || numval > 90) return 'Range: -90 to 90';
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
                        final numval = double.tryParse(value);
                        if (numval == null) return 'Invalid number';
                        if (numval < -180 || numval > 180) return 'Range: -180 to 180';
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _userNotesController,
                decoration: InputDecoration(labelText: 'Notes for Admin (e.g., reason for update)', border: const OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: Text(_isUpdating ? 'Submit Update Suggestion' : 'Submit New Report'),
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