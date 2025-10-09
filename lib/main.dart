import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const BuildMateApp());
}

class BuildMateApp extends StatelessWidget {
  const BuildMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: "Poppins"),
      home: const SplashScreen(),
    );
  }
}
