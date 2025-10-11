import 'package:buildmate/screens/auth_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final bool isLoggedIn = false; // ← Simulate logged-in state
  final String? profileImagePath = null; // ← Simulate missing profile picture

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: profileImagePath != null
                      ? AssetImage(profileImagePath!)
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: profileImagePath == null
                      ? const Icon(Icons.add, size: 30, color: Colors.grey)
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (isLoggedIn)
              const Text(
                "Ringheart Tagalog",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Expanded(
                  child: _StatusCard(
                    icon: Icons.check_circle,
                    label: "Delivered",
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatusCard(icon: Icons.sync, label: "Processing"),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatusCard(icon: Icons.cancel, label: "Cancelled"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildOption(Icons.edit, "Edit Profile"),
            _buildOption(Icons.location_on, "Shipping Address"),
            _buildOption(
              Icons.logout,
              isLoggedIn == false ? "Login" : "Logout",
              isLogout: isLoggedIn == false ? true : false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildOption(
    IconData icon,
    String text, {
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300] ?? Colors.grey),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isLogout
                    ? const Color(0xFF615EFC)
                    : const Color(0xFF615EFC),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isLogout ? Colors.green : Colors.black,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300] ?? Colors.grey),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: const Color(0xFF615EFC)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
