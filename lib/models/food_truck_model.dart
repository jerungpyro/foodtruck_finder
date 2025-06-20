import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodTruck {
  final String id;
  final String name;
  final String type;
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

  factory FoodTruck.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    GeoPoint geoPoint = data['position'] ?? const GeoPoint(0, 0); // Default if null
    LatLng positionValue = LatLng(geoPoint.latitude, geoPoint.longitude);

    Timestamp timestamp = data['lastReported'] ?? Timestamp.now(); // Default if null
    DateTime lastReportedValue = timestamp.toDate();

    return FoodTruck(
      id: doc.id,
      name: data['name'] ?? 'Unknown Name',
      type: data['type'] ?? 'Unknown Type',
      position: positionValue,
      reportedBy: data['reportedBy'] ?? 'Unknown Reporter',
      lastReported: lastReportedValue,
    );
  }
}