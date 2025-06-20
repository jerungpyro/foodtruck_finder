import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For User type

import '../../services/auth_service.dart';

// Import the section widgets from their new files
import 'sections/admin_overview_section.dart';
import 'sections/food_truck_management_section.dart';
import 'sections/report_management_section.dart';
import 'sections/user_management_section.dart';

class AdminDashboardScreen extends StatefulWidget {
  final User adminUser;
  const AdminDashboardScreen({super.key, required this.adminUser});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  // Updated list to reference the imported section widgets
  static const List<Widget> _adminPanelSections = <Widget>[
    AdminOverviewSection(),
    FoodTruckManagementSection(),
    ReportManagementSection(),
    UserManagementSection(),
  ];

  void _onNavigationItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Close drawer if it's open (for mobile-like drawer behavior)
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentSectionTitle = "Overview"; // Default title
    switch (_selectedIndex) {
      // case 0: currentSectionTitle = "Overview"; break; // Already default
      case 1:
        currentSectionTitle = "Food Truck Management";
        break;
      case 2:
        currentSectionTitle = "Pending User Reports";
        break;
      case 3:
        currentSectionTitle = "User Management";
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSectionTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout Admin',
            onPressed: () async {
              await _authService.signOut();
              // AdminAuthWrapper will handle navigation
            },
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'FoodTruck Admin',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  Text(
                    widget.adminUser.displayName ??
                        widget.adminUser.email ??
                        'Admin',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            _buildDrawerItem(
                icon: Icons.dashboard_outlined,
                text: 'Overview',
                isSelected: _selectedIndex == 0,
                onTap: () => _onNavigationItemSelected(0)),
            _buildDrawerItem(
                icon: Icons.local_shipping_outlined,
                text: 'Food Trucks',
                isSelected: _selectedIndex == 1,
                onTap: () => _onNavigationItemSelected(1)),
            _buildDrawerItem(
                icon: Icons.flag_outlined,
                text: 'Pending Reports',
                isSelected: _selectedIndex == 2,
                onTap: () => _onNavigationItemSelected(2)),
            _buildDrawerItem(
                icon: Icons.people_alt_outlined,
                text: 'Users',
                isSelected: _selectedIndex == 3,
                onTap: () => _onNavigationItemSelected(3)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await _authService.signOut();
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _adminPanelSections,
      ),
    );
  }

  Widget _buildDrawerItem(
      {required IconData icon,
      required String text,
      required bool isSelected,
      required GestureTapCallback onTap}) {
    return ListTile(
      leading: Icon(icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).textTheme.bodySmall?.color),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      tileColor:
          isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
      selected: isSelected,
      onTap: onTap,
    );
  }
}