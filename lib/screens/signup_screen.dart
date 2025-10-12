import 'package:buildmate/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:buildmate/screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isSigningUp = false;

  Future<void> _signUp() async {
    final username =
        "${firstNameController.text.trim()[0].toUpperCase()}${firstNameController.text.trim().substring(1).toLowerCase()} "
        "${lastNameController.text.trim()[0].toUpperCase()}${lastNameController.text.trim().substring(1).toLowerCase()}";
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (password != confirmPasswordController.text.trim()) {
      showModernToast(
        message: "Passwords do not match",
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      showModernToast(
        message: "Please fill in all fields",
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    if (email.length < 5 || !email.contains('@')) {
      showModernToast(
        message: "Please enter a valid email",
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    if (password.length < 6) {
      showModernToast(
        message: "Password must be at least 6 characters",
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    final client = http.Client();
    setState(() => isSigningUp = true);
    try {
      final response = await client
          .post(
            Uri.parse("https://buildmate-db.onrender.com/users"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": username,
              "email": email,
              "password": password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        showModernToast(
          message: data['message'] ?? "Account created successfully",
        );
        // clear inputs
        firstNameController.clear();
        lastNameController.clear();
        emailController.clear();
        passwordController.clear();
        confirmPasswordController.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else if (response.statusCode == 409) {
        showModernToast(
          message: data["error"] ?? "Email already registered",
          backgroundColor: Colors.redAccent,
        );
      } else {
        showModernToast(
          message: data["error"] ?? "Failed to create account",
          backgroundColor: Colors.redAccent,
        );
      }
    } on TimeoutException {
      showModernToast(
        message: 'Request timed out',
        backgroundColor: Colors.redAccent,
      );
    } catch (e) {
      showModernToast(message: "Error: $e", backgroundColor: Colors.redAccent);
    } finally {
      client.close();
      setState(() => isSigningUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.07,
                  vertical: size.height * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: size.height * 0.08),
                    Center(
                      child: Image.asset(
                        "assets/images/logo.png",
                        height: size.height * 0.12,
                      ),
                    ),
                    SizedBox(height: size.height * 0.05),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: firstNameController,
                            decoration: InputDecoration(
                              hintText: "First Name",
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: lastNameController,
                            decoration: InputDecoration(
                              hintText: "Last Name",
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: "Email",
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Confirm Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF615EFC),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSigningUp ? null : _signUp,
                      child: isSigningUp
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF615EFC),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.02),
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
