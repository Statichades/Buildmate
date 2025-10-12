import 'package:buildmate/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:buildmate/screens/signup_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buildmate/utils/toast_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoggingIn = false;

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showModernToast(
        message: 'Please enter email and password',
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    setState(() => isLoggingIn = true);
    final client = http.Client();
    try {
      final loginUrl = Uri.parse(
        'https://buildmate-db.onrender.com/users/login',
      );
      final postResp = await client
          .post(
            loginUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (postResp.statusCode == 200) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final payload = jsonDecode(postResp.body);
          final savedName = (payload is Map && payload['username'] != null)
              ? payload['username'].toString()
              : email;
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('username', savedName);
          if (payload is Map && payload['profileImage'] != null) {
            await prefs.setString('profileImage', payload['profileImage']);
          }
        } catch (_) {}
        showModernToast(message: 'Login successful');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
        return;
      }

      final usersUrl = Uri.parse(
        'https://buildmate-db.onrender.com/users/login',
      );
      final usersResp = await client
          .get(usersUrl)
          .timeout(const Duration(seconds: 10));

      if (usersResp.statusCode == 200) {
        final List<dynamic> users = jsonDecode(usersResp.body);
        final match = users.firstWhere(
          (u) =>
              (u['email'] ?? '').toString().toLowerCase() ==
                  email.toLowerCase() &&
              (u['password'] ?? '').toString() == password,
          orElse: () => null,
        );
        if (match != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            final name = (match['username'] ?? match['name'] ?? email)
                .toString();
            await prefs.setString('username', name);
            if (match['profileImage'] != null) {
              await prefs.setString(
                'profileImage',
                match['profileImage'].toString(),
              );
            }
          } catch (_) {}
          showModernToast(message: 'Login successful');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
          return;
        }
      }

      showModernToast(
        message: 'Invalid credentials',
        backgroundColor: Colors.redAccent,
      );
    } catch (e) {
      showModernToast(
        message: 'Login error: $e',
        backgroundColor: Colors.redAccent,
      );
    } finally {
      client.close();
      setState(() => isLoggingIn = false);
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
                    SizedBox(height: size.height * 0.03),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF615EFC),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoggingIn ? null : _login,
                      child: SizedBox(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: isLoggingIn ? 0.0 : 1.0,
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (isLoggingIn)
                              const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don’t have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Sign up",
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
