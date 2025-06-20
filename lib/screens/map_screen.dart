import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_truck_model.dart'; // Ensure this model is updated for all fields
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
  bool _isLoadingFoodTrucks = true;

  final Set<Marker> _markers = {};
  StreamSubscription? _foodTrucksSubscription;

  List<FoodTruck> _allFoodTrucks = [];
  List<FoodTruck> _filteredFoodTrucks = [];

  // --- Search State ---
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = "";

  // --- Filter State ---
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
      if (mounted) { // Check if widget is still in the tree
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
      _filterFoodTrucks();
    }
  }

  void _populateAvailableFoodTypes() {
    if (!mounted) return;
    final Set<String> types = {};
    for (var truck in _allFoodTrucks) {
      if (truck.type.isNotEmpty) {
        // Normalize type names for consistency if needed (e.g., capitalize first letter)
        // String normalizedType = truck.type[0].toUpperCase() + truck.type.substring(1).toLowerCase();
        // types.add(normalizedType);
        types.add(truck.type);
      }
    }
    if (mounted) {
      setState(() {
        _availableFoodTypes = types.toList()..sort(
          (a, b) => a.toLowerCase().compareTo(b.toLowerCase())
        );
      });
    }
  }

  void _filterFoodTrucks() {
    List<FoodTruck> trucksToDisplay;

    trucksToDisplay = List.from(_allFoodTrucks);

    if (_selectedFoodTypeFilter != null && _selectedFoodTypeFilter!.isNotEmpty) {
      trucksToDisplay = trucksToDisplay.where((truck) {
        return truck.type.toLowerCase() == _selectedFoodTypeFilter!.toLowerCase();
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      trucksToDisplay = trucksToDisplay.where((truck) {
        return truck.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               truck.type.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    if (mounted) {
      setState(() {
        _filteredFoodTrucks = trucksToDisplay;
      });
    }
    _createMarkersFromData(trucksToDisplay);
  }

  void _listenToFoodTruckUpdates() {
    print("[MapScreen] Subscribing to food truck updates...");
    if (mounted) {
      setState(() { _isLoadingFoodTrucks = true; });
    }

    _foodTrucksSubscription = FirebaseFirestore.instance
        .collection('foodTrucks')
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      print("[MapScreen] Received food truck data snapshot. Docs: ${snapshot.docs.length}");
      List<FoodTruck> fetchedTrucks = [];
      if (snapshot.docs.isNotEmpty) {
        try {
          fetchedTrucks = snapshot.docs
              .map((doc) => FoodTruck.fromFirestore(doc))
              .toList();
        } catch (e) {
          print("[MapScreen] Error parsing food truck data: $e");
          fetchedTrucks = []; 
        }
      } else {
        print("[MapScreen] No food trucks found in snapshot.");
      }
      
      if (mounted) {
        setState(() {
          _allFoodTrucks = fetchedTrucks;
          _populateAvailableFoodTypes();
        });
        _filterFoodTrucks(); 
        if (mounted) {
          setState(() { _isLoadingFoodTrucks = false; });
        }
      }

    }, onError: (error) {
      print("[MapScreen] Error listening to food truck updates: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Error loading food trucks: ${error.toString().substring(0, (error.toString().length > 100) ? 100 : error.toString().length)}...')));
        setState(() {
          _isLoadingFoodTrucks = false;
          _allFoodTrucks = [];
          _filteredFoodTrucks = [];
          _availableFoodTypes = [];
          _createMarkersFromData([]);
        });
      }
    });
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
            snippet: 'Type: ${truck.type}. Tap for details.',
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
    print("--- BottomSheet for Truck ID: ${truck.id} ---");
    print("Truck Name: ${truck.name}");
    print("Truck ReportedBy field (from truck object): '${truck.reportedBy}'");
    print("Truck Last Reported Date: ${truck.lastReported}");
    print("Truck Location Description: ${truck.locationDescription}");

    String formattedDateTime =
        "${truck.lastReported.toLocal().day.toString().padLeft(2, '0')}/${truck.lastReported.toLocal().month.toString().padLeft(2, '0')}/${truck.lastReported.toLocal().year} at ${truck.lastReported.toLocal().hour.toString().padLeft(2, '0')}:${truck.lastReported.toLocal().minute.toString().padLeft(2, '0')}";

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20.0, left: 20.0, right: 20.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                truck.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.category_outlined, "Type", truck.type),
              if (truck.locationDescription != null && truck.locationDescription!.isNotEmpty)
                 _buildDetailRow(Icons.description_outlined, "Description", truck.locationDescription!),
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
              fontSize: 16, fontWeight: FontWeight.w600,
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
    setState(() { _isLoadingLocation = true; });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        setState(() { _currentMapPosition = _defaultInitialPosition; _isLoadingLocation = false; });
      }
      if (_controllerCompleter.isCompleted) _animateToPosition(_currentMapPosition);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
          setState(() { _currentMapPosition = _defaultInitialPosition; _isLoadingLocation = false; });
        }
        if (_controllerCompleter.isCompleted) _animateToPosition(_currentMapPosition);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
        setState(() { _currentMapPosition = _defaultInitialPosition; _isLoadingLocation = false; });
      }
      if (_controllerCompleter.isCompleted) _animateToPosition(_currentMapPosition);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
        setState(() { _currentMapPosition = _defaultInitialPosition; _isLoadingLocation = false; });
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

  void _showFilterDialog() {
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Filter by Food Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_availableFoodTypes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("No types available to filter."),
                      ),
                    if (_availableFoodTypes.isNotEmpty)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0) // Adjust padding
                        ),
                        hint: const Text("All Types"),
                        value: tempSelectedType,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text("All Types"),
                          ),
                          ..._availableFoodTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                        ],
                        onChanged: (String? newValue) {
                          setDialogState(() {
                            tempSelectedType = newValue;
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Apply Filters'),
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _selectedFoodTypeFilter = tempSelectedType;
                      });
                    }
                    _filterFoodTrucks();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  AppBar _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (mounted) {
              setState(() {
                _isSearching = false;
                _searchController.clear(); // This also triggers _onSearchChanged -> _filterFoodTrucks
              });
            }
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by name or type...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              if (_searchController.text.isEmpty) {
                if (mounted) { setState(() { _isSearching = false; });}
              } else {
                _searchController.clear();
              }
            },
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
      );
    } else {
      return AppBar(
        title: Row( // Using Row to allow Chip next to title
          children: [
            Expanded(child: Text(widget.title)), // Title takes available space
            if (_selectedFoodTypeFilter != null && _selectedFoodTypeFilter!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Chip(
                  label: Text(_selectedFoodTypeFilter!, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: (){
                    if(mounted){
                      setState(() {
                        _selectedFoodTypeFilter = null;
                      });
                      _filterFoodTrucks();
                    }
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0), // Reduced vertical padding
                  labelPadding: const EdgeInsets.only(left: 6), // Adjust label padding
                  deleteIconColor: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              )
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: _selectedFoodTypeFilter != null ? Theme.of(context).colorScheme.primary : null),
            tooltip: 'Filter',
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              if (mounted) { setState(() { _isSearching = true; });}
            },
          ),
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
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showPrimaryLoader = _isLoadingFoodTrucks && _allFoodTrucks.isEmpty && _searchQuery.isEmpty && _selectedFoodTypeFilter == null;
    bool noResultsAfterFilterOrSearch = !_isLoadingFoodTrucks && _filteredFoodTrucks.isEmpty && (_searchQuery.isNotEmpty || _selectedFoodTypeFilter != null);

    return Scaffold(
      appBar: _buildAppBar(),
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
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),
          if (showPrimaryLoader)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
          if (noResultsAfterFilterOrSearch)
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _searchQuery.isNotEmpty 
                    ? 'No food trucks found for "$_searchQuery"${_selectedFoodTypeFilter != null ? " of type \"$_selectedFoodTypeFilter\"" : ""}' 
                    : 'No food trucks found for type "$_selectedFoodTypeFilter"',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getUserLocationAndCenterMap,
        tooltip: 'My Location',
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        child: _isLoadingLocation
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