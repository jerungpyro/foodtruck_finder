import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  // Helper function to launch URLs
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('Could not launch $urlString');
      // Optionally show a SnackBar to the user here
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title, {double topPadding = 24.0}) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTeamMemberTile(BuildContext context, String name) {
    return ListTile(
      leading: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
      title: Text(name),
      contentPadding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0),
    );
  }

  Widget _buildLinkTile(BuildContext context, IconData icon, String title, String url, {Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
      onTap: () => _launchURL(url),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About FoodTruck Finder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        children: <Widget>[
          // --- Original App Description Content ---
          Center(
            child: Icon(
              Icons.fastfood_outlined,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'FoodTruck Finder',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          const Center(
            child: Text(
              'Version 1.0.0', // Replace with your app version
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to FoodTruck Finder!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          const Text(
            'Our mission is to connect you with the best and most exciting food trucks in your area. Discover new tastes, track your favorites, and never miss out on a delicious street food experience again!',
            style: TextStyle(fontSize: 16, height: 1.5),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 20),
          const Text(
            'Key Features:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.map_outlined),
            title: Text('Real-time food truck locations on an interactive map.'),
            contentPadding: EdgeInsets.zero,
          ),
          const ListTile(
            leading: Icon(Icons.food_bank_outlined),
            title: Text('Details on food truck types and user reports.'),
            contentPadding: EdgeInsets.zero,
          ),
          const ListTile(
            leading: Icon(Icons.people_alt_outlined),
            title: Text('Crowdsourced reporting to keep information fresh and accurate.'),
             contentPadding: EdgeInsets.zero,
          ),
          // --- End of Original App Description Content ---

          const Divider(height: 40, thickness: 1), // Visual separator

          // --- Development Team and Useful Links ---
          _buildSectionTitle(context, 'Development Team', topPadding: 16.0),
          const Divider(),
          _buildTeamMemberTile(context, 'Badrul Muhammad Akasyah'),
          _buildTeamMemberTile(context, 'Wan Muhammad Azlan'),
          _buildTeamMemberTile(context, 'Sufyan'),
          _buildTeamMemberTile(context, 'Azwar Ansori'),

          _buildSectionTitle(context, 'Useful Links'),
          const Divider(),
          _buildLinkTile(
            context,
            Icons.code,
            'View Project on GitHub',
            'https://github.com/YOUR_USERNAME/YOUR_PROJECT_REPO', // Replace
          ),
          _buildLinkTile(
            context,
            Icons.bug_report,
            'Report an Issue',
            'https://github.com/YOUR_USERNAME/YOUR_PROJECT_REPO/issues', // Replace
            iconColor: Colors.redAccent,
          ),
          // --- End of Development Team and Useful Links ---

          const SizedBox(height: 40),
          Center(
            child: Text(
              '© ${DateTime.now().year} FoodTruck Finder. All rights reserved.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}