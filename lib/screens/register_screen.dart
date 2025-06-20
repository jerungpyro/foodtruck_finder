import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../widgets/auth_wrapper.dart'; // Import AuthWrapper

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _displayName = '';
  String _errorMessage = '';
  bool _isLoading = false;

  void _register() async {
    print("[RegisterScreen] Register button pressed.");
    if (_formKey.currentState!.validate()) {
      print("[RegisterScreen] Form is valid.");
      if (_password != _confirmPassword) {
        print("[RegisterScreen] Passwords do not match.");
        if (mounted) {
          setState(() {
            _errorMessage = 'Passwords do not match';
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }
      try {
        print("[RegisterScreen] Calling AuthService.registerWithEmailAndPassword...");
        bool success = await _authService.registerWithEmailAndPassword(_email, _password, _displayName);
        print("[RegisterScreen] Registration call completed. Success: $success");

        if (success) {
          print("[RegisterScreen] Registration successful. Navigating to AuthWrapper.");
          if (mounted) {
            // Navigate to a new instance of AuthWrapper, replacing all previous routes.
            // This forces AuthWrapper to evaluate the auth state fresh.
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthWrapper()),
              (Route<dynamic> route) => false, // Remove all previous routes
            );
          }
          return; // Exit after navigation
        }
        // If not successful, an exception should have been thrown and caught below.
        // This part should ideally not be reached if success is false without an exception.
        // For safety, ensure isLoading is handled.

      } on FirebaseAuthException catch (e) {
        print("[RegisterScreen] FirebaseAuthException caught during registration: ${e.message}");
        if (mounted) {
          setState(() {
            _errorMessage = e.message ?? "An error occurred during registration.";
          });
        }
      } catch (e) {
        print("[RegisterScreen] General error caught during registration: $e");
        if (mounted) {
          setState(() {
            _errorMessage = e.toString(); // Display the error message
          });
        }
      } finally {
        print("[RegisterScreen] Registration process finished (in finally block).");
        if (mounted && _isLoading) { // Only set if still loading (e.g. if navigation didn't happen)
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      print("[RegisterScreen] Form is invalid.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... build method remains the same as before ...
    return Scaffold(
      appBar: AppBar(title: const Text('Register - FoodTruck Finder')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'Enter your display name' : null,
                  onChanged: (value) => _displayName = value.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value!.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
                  onChanged: (value) => _email = value.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) =>
                      value!.isEmpty || value.length < 6 ? 'Password must be at least 6 characters' : null,
                  onChanged: (value) => _password = value.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? 'Confirm your password' : null,
                  onChanged: (value) => _confirmPassword = value.trim(),
                ),
                const SizedBox(height: 24),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                           textStyle: const TextStyle(fontSize: 18),
                        ),
                        onPressed: _register,
                        child: const Text('Register'),
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}