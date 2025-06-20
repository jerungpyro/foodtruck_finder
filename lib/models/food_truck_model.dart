import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodTruck {
  final String id;
  final String name;
  final String type;
  final LatLng position;
  final String reportedBy;          // This will hold lastReportedByDisplayName
  final DateTime lastReported;
  final String? locationDescription;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isVerified;

  FoodTruck({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    required this.reportedBy,
    required this.lastReported,
    this.locationDescription,
    this.createdAt,
    this.updatedAt,
    this.isVerified,
  });

  factory FoodTruck.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    GeoPoint geoPoint = data['position'] ?? const GeoPoint(0, 0);
    LatLng positionValue = LatLng(geoPoint.latitude, geoPoint.longitude);

    Timestamp? lastReportedTimestamp = data['lastReported'] as Timestamp?;
    DateTime lastReportedValue = lastReportedTimestamp?.toDate() ?? DateTime.now();

    String? locationDescriptionValue = data['locationDescription'] as String?;
    DateTime? createdAtValue = (data['createdAt'] as Timestamp?)?.toDate();
    DateTime? updatedAtValue = (data['updatedAt'] as Timestamp?)?.toDate();
    bool? isVerifiedValue = data['isVerified'] as bool?;

    // Debugging print statement for reportedBy
    String? displayNameFromData = data['lastReportedByDisplayName'] as String?;
    print("--- FoodTruck.fromFirestore ---");
    print("Doc ID: ${doc.id}, Truck Name: ${data['name'] ?? 'N/A'}");
    print("Raw 'lastReportedByDisplayName' from Firestore: '$displayNameFromData'");
    // End of Debugging

    return FoodTruck(
      id: doc.id,
      name: data['name'] ?? 'Unknown Name',
      type: data['type'] ?? 'Unknown Type',
      position: positionValue,
      reportedBy: displayNameFromData ?? 'Unknown Reporter', // Use the parsed displayNameFromData
      lastReported: lastReportedValue,
      locationDescription: locationDescriptionValue,
      createdAt: createdAtValue,
      updatedAt: updatedAtValue,
      isVerified: isVerifiedValue,
    );
  }
}