import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_truck_model.dart';
import 'profile_screen.dart';
import 'report_food_truck_screen.dart';
import '../widgets/map_screen_widgets/food_truck_details_bottom_sheet.dart';
import '../widgets/map_screen_widgets/map_screen_app_bar.dart';
import '../services/nearby_trucks_service.dart';

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

  MapType _currentMapType = MapType.normal;

  // Nearby trucks discovery
  List<FoodTruck> _newNearbyTrucks = [];
  bool _showNewTrucksBanner = false;
  LatLng? _userLocation;

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
        _availableFoodTypes = types.toList()..sort((a,b) => a.toLowerCase().compareTo(b.toLowerCase()));
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
        // Check for nearby trucks when data is loaded
        _checkForNearbyTrucks();
      }
    }, onError: (error) {
      print("[MapScreen] Error listening to food truck updates: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading food trucks: ${error.toString().substring(0, (error.toString().length > 100) ? 100 : error.toString().length)}...')));
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

  void _showFoodTruckDetailsBottomSheet(FoodTruck truck) {
    print("--- BottomSheet for Truck ID: ${truck.id} (called from MapScreen) ---");
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0)),
      ),
      builder: (_) {
        return FoodTruckDetailsBottomSheet(truck: truck, parentContext: context);
      },
    );
  }

  Future<void> _getUserLocationAndCenterMap() async {
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
        setState(() { 
          _currentMapPosition = LatLng(position.latitude, position.longitude);
          _userLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
      }
      _animateToPosition(_currentMapPosition);
      // Check for nearby trucks after getting location
      _checkForNearbyTrucks();
    } catch (e) {
      print("[MapScreen] Error getting location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
        setState(() { _currentMapPosition = _defaultInitialPosition; _isLoadingLocation = false; });
      }
      if (_controllerCompleter.isCompleted) _animateToPosition(_currentMapPosition);
    }
  }

  Future<void> _animateToPosition(LatLng position) async {
    final GoogleMapController controller = await _controllerCompleter.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: position, zoom: 15.0)));
  }

  Future<void> _checkForNearbyTrucks() async {
    if (_userLocation == null || _allFoodTrucks.isEmpty) return;

    // Check if enough time has passed since last check
    final shouldCheck = await NearbyTrucksService.shouldCheckForNewTrucks();
    if (!shouldCheck) return;

    // Get trucks within 2km radius
    final nearbyTrucks = NearbyTrucksService.getTrucksNearby(
      _allFoodTrucks,
      _userLocation!,
      2.0, // 2km radius
    );

    // Detect new trucks
    final newTrucks = await NearbyTrucksService.detectNewTrucks(nearbyTrucks);

    if (newTrucks.isNotEmpty && mounted) {
      setState(() {
        _newNearbyTrucks = newTrucks;
        _showNewTrucksBanner = true;
      });

      // Auto-hide banner after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _showNewTrucksBanner = false;
          });
        }
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? tempSelectedType = _selectedFoodTypeFilter;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Filter Food Trucks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Filter by Food Type:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                if (_availableFoodTypes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 12),
                        Text(
                          "No types available to filter",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                if (_availableFoodTypes.isNotEmpty)
                  StatefulBuilder(
                    builder: (context, setDialogState) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            prefixIcon: Icon(
                              Icons.restaurant_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          hint: const Text("All Types"),
                          value: tempSelectedType,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text("All Types", style: TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            ..._availableFoodTypes.map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                          ],
                          onChanged: (String? newValue) {
                            setDialogState(() => tempSelectedType = newValue);
                          },
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Apply Filters'),
                      onPressed: () {
                        if (mounted) setState(() => _selectedFoodTypeFilter = tempSelectedType);
                        _filterFoodTrucks();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMapTypeSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        MapType selectedTypeInDialog = _currentMapType;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.layers_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Map Style',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Column(
                      children: [
                        _buildMapStyleOption(
                          context: context,
                          icon: Icons.map_rounded,
                          title: 'Normal',
                          description: 'Standard road map',
                          mapType: MapType.normal,
                          selectedType: selectedTypeInDialog,
                          onChanged: (value) => setDialogState(() => selectedTypeInDialog = value!),
                        ),
                        const SizedBox(height: 8),
                        _buildMapStyleOption(
                          context: context,
                          icon: Icons.satellite_alt_rounded,
                          title: 'Satellite',
                          description: 'Aerial imagery',
                          mapType: MapType.satellite,
                          selectedType: selectedTypeInDialog,
                          onChanged: (value) => setDialogState(() => selectedTypeInDialog = value!),
                        ),
                        const SizedBox(height: 8),
                        _buildMapStyleOption(
                          context: context,
                          icon: Icons.layers_rounded,
                          title: 'Hybrid',
                          description: 'Satellite with labels',
                          mapType: MapType.hybrid,
                          selectedType: selectedTypeInDialog,
                          onChanged: (value) => setDialogState(() => selectedTypeInDialog = value!),
                        ),
                        const SizedBox(height: 8),
                        _buildMapStyleOption(
                          context: context,
                          icon: Icons.terrain_rounded,
                          title: 'Terrain',
                          description: 'Topographic features',
                          mapType: MapType.terrain,
                          selectedType: selectedTypeInDialog,
                          onChanged: (value) => setDialogState(() => selectedTypeInDialog = value!),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Apply'),
                      onPressed: () {
                        if (mounted) setState(() => _currentMapType = selectedTypeInDialog);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapStyleOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required MapType mapType,
    required MapType selectedType,
    required ValueChanged<MapType?> onChanged,
  }) {
    final isSelected = selectedType == mapType;
    return InkWell(
      onTap: () => onChanged(mapType),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: Colors.grey[400],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToReportTruckScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportFoodTruckScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showPrimaryLoader = _isLoadingFoodTrucks && _allFoodTrucks.isEmpty && _searchQuery.isEmpty && _selectedFoodTypeFilter == null;
    bool noResultsAfterFilterOrSearch = !_isLoadingFoodTrucks && _filteredFoodTrucks.isEmpty && (_searchQuery.isNotEmpty || _selectedFoodTypeFilter != null);

    return Scaffold(
      appBar: MapScreenAppBar( // Instantiating the custom AppBar
        title: widget.title,
        isSearching: _isSearching,
        searchController: _searchController,
        activeFilterDisplay: _selectedFoodTypeFilter,
        onMapStylePressed: _showMapTypeSelectionDialog,
        // onReportTruckPressed is NOT passed here, as it's handled by a FAB now
        onSearchPressed: () {
          if (mounted) setState(() => _isSearching = true);
        },
        onFilterPressed: _showFilterDialog,
        onProfilePressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
        },
        onExitSearch: () {
          if (mounted) {
            setState(() { _isSearching = false; _searchController.clear(); });
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
            mapType: _currentMapType,
            onMapCreated: (GoogleMapController controller) {
              if (!_controllerCompleter.isCompleted) _controllerCompleter.complete(controller);
              if (!_isLoadingLocation && _currentMapPosition != _defaultInitialPosition) _animateToPosition(_currentMapPosition);
            },
            initialCameraPosition: CameraPosition(target: _currentMapPosition, zoom: 11.0),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            padding: const EdgeInsets.only(bottom: 140.0, right: 0.0), // For stacked FABs
          ),
          if (showPrimaryLoader)
            const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.orange))),
          if (noResultsAfterFilterOrSearch)
            Center(
              child: Container(
                margin: const EdgeInsets.all(20), padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(8.0)),
                child: Text(
                  _searchQuery.isNotEmpty 
                    ? 'No food trucks found for "$_searchQuery"${_selectedFoodTypeFilter != null ? " of type \"$_selectedFoodTypeFilter\"" : ""}' 
                    : 'No food trucks found for type "$_selectedFoodTypeFilter"',
                  style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center,
                ),
              ),
            ),
          // Nearby Trucks Discovery Banner
          if (_showNewTrucksBanner && _newNearbyTrucks.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange[700]!,
                        Colors.orange[500]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              NearbyTrucksService.getNewTrucksSummary(_newNearbyTrucks),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_newNearbyTrucks.length == 1)
                              Text(
                                _newNearbyTrucks.first.type,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _showNewTrucksBanner = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'reportTruckFab',
              onPressed: _navigateToReportTruckScreen,
              tooltip: 'Report New Food Truck',
              elevation: 4,
              label: const Text(
                'Report',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              icon: const Icon(Icons.add_location_alt_rounded, size: 22),
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'myLocationFab',
              onPressed: _getUserLocationAndCenterMap,
              tooltip: 'My Location',
              elevation: 4,
              backgroundColor: Colors.white,
              child: _isLoadingLocation
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.my_location_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 26,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}