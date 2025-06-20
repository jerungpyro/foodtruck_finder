import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For User
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng

import '../../../models/food_truck_model.dart';
import '../../../services/auth_service.dart'; // To get current admin user

class FoodTruckManagementSection extends StatefulWidget {
  const FoodTruckManagementSection({super.key});

  @override
  State<FoodTruckManagementSection> createState() =>
      _FoodTruckManagementSectionState();
}

class _FoodTruckManagementSectionState
    extends State<FoodTruckManagementSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _showFoodTruckFormDialog({FoodTruck? foodTruck}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: foodTruck?.name ?? '');
    final typeController = TextEditingController(text: foodTruck?.type ?? '');
    final descriptionController = TextEditingController(
        text: foodTruck?.locationDescription ?? ''); // Ensure model has this
    final latController = TextEditingController(
        text: foodTruck?.position.latitude.toString() ?? '');
    final longController = TextEditingController(
        text: foodTruck?.position.longitude.toString() ?? '');

    double? latitude = foodTruck?.position.latitude;
    double? longitude = foodTruck?.position.longitude;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title:
              Text(foodTruck == null ? 'Add New Food Truck' : 'Edit Food Truck'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Name / Brand'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a name' : null,
                  ),
                  TextFormField(
                    controller: typeController,
                    decoration: const InputDecoration(
                        labelText: 'Type (e.g., BBQ, Tacos)'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a type' : null,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration:
                        const InputDecoration(labelText: 'Location Description'),
                    maxLines: 2,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: latController,
                          decoration:
                              const InputDecoration(labelText: 'Latitude'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            final num = double.tryParse(value);
                            if (num == null) return 'Invalid number';
                            if (num < -90 || num > 90) return 'Range: -90 to 90';
                            return null;
                          },
                          onChanged: (value) => latitude = double.tryParse(value), // Update local var
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: longController,
                          decoration:
                              const InputDecoration(labelText: 'Longitude'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          validator: (value) {
                             if (value == null || value.isEmpty) return 'Required';
                            final num = double.tryParse(value);
                            if (num == null) return 'Invalid number';
                            if (num < -180 || num > 180) return 'Range: -180 to 180';
                            return null;
                          },
                           onChanged: (value) => longitude = double.tryParse(value), // Update local var
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: Text(foodTruck == null ? 'Add Truck' : 'Save Changes'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // Ensure lat/long are parsed from controllers if not updated by onChanged
                  latitude = double.tryParse(latController.text);
                  longitude = double.tryParse(longController.text);

                  if (latitude == null || longitude == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Latitude and Longitude must be valid numbers.')));
                    return;
                  }

                  final User? adminUser = AuthService().getCurrentUser();
                  final now = Timestamp.now();

                  // Prepare data, ensuring locationDescription is handled
                  Map<String, dynamic> truckData = {
                    'name': nameController.text,
                    'type': typeController.text,
                    'locationDescription': descriptionController.text,
                    'position': GeoPoint(latitude!, longitude!),
                    // Preserve original report time if editing, else use now
                    'lastReported': foodTruck?.lastReported != null ? Timestamp.fromDate(foodTruck!.lastReported) : now,
                    'lastReportedByUserId': adminUser?.uid ?? 'admin_console',
                    'lastReportedByDisplayName': adminUser?.displayName ?? 'Admin',
                    'isVerified': true,
                    'updatedAt': now,
                    // Set createdAt only for new trucks, preserve if editing
                    if (foodTruck == null) 'createdAt': now,
                    if (foodTruck != null && foodTruck.createdAt != null)
                         'createdAt': Timestamp.fromDate(foodTruck.createdAt!),
                  };


                  try {
                    if (foodTruck == null) {
                      await _firestore
                          .collection('foodTrucks')
                          .add(truckData);
                      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Food truck added successfully!')));
                    } else {
                      await _firestore
                          .collection('foodTrucks')
                          .doc(foodTruck.id)
                          .update(truckData);
                      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Food truck updated successfully!')));
                    }
                    Navigator.of(dialogContext).pop();
                  } catch (e) {
                    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving food truck: $e')));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore.collection('foodTrucks').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No food trucks found. Add one!'));
          }

          List<FoodTruck> foodTrucks = snapshot.data!.docs
              .map((doc) => FoodTruck.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: foodTrucks.length,
            itemBuilder: (context, index) {
              FoodTruck truck = foodTrucks[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: Icon(Icons.local_shipping,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(truck.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "${truck.type}\n${truck.locationDescription ?? ''}\nLat: ${truck.position.latitude.toStringAsFixed(4)}, Lng: ${truck.position.longitude.toStringAsFixed(4)}\nReported: ${truck.lastReported.toLocal().toString().substring(0, 16)} by ${truck.reportedBy}"),
                  isThreeLine: (truck.locationDescription ?? '').isNotEmpty, // Make it three lines if description exists
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.blue),
                        tooltip: 'Edit',
                        onPressed: () {
                          _showFoodTruckFormDialog(foodTruck: truck);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () async {
                          bool? deleteConfirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext dialogContext) =>
                                AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: Text(
                                  'Are you sure you want to delete ${truck.name}?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (deleteConfirmed == true) {
                            try {
                              await _firestore
                                  .collection('foodTrucks')
                                  .doc(truck.id)
                                  .delete();
                              if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(
                                          '${truck.name} deleted successfully!')));
                            } catch (e) {
                              if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Error deleting truck: $e')));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showFoodTruckFormDialog();
        },
        label: const Text('Add Food Truck'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}