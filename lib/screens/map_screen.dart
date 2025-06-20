import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// No longer need url_launcher here if bottom sheet handles it
// import 'package:url_launcher/url_launcher.dart'; 

import '../models/food_truck_model.dart';
import 'profile_screen.dart';
// Import the new custom widgets
import '../widgets/map_screen_widgets/food_truck_details_bottom_sheet.dart';
import '../widgets/map_screen_widgets/map_screen_app_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.title});
  final String title;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer<GoogleMapController>();

  static const LatLng _defaultInitialPosition = LatLng(37.4219983, -122.084);
  LatLng _currentMapPosition = _defaultInitialPosition;

  bool _isLoadingLocation = true;
  bool _isLoadingFoodTrucks = true;

  final Set<Marker> _markers = {};
  StreamSubscription? _foodTrucksSubscription;

  List<FoodTruck> _allFoodTrucks = [];
  List<FoodTruck> _filteredFoodTrucks = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = "";

  String? _selectedFoodTypeFilter;
  List<String> _availableFoodTypes = [];

  @override
  void initState() {
    super.initState();
    _listenToFoodTruckUpdates();
    _getUserLocationAndCenterMap();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _foodTrucksSubscription?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchQuery != _searchController.text) {
      if (mounted) {
        setState(() { _searchQuery = _searchController.text; });
      }
      _filterFoodTrucks();
    }
  }

  void _populateAvailableFoodTypes() {
    if (!mounted) return;
    final Set<String> types = {};
    for (var truck in _allFoodTrucks) {
      if (truck.type.isNotEmpty) { types.add(truck.type); }
    }
    if (mounted) {
      setState(() {
        _availableFoodTypes = types.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
    }
  }

  void _filterFoodTrucks() {
    List<FoodTruck> trucksToDisplay = List.from(_allFoodTrucks);
    if (_selectedFoodTypeFilter != null && _selectedFoodTypeFilter!.isNotEmpty) {
      trucksToDisplay = trucksToDisplay.where((truck) => truck.type.toLowerCase() == _selectedFoodTypeFilter!.toLowerCase()).toList();
    }
    if (_searchQuery.isNotEmpty) {
      trucksToDisplay = trucksToDisplay.where((truck) =>
          truck.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          truck.type.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (mounted) {
      setState(() { _filteredFoodTrucks = trucksToDisplay; });
    }
    _createMarkersFromData(trucksToDisplay);
  }

  void _listenToFoodTruckUpdates() {
    print("[MapScreen] Subscribing to food truck updates...");
    if (mounted) setState(() { _isLoadingFoodTrucks = true; });
    _foodTrucksSubscription = FirebaseFirestore.instance
        .collection('foodTrucks').where('isVerified', isEqualTo: true).snapshots()
        .listen((QuerySnapshot snapshot) {
      print("[MapScreen] Received food truck data snapshot. Docs: ${snapshot.docs.length}");
      List<FoodTruck> fetchedTrucks = [];
      if (snapshot.docs.isNotEmpty) {
        try {
          fetchedTrucks = snapshot.docs.map((doc) => FoodTruck.fromFirestore(doc)).toList();
        } catch (e) { print("[MapScreen] Error parsing food truck data: $e"); fetchedTrucks = []; }
      } else { print("[MapScreen] No food trucks found in snapshot."); }
      if (mounted) {
        setState(() { _allFoodTrucks = fetchedTrucks; _populateAvailableFoodTypes(); });
        _filterFoodTrucks();
        if (mounted) setState(() { _isLoadingFoodTrucks = false; });
      }
    }, onError: (error) {
      print("[MapScreen] Error listening to food truck updates: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading food trucks: ${error.toString().substring(0, 100)}...')));
        setState(() {
          _isLoadingFoodTrucks = false; _allFoodTrucks = []; _filteredFoodTrucks = []; _availableFoodTypes = [];
          _createMarkersFromData([]);
        });
      }
    });
  }

  void _createMarkersFromData(List<FoodTruck> trucks) {
    Set<Marker> tempMarkers = {};
    for (var truck in trucks) {
      tempMarkers.add(Marker(
        markerId: MarkerId(truck.id), position: truck.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: truck.name, snippet: 'Type: ${truck.type}. Tap for details.'),
        onTap: () => _showFoodTruckDetailsBottomSheet(truck),
      ));
    }
    if (mounted) setState(() { _markers.clear(); _markers.addAll(tempMarkers); });
  }

  // MODIFIED: Now calls the extracted widget
  void _showFoodTruckDetailsBottomSheet(FoodTruck truck) {
    // Debug prints can remain here or move to the widget if preferred
    print("--- BottomSheet for Truck ID: ${truck.id} (called from MapScreen) ---");
    print("Truck Name: ${truck.name}");
    print("Truck ReportedBy field (from truck object): '${truck.reportedBy}'");

    showModalBottomSheet(
      context: context, // Use MapScreen's context for showing the sheet
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0)),
      ),
      builder: (_) { // The builder context is specific to the bottom sheet
        return FoodTruckDetailsBottomSheet(truck: truck, parentContext: context);
      },
    );
  }

  // _buildDetailRow is now part of FoodTruckDetailsBottomSheet
  // _launchDirections is now part of FoodTruckDetailsBottomSheet or passed as a callback

  Future<void> _getUserLocationAndCenterMap() async { /* ... remains the same ... */
    if (!mounted) return;
    setState(() { _isLoadingLocation = true; });
    bool serviceEnabled; LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        setState(() { _currentMapPosition = _defaultInitialPosition; _isLoadingLocation = false; });
      }
      if (_controllerCompleter.isCompleted) _animateToPosition(_currentMapPosition); return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
          setState(() { _currentMapPosition = _defaultInitialPosition; _isLoadingLocation = false; });
        }
        if (_controllerCompleter.isCompleted) _animateToPosition(_currentMapPosition); return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
        setState(() { _currentMapPosition = _defaultInitialPosition; _isLoadingLocation = false; });
      }
      if (_controllerCompleter.isCompleted) _animateToPosition(_currentMapPosition); return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() { _currentMapPosition = LatLng(position.latitude, position.longitude); _isLoadingLocation = false; });
      }
      _animateToPosition(_currentMapPosition);
    } catch (e) {
      print("[MapScreen] Error getting location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
        setState(() { _currentMapPosition = _defaultInitialPosition; _isLoadingLocation = false; });
      }
      if (_controllerCompleter.isCompleted) _animateToPosition(_currentMapPosition);
    }
  }

  Future<void> _animateToPosition(LatLng position) async { /* ... remains the same ... */
    final GoogleMapController controller = await _controllerCompleter.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: position, zoom: 15.0)));
  }

  void _showFilterDialog() { /* ... remains the same ... */
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? tempSelectedType = _selectedFoodTypeFilter;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Filter Food Trucks'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Filter by Food Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_availableFoodTypes.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("No types available to filter.")),
                    if (_availableFoodTypes.isNotEmpty)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0)),
                        hint: const Text("All Types"), value: tempSelectedType, isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text("All Types")),
                          ..._availableFoodTypes.map((String type) => DropdownMenuItem<String>(value: type, child: Text(type))).toList(),
                        ],
                        onChanged: (String? newValue) => setDialogState(() => tempSelectedType = newValue),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
                ElevatedButton(
                  child: const Text('Apply Filters'),
                  onPressed: () {
                    if (mounted) setState(() => _selectedFoodTypeFilter = tempSelectedType);
                    _filterFoodTrucks(); Navigator.of(context).pop();
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  // _buildAppBar is now removed, using MapScreenAppBar widget

  @override
  Widget build(BuildContext context) {
    bool showPrimaryLoader = _isLoadingFoodTrucks && _allFoodTrucks.isEmpty && _searchQuery.isEmpty && _selectedFoodTypeFilter == null;
    bool noResultsAfterFilterOrSearch = !_isLoadingFoodTrucks && _filteredFoodTrucks.isEmpty && (_searchQuery.isNotEmpty || _selectedFoodTypeFilter != null);

    return Scaffold(
      // MODIFIED: Use the extracted AppBar widget
      appBar: MapScreenAppBar(
        title: widget.title,
        isSearching: _isSearching,
        searchController: _searchController,
        activeFilterDisplay: _selectedFoodTypeFilter,
        onSearchPressed: () {
          if (mounted) setState(() => _isSearching = true);
        },
        onFilterPressed: _showFilterDialog,
        onProfilePressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
        },
        onExitSearch: () {
          if (mounted) {
            setState(() { _isSearching = false; _searchController.clear(); /* This triggers _onSearchChanged -> _filterFoodTrucks */ });
          }
        },
        onClearActiveFilter: (){
          if(mounted){
            setState(() => _selectedFoodTypeFilter = null);
            _filterFoodTrucks();
          }
        },
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              if (!_controllerCompleter.isCompleted) _controllerCompleter.complete(controller);
              if (!_isLoadingLocation && _currentMapPosition != _defaultInitialPosition) _animateToPosition(_currentMapPosition);
            },
            initialCameraPosition: CameraPosition(target: _currentMapPosition, zoom: 11.0),
            markers: _markers, myLocationEnabled: true, myLocationButtonEnabled: false, zoomControlsEnabled: true,
          ),
          if (showPrimaryLoader) const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.orange))),
          if (noResultsAfterFilterOrSearch)
            Center(
              child: Container(
                margin: const EdgeInsets.all(20), padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(8.0)),
                child: Text(
                  _searchQuery.isNotEmpty ? 'No food trucks found for "$_searchQuery"${_selectedFoodTypeFilter != null ? " of type \"$_selectedFoodTypeFilter\"" : ""}' : 'No food trucks found for type "$_selectedFoodTypeFilter"',
                  style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getUserLocationAndCenterMap, tooltip: 'My Location',
        backgroundColor: Theme.of(context).colorScheme.secondary, foregroundColor: Theme.of(context).colorScheme.onSecondary,
        child: _isLoadingLocation ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Icon(Icons.my_location),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}