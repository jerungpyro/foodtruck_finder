import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For User type

import '../../../models/report_model.dart';
import '../../../services/auth_service.dart'; // To get current admin user

class ReportManagementSection extends StatefulWidget {
  const ReportManagementSection({super.key});

  @override
  State<ReportManagementSection> createState() =>
      _ReportManagementSectionState();
}

class _ReportManagementSectionState extends State<ReportManagementSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService(); // Use the singleton

  Future<void> _approveReport(FoodTruckReport report) async {
    print(
        "[ReportManagement] Approving report: ${report.id} - ${report.truckNameOrType}");
    final User? adminUser = _authService.getCurrentUser();

    if (adminUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Admin session error. Please re-login.')));
      }
      return;
    }

    // 1. Prepare data for the 'foodTrucks' collection from the report
    final Map<String, dynamic> newVerifiedFoodTruckData = {
      'name': report.truckNameOrType,
      'type': report.truckNameOrType.toLowerCase().contains("coffee") ? "Coffee" :
            report.truckNameOrType.toLowerCase().contains("bbq") ? "BBQ" :
            report.truckNameOrType.toLowerCase().contains("taco") ? "Tacos" :
            report.truckNameOrType.toLowerCase().contains("nasi lemak") ? "Nasi Lemak" :
            report.truckNameOrType.toLowerCase().contains("cendol") ? "Dessert" :
            report.truckNameOrType.toLowerCase().contains("satay") ? "Satay" :
            "Miscellaneous",
      'locationDescription': report.locationDescription ?? '',
      'position': GeoPoint(report.coordinates.latitude, report.coordinates.longitude),
      'lastReported': Timestamp.fromDate(report.reportedAt),
      'lastReportedByUserId': report.reportedByUserId,
      'lastReportedByDisplayName': report.reportedByDisplayName,
      'isVerified': true,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'sourceReportId': report.id,
    };

    try {
      // 2. Add the new food truck to the 'foodTrucks' collection
      DocumentReference addedTruckRef = await _firestore.collection('foodTrucks').add(newVerifiedFoodTruckData);
      print("[ReportManagement] New verified food truck added with ID: ${addedTruckRef.id}");

      // 3. Update the status of the original report in the 'reports' collection
      await _firestore.collection('reports').doc(report.id).update({
        'status': 'approved',
        'adminNotes': 'Approved by ${adminUser.displayName ?? adminUser.email}. Truck ID: ${addedTruckRef.id}',
        'processedAt': Timestamp.now(),
        'processedByAdminId': adminUser.uid,
        'linkedFoodTruckId': addedTruckRef.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Report for ${report.truckNameOrType} approved. New food truck added.')));
      }
    } catch (e) {
      print("[ReportManagement] Error approving report and creating food truck: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing approval: $e')));
      }
    }
  }

  Future<void> _rejectReport(FoodTruckReport report) async {
    print(
        "[ReportManagement] Rejecting report: ${report.id} - ${report.truckNameOrType}");
    final User? adminUser = _authService.getCurrentUser();
    try {
      await _firestore.collection('reports').doc(report.id).update({
        'status': 'rejected',
        'adminNotes':
            'Rejected by ${adminUser?.displayName ?? adminUser?.email ?? "Admin"}.',
        'processedAt': Timestamp.now(),
        'processedByAdminId': adminUser?.uid,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Report for ${report.truckNameOrType} rejected.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error rejecting report: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar here as it's part of AdminDashboardScreen
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('reports')
            .where('status', isEqualTo: 'pending')
            .orderBy('reportedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending reports found.'));
          }

          List<FoodTruckReport> reports = snapshot.data!.docs
              .map((doc) => FoodTruckReport.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              FoodTruckReport report = reports[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.truckNameOrType,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                          "Reported by: ${report.reportedByDisplayName} (${report.reportedByUserId.length > 6 ? report.reportedByUserId.substring(0, 6) : report.reportedByUserId}...)"),
                      Text(
                          "Reported at: ${report.reportedAt.toLocal().toString().substring(0, 16)}"),
                      if (report.locationDescription != null &&
                          report.locationDescription!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text("Description: ${report.locationDescription}"),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                            "Coordinates: ${report.coordinates.latitude.toStringAsFixed(5)}, ${report.coordinates.longitude.toStringAsFixed(5)}"),
                      ),
                      if (report.userNotes != null &&
                          report.userNotes!.isNotEmpty)
                        Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text("User Notes: \"${report.userNotes}\"",
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic))),
                      if (report.isNewTruck == true)
                        const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Text("Marked as new truck by user.",
                                style: TextStyle(color: Colors.blueGrey, fontSize: 12))),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.red),
                              label: const Text('Reject',
                                  style: TextStyle(color: Colors.red)),
                              onPressed: () => _rejectReport(report)),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                              icon: const Icon(
                                  Icons.check_circle_outline_rounded),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white),
                              onPressed: () => _approveReport(report)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}