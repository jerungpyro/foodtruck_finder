import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/food_truck_model.dart';

class NearbyTrucksService {
  static const String _lastSeenTrucksKey = 'last_seen_trucks';
  static const String _lastCheckTimeKey = 'last_check_time';

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadiusKm = 6371.0;

    double lat1Rad = point1.latitude * pi / 180;
    double lat2Rad = point2.latitude * pi / 180;
    double deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    double deltaLonRad = (point2.longitude - point1.longitude) * pi / 180;

    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Get trucks within specified radius of user's location
  static List<FoodTruck> getTrucksNearby(
    List<FoodTruck> allTrucks,
    LatLng userLocation,
    double radiusKm,
  ) {
    return allTrucks.where((truck) {
      double distance = calculateDistance(userLocation, truck.position);
      return distance <= radiusKm;
    }).toList();
  }

  /// Save the IDs of currently visible trucks
  static Future<void> saveLastSeenTrucks(List<String> truckIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_lastSeenTrucksKey, truckIds);
    await prefs.setInt(_lastCheckTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get the IDs of previously seen trucks
  static Future<List<String>> getLastSeenTrucks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_lastSeenTrucksKey) ?? [];
  }

  /// Get the last check time
  static Future<DateTime?> getLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastCheckTimeKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Detect new trucks that weren't seen before
  static Future<List<FoodTruck>> detectNewTrucks(
    List<FoodTruck> currentNearbyTrucks,
  ) async {
    final lastSeenIds = await getLastSeenTrucks();
    
    // Find trucks that are in current list but not in last seen list
    final newTrucks = currentNearbyTrucks.where((truck) {
      return !lastSeenIds.contains(truck.id);
    }).toList();

    // Update the last seen list with current trucks
    final currentIds = currentNearbyTrucks.map((t) => t.id).toList();
    await saveLastSeenTrucks(currentIds);

    return newTrucks;
  }

  /// Check if enough time has passed since last check (to avoid spam)
  static Future<bool> shouldCheckForNewTrucks({Duration cooldown = const Duration(minutes: 15)}) async {
    final lastCheck = await getLastCheckTime();
    if (lastCheck == null) return true;
    
    final timeSinceLastCheck = DateTime.now().difference(lastCheck);
    return timeSinceLastCheck >= cooldown;
  }

  /// Get a summary message for new trucks
  static String getNewTrucksSummary(List<FoodTruck> newTrucks) {
    if (newTrucks.isEmpty) return '';
    
    if (newTrucks.length == 1) {
      return '🚚 New truck nearby: ${newTrucks.first.name}!';
    } else {
      return '🚚 ${newTrucks.length} new trucks discovered nearby!';
    }
  }

  /// Clear all saved data (useful for testing or user logout)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSeenTrucksKey);
    await prefs.remove(_lastCheckTimeKey);
  }
}
