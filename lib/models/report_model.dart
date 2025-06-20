// lib/models/report_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng

enum ReportStatus { pending, approved, rejected, unknown }

class FoodTruckReport {
  final String id;
  final String reportedByUserId;
  final String reportedByDisplayName;
  final DateTime reportedAt;
  final String truckNameOrType;
  final String? locationDescription;
  final LatLng coordinates;
  final String? userNotes;
  final ReportStatus status;
  final String? adminNotes; // For admin's reason for approval/rejection
  final bool? isNewTruck; // Indication from user if it's a new truck

  FoodTruckReport({
    required this.id,
    required this.reportedByUserId,
    required this.reportedByDisplayName,
    required this.reportedAt,
    required this.truckNameOrType,
    this.locationDescription,
    required this.coordinates,
    this.userNotes,
    required this.status,
    this.adminNotes,
    this.isNewTruck,
  });

  factory FoodTruckReport.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    GeoPoint geoPoint = data['coordinates'] ?? const GeoPoint(0,0);
    LatLng coords = LatLng(geoPoint.latitude, geoPoint.longitude);

    ReportStatus currentStatus;
    switch (data['status']?.toLowerCase()) {
      case 'pending':
        currentStatus = ReportStatus.pending;
        break;
      case 'approved':
        currentStatus = ReportStatus.approved;
        break;
      case 'rejected':
        currentStatus = ReportStatus.rejected;
        break;
      default:
        currentStatus = ReportStatus.unknown;
    }

    return FoodTruckReport(
      id: doc.id,
      reportedByUserId: data['reportedByUserId'] ?? '',
      reportedByDisplayName: data['reportedByDisplayName'] ?? 'Unknown User',
      reportedAt: (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      truckNameOrType: data['truckNameOrType'] ?? 'Unknown Truck',
      locationDescription: data['locationDescription'],
      coordinates: coords,
      userNotes: data['userNotes'],
      status: currentStatus,
      adminNotes: data['adminNotes'],
      isNewTruck: data['isNewTruck'] as bool?,
    );
  }

  String get statusToString {
    switch (status) {
      case ReportStatus.pending: return 'Pending';
      case ReportStatus.approved: return 'Approved';
      case ReportStatus.rejected: return 'Rejected';
      default: return 'Unknown';
    }
  }
}