// lib/screens/admin/admin_login_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For checking role

class AdminLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess; // Callback to notify parent
  const AdminLoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _loginAsAdmin() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; _errorMessage = ''; });
      try {
        final userCredential = await _authService.signInWithEmailAndPassword(_email, _password);
        if (userCredential?.user != null) {
          // Check user role from Firestore
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(userCredential!.user!.uid).get();
          if (userDoc.exists && userDoc.get('role') == 'admin') {
            print("[AdminLoginScreen] Admin login successful for ${userCredential.user!.email}");
            widget.onLoginSuccess(); // Notify parent (e.g., AdminAuthWrapper)
          } else {
            await _authService.signOut(); // Sign out if not an admin
            setState(() { _errorMessage = 'Access Denied: Not an admin user.';});
          }
        } else {
           setState(() { _errorMessage = 'Login failed. Please try again.';});
        }
      } catch (e) {
        print("[AdminLoginScreen] Error during admin login: $e");
        String displayError = "An error occurred.";
        if (e is FirebaseException) { displayError = e.message ?? "Firebase error."; }
        else if (e.toString().contains(']') && e.toString().split(']').length > 1) { displayError = e.toString().split(']')[1].trim(); }
        else { displayError = e.toString(); }
        setState(() { _errorMessage = displayError; });
      } finally {
        if (mounted) { setState(() { _isLoading = false; });}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8.0,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'FoodTruck Admin Login',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Admin Email', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value!.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
                      onChanged: (value) => _email = value.trim(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                      obscureText: true,
                      validator: (value) => value!.isEmpty || value.length < 6 ? 'Password too short' : null,
                      onChanged: (value) => _password = value.trim(),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
                      ),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _loginAsAdmin,
                            child: const Text('Login as Admin'),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}