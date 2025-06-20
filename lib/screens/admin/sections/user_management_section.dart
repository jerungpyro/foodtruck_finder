// lib/screens/admin/sections/user_management_section.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

// AdminDisplayedUser model remains the same
class AdminDisplayedUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? role;
  final DateTime? createdAt;

  AdminDisplayedUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.role,
    this.createdAt,
  });

  factory AdminDisplayedUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AdminDisplayedUser(
      uid: doc.id,
      email: data['email'] ?? 'N/A',
      displayName: data['displayName'] as String?,
      role: data['role'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class UserManagementSection extends StatefulWidget {
  const UserManagementSection({super.key});

  @override
  State<UserManagementSection> createState() => _UserManagementSectionState();
}

class _UserManagementSectionState extends State<UserManagementSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy hh:mm a');

  Future<void> _changeUserRole(AdminDisplayedUser user) async {
    final String currentRole = user.role ?? 'user';
    final String newRole = currentRole == 'admin' ? 'user' : 'admin';

    // Confirmation Dialog
    bool? confirmChange = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Role Change'),
          content: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(dialogContext).style.copyWith(fontSize: 16),
              children: <TextSpan>[
                const TextSpan(text: 'Are you sure you want to change the role of '),
                TextSpan(
                    text: user.displayName ?? user.email,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: ' from '),
                TextSpan(
                    text: currentRole,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: ' to '),
                TextSpan(
                    text: newRole,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: Text('Confirm Change to $newRole', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmChange == true) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'role': newRole});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  "${user.displayName ?? user.email}'s role changed to $newRole.")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error changing role: $e")));
        }
        print("Error changing role for ${user.uid}: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          List<AdminDisplayedUser> users = snapshot.data!.docs
              .map((doc) => AdminDisplayedUser.fromFirestore(doc))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              AdminDisplayedUser user = users[index];
              bool isAdmin = user.role == 'admin';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAdmin ? Colors.amber[700] : Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    isAdmin ? Icons.shield_outlined : Icons.person_outline,
                    color: isAdmin ? Colors.white : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(user.displayName ?? 'No Display Name',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${user.email}'),
                    Text('UID: ${user.uid}'),
                    Text('Role: ${user.role ?? 'user'}', style: TextStyle(fontWeight: isAdmin ? FontWeight.bold : FontWeight.normal, color: isAdmin ? Colors.amber[800] : null)),
                    if (user.createdAt != null)
                      Text(
                          'Joined: ${_dateFormatter.format(user.createdAt!.toLocal())}'),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: "User Actions",
                  onSelected: (value) {
                    if (value == 'changeRole') {
                      _changeUserRole(user); // Call the implemented function
                    } else if (value == 'viewDetails') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('View user details TBD.')));
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'viewDetails',
                      child: ListTile(
                          leading: Icon(Icons.visibility_outlined), title: Text('View Details')),
                    ),
                    PopupMenuItem<String>(
                      value: 'changeRole',
                      child: ListTile(
                          leading: Icon(isAdmin ? Icons.person_remove_outlined : Icons.admin_panel_settings_outlined),
                          title: Text(isAdmin ? 'Demote to User' : 'Promote to Admin')),
                    ),
                  ],
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}