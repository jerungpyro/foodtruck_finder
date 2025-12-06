import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For directions
import '../../models/food_truck_model.dart';
import '../../screens/report_food_truck_screen.dart'; // To navigate to the report screen
import '../../theme/app_theme.dart';

class FoodTruckDetailsBottomSheet extends StatelessWidget {
  final FoodTruck truck;
  final BuildContext parentContext; // To show SnackBars or use theme from MapScreen

  const FoodTruckDetailsBottomSheet({
    super.key,
    required this.truck,
    required this.parentContext,
  });

  Future<void> _launchDirections(double destinationLatitude, double destinationLongitude) async {
    String universalMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$destinationLatitude,$destinationLongitude&travelmode=driving';
    final Uri url = Uri.parse(universalMapsUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(content: Text('Could not open map application for directions.')),
        );
      }
    }
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20.0, color: AppTheme.primary),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  truck.name,
                  style: AppTheme.heading2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                textStyle: AppTheme.button,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // Close bottom sheet using its own context
                _launchDirections(truck.position.latitude, truck.position.longitude);
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('Suggest Update'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primary, width: 1.5),
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: AppTheme.button,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // Close current bottom sheet
                Navigator.push(
                  parentContext, // Use parentContext (MapScreen's context) for navigation
                  MaterialPageRoute(
                    builder: (context) => ReportFoodTruckScreen(
                      existingTruck: truck, // Pass the existing truck data
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}