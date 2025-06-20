import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For directions
import '../../models/food_truck_model.dart'; // Assuming your FoodTruck model is here

class FoodTruckDetailsBottomSheet extends StatelessWidget {
  final FoodTruck truck;
  final BuildContext parentContext; // To show SnackBars or use theme from MapScreen

  const FoodTruckDetailsBottomSheet({
    super.key,
    required this.truck,
    required this.parentContext, // Pass the MapScreen's context
  });

  Future<void> _launchDirections(double destinationLatitude, double destinationLongitude) async {
    // This logic can remain here or be passed in as a callback if it needs access to MapScreen's state
    // For now, keeping it self-contained using Geolocator directly.
    // Ensure Geolocator is imported if used here, or pass current location from MapScreen.
    // For simplicity, let's assume it's okay for the bottom sheet to handle this.
    // (Alternatively, pass a VoidCallback from MapScreen that already has origin info)

    String universalMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$destinationLatitude,$destinationLongitude&travelmode=driving';
    final Uri url = Uri.parse(universalMapsUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
      if (parentContext.mounted) { // Use parentContext for ScaffoldMessenger
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(content: Text('Could not open map application for directions.')),
        );
      }
    }
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) { // This context is for the bottom sheet itself
    String formattedDateTime =
        "${truck.lastReported.toLocal().day.toString().padLeft(2, '0')}/${truck.lastReported.toLocal().month.toString().padLeft(2, '0')}/${truck.lastReported.toLocal().year} at ${truck.lastReported.toLocal().hour.toString().padLeft(2, '0')}:${truck.lastReported.toLocal().minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: EdgeInsets.only(
        top: 20.0,
        left: 20.0,
        right: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.0, // Uses bottom sheet's context
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
          _buildDetailRow(context, Icons.category_outlined, "Type", truck.type),
          if (truck.locationDescription != null && truck.locationDescription!.isNotEmpty)
             _buildDetailRow(context, Icons.description_outlined, "Description", truck.locationDescription!),
          _buildDetailRow(context, Icons.person_pin_circle_outlined, "Reported by", truck.reportedBy),
          _buildDetailRow(context, Icons.timer_outlined, "Last Reported", formattedDateTime),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.directions_car_filled_outlined),
              label: const Text('Get Directions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.pop(context); // Close bottom sheet using its own context
                _launchDirections(truck.position.latitude, truck.position.longitude);
              },
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)),
              child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: () => Navigator.pop(context), // Close bottom sheet
            ),
          ),
        ],
      ),
    );
  }
}