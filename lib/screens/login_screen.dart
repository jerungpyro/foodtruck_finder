import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseException
import '../services/auth_service.dart'; // Uses the singleton AuthService
import 'register_screen.dart';
import '../widgets/glass_container.dart';

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
  bool _obscurePassword = true;

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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          GlassGradientBackground(
            colors: [
              colorScheme.primary.withOpacity(0.1),
              Colors.orange[200]!.withOpacity(0.2),
              Colors.purple[100]!.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Hero Icon
                      GlassContainer(
                        padding: const EdgeInsets.all(28),
                        margin: const EdgeInsets.symmetric(horizontal: 80),
                        blur: 15,
                        opacity: 0.2,
                        borderRadius: BorderRadius.circular(100),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacity(0.3),
                            colorScheme.primary.withOpacity(0.1),
                          ],
                        ),
                        child: Icon(
                          Icons.local_shipping_rounded,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                
                // Welcome Text
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue finding food trucks',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Email Field Card
                GlassContainer(
                  padding: const EdgeInsets.all(4.0),
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  blur: 15,
                  opacity: 0.2,
                  borderRadius: BorderRadius.circular(18),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      prefixIcon: Icon(
                        Icons.email_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.red[400]!),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value!.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
                    onChanged: (value) => _email = value.trim(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password Field Card
                GlassContainer(
                  padding: const EdgeInsets.all(4.0),
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  blur: 15,
                  opacity: 0.2,
                  borderRadius: BorderRadius.circular(18),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      prefixIcon: Icon(
                        Icons.lock_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword 
                              ? Icons.visibility_rounded 
                              : Icons.visibility_off_rounded,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.red[400]!),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) =>
                        value!.isEmpty || value.length < 6 ? 'Password must be at least 6 characters' : null,
                    onChanged: (value) => _password = value.trim(),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Error Message
                if (_errorMessage.isNotEmpty)
                  GlassContainer(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    blur: 10,
                    opacity: 0.15,
                    color: Colors.red[300],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red[300]!.withOpacity(0.3), width: 1.5),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Login Button
                _isLoading
                    ? GlassContainer(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        blur: 15,
                        opacity: 0.2,
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacity(0.3),
                            colorScheme.primary.withOpacity(0.15),
                          ],
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                            ),
                          ),
                        ),
                      )
                    : GlassButton(
                        onPressed: _login,
                        color: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.login_rounded, size: 22, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                const SizedBox(height: 24),
                
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Register Button
                GlassButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_rounded, size: 22, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Create New Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                    ],  // End of Column children
                  ),  // End of Column
                ),  // End of Form
              ),  // End of SingleChildScrollView
            ),  // End of Center
          ),  // End of SafeArea
        ],  // End of Stack children
      ),  // End of Stack body
    );  // End of Scaffold
  }
}