import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseException
import '../services/auth_service.dart'; // Uses the singleton AuthService
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Get the singleton instance of AuthService
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _errorMessage = '';
  bool _isLoading = false;

  void _login() async {
    print("[LoginScreen] Login button pressed.");
    if (_formKey.currentState!.validate()) {
      print("[LoginScreen] Form is valid.");
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }
      try {
        print("[LoginScreen] Calling AuthService.signInWithEmailAndPassword...");
        await _authService.signInWithEmailAndPassword(_email, _password);
        print("[LoginScreen] Sign-in call completed. AuthWrapper SHOULD handle navigation.");
      } on FirebaseAuthException catch (e) {
        print("[LoginScreen] FirebaseAuthException caught during login: ${e.message}");
         if (mounted) {
          setState(() {
            _errorMessage = e.message ?? "An error occurred during login.";
          });
        }
      } catch (e) {
        print("[LoginScreen] General error caught during login: $e");
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
          });
        }
      } finally {
        print("[LoginScreen] Login process finished (in finally block).");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      print("[LoginScreen] Form is invalid.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login - FoodTruck Finder')),
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
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
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
                        onPressed: _login,
                        child: const Text('Login'),
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Don\'t have an account? Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}