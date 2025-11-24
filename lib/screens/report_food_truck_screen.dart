import 'dart:async';

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

  // Predefined food types
  static const List<String> _foodTypes = [
    'Burgers',
    'Tacos',
    'Pizza',
    'Coffee & Beverages',
    'Desserts & Ice Cream',
    'Asian Cuisine',
    'Malaysian Breakfast & Snacks',
    'BBQ & Grilled',
    'Sandwiches & Wraps',
    'Seafood',
    'Vegetarian & Vegan',
    'Middle Eastern',
    'Mexican',
    'Italian',
    'Fast Food',
    'Healthy & Organic',
    'Street Food',
    'Miscellaneous',
  ];

  // Form field controllers
  final TextEditingController _truckNameController = TextEditingController();
  final TextEditingController _locationDescriptionController = TextEditingController();
  String? _selectedFoodType;
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _userNotesController = TextEditingController();

  bool _isLoading = false;
  bool _isFetchingLocation = false;
  LatLng? _selectedLocation;
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();

  bool get _isUpdating => widget.existingTruck != null;

  @override
  void initState() {
    super.initState();
    if (_isUpdating) {
      _truckNameController.text = widget.existingTruck!.name;
      // Set selected food type if it exists in predefined list, otherwise default to Miscellaneous
      _selectedFoodType = _foodTypes.contains(widget.existingTruck!.type) 
          ? widget.existingTruck!.type 
          : 'Miscellaneous';
      _locationDescriptionController.text = widget.existingTruck!.locationDescription ?? '';
      _selectedLocation = widget.existingTruck!.position;
      _latitudeController.text = widget.existingTruck!.position.latitude.toStringAsFixed(7);
      _longitudeController.text = widget.existingTruck!.position.longitude.toStringAsFixed(7);
    } else if (widget.initialCoordinates != null) {
      _selectedLocation = widget.initialCoordinates;
      _latitudeController.text = widget.initialCoordinates!.latitude.toStringAsFixed(7);
      _longitudeController.text = widget.initialCoordinates!.longitude.toStringAsFixed(7);
    }
    
    // Get current location if no location is set
    if (_selectedLocation == null) {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _truckNameController.dispose();
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
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _latitudeController.text = position.latitude.toStringAsFixed(7);
          _longitudeController.text = position.longitude.toStringAsFixed(7);
          _isFetchingLocation = false;
        });
        
        // Animate map to location if controller is ready
        if (_mapController.isCompleted) {
          final controller = await _mapController.future;
          controller.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 15));
        }
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
    
    // Check if location is selected
    if (_selectedLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location on the map')),
        );
      }
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

    Map<String, dynamic> reportData = {
      'truckNameOrType': _truckNameController.text.trim(),
      'truckTypeSuggestion': _selectedFoodType ?? 'Miscellaneous',
      'locationDescription': _locationDescriptionController.text.trim(),
      'coordinates': GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isUpdating ? 'Suggest Update' : 'Report New Food Truck',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Icon
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isUpdating ? Icons.edit_location : Icons.add_location_alt,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isUpdating 
                        ? 'Update "${widget.existingTruck!.name}"' 
                        : 'Spot a Food Truck?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isUpdating 
                        ? 'Suggest changes for review by admins'
                        : 'Help others find great food!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Form Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Truck Details Card
                    _buildSectionCard(
                      title: 'Truck Details',
                      icon: Icons.local_shipping,
                      children: [
                        _buildTextField(
                          controller: _truckNameController,
                          label: 'Truck Name / Brand',
                          hint: 'e.g., Joe\'s Tacos, Coffee Express',
                          icon: Icons.storefront,
                          required: true,
                          validator: (value) => (value == null || value.trim().isEmpty) 
                              ? 'Please enter the truck name' 
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildFoodTypeDropdown(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _locationDescriptionController,
                          label: 'Location Description',
                          hint: 'e.g., Near Central Park entrance',
                          icon: Icons.place,
                          maxLines: 2,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Location Map Picker Card
                    _buildSectionCard(
                      title: 'Location',
                      icon: Icons.location_on,
                      children: [
                        Text(
                          'Tap on the map to select the food truck location',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Map Container
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _selectedLocation == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text('Loading map...'),
                                    ],
                                  ),
                                )
                              : GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: _selectedLocation!,
                                    zoom: 15,
                                  ),
                                  onMapCreated: (GoogleMapController controller) {
                                    if (!_mapController.isCompleted) {
                                      _mapController.complete(controller);
                                    }
                                  },
                                  onTap: (LatLng position) {
                                    setState(() {
                                      _selectedLocation = position;
                                      _latitudeController.text = position.latitude.toStringAsFixed(7);
                                      _longitudeController.text = position.longitude.toStringAsFixed(7);
                                    });
                                  },
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('selected_location'),
                                      position: _selectedLocation!,
                                      draggable: true,
                                      onDragEnd: (LatLng newPosition) {
                                        setState(() {
                                          _selectedLocation = newPosition;
                                          _latitudeController.text = newPosition.latitude.toStringAsFixed(7);
                                          _longitudeController.text = newPosition.longitude.toStringAsFixed(7);
                                        });
                                      },
                                      icon: BitmapDescriptor.defaultMarkerWithHue(
                                        BitmapDescriptor.hueOrange,
                                      ),
                                    ),
                                  },
                                  myLocationEnabled: true,
                                  myLocationButtonEnabled: true,
                                  zoomControlsEnabled: true,
                                  mapToolbarEnabled: false,
                                ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Use Current Location Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _isFetchingLocation
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.my_location_rounded, size: 20),
                            label: Text(
                              _isFetchingLocation 
                                  ? 'Getting Location...' 
                                  : 'Use My Current Location',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Additional Notes Card
                    _buildSectionCard(
                      title: 'Additional Notes',
                      icon: Icons.notes,
                      children: [
                        _buildTextField(
                          controller: _userNotesController,
                          label: 'Notes for Admin',
                          hint: _isUpdating 
                              ? 'Explain why this update is needed...'
                              : 'Any additional information...',
                          icon: Icons.edit_note,
                          maxLines: 4,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.send_rounded, size: 22),
                            label: Text(
                              _isUpdating ? 'Submit Update' : 'Submit Report',
                              style: const TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _submitReport,
                          ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 1,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon, 
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label${required ? " *" : ""}',
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, 
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, 
          vertical: 16,
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
  
  Widget _buildFoodTypeDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return DropdownButtonFormField<String>(
      value: _selectedFoodType,
      decoration: InputDecoration(
        labelText: 'Food Type *',
        hintText: 'Select food type',
        prefixIcon: const Icon(Icons.restaurant_rounded, size: 20),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, 
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, 
          vertical: 16,
        ),
      ),
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down_rounded),
      items: _foodTypes.map((String foodType) {
        return DropdownMenuItem<String>(
          value: foodType,
          child: Text(foodType),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedFoodType = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select a food type' : null,
    );
  }
}