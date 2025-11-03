import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buildmate/utils/toast_util.dart';
import 'package:buildmate/screens/login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController codeController = TextEditingController();
  bool isVerifying = false;
  bool isResending = false;

  @override
  void initState() {
    super.initState();
    _resendCode(); // Automatically send verification code on screen load
  }

  Future<void> _verifyEmail() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      showModernToast(message: 'Please enter verification code');
      return;
    }

    setState(() => isVerifying = true);

    try {
      final response = await http.post(
        Uri.parse('https://buildmate-db.onrender.com/api/users/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.email, 'verification_code': code}),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      debugPrint('Response headers: ${response.headers}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        showModernToast(message: 'Email verified successfully');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        showModernToast(message: responseBody['error'] ?? 'Verification failed');
      }
    } catch (e) {
      debugPrint('Error: $e');
      showModernToast(message: 'An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => isVerifying = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() => isResending = true);

    try {
      final response = await http.post(
        Uri.parse('https://buildmate-db.onrender.com/api/users/send-verification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.email}),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Resend Response status: ${response.statusCode}');
      debugPrint('Resend Response body: ${response.body}');
      debugPrint('Resend Response headers: ${response.headers}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        showModernToast(message: 'Verification code sent');
      } else {
        showModernToast(message: responseBody['error'] ?? 'Failed to send code');
      }
    } catch (e) {
      debugPrint('Resend Error: $e');
      showModernToast(message: 'An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => isResending = false);
      }
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
                    const Text(
                      'Verify Your Email',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        children: [
                          const TextSpan(text: 'We sent a verification code to '),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextFormField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '000000',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 24,
                            letterSpacing: 8,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF615EFC),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isVerifying ? null : _verifyEmail,
                      child: isVerifying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              "Verify Email",
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
                        Text(
                          "Didn't receive code?",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: isResending ? null : _resendCode,
                          child: isResending
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation(
                                      Color(0xFF615EFC),
                                    ),
                                  ),
                                )
                              : const Text(
                                  "Resend",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF615EFC),
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Back to Login",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
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
