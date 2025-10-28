import 'dart:convert';
import 'dart:io';

import 'package:buildmate/screens/auth_screen.dart';
import 'package:buildmate/screens/edit_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoggedIn = false;
  String? username;
  String? profileImagePath;
  String? tempProfileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      username = prefs.getString('name');
      profileImagePath = prefs.getString('profileImage');
      tempProfileImagePath = prefs.getString('tempProfileImagePath');
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('name');
    await prefs.remove('profileImage');
    await prefs.remove('tempProfileImagePath');
    await prefs.remove('user_id');

    setState(() {
      isLoggedIn = false;
      username = null;
      profileImagePath = null;
      tempProfileImagePath = null;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF615EFC),
              ),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF615EFC)),
              title: const Text('Take a Picture'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromCamera();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tempProfileImagePath', pickedFile.path);

      setState(() {
        tempProfileImagePath = pickedFile.path;
      });

      _uploadImage(File(pickedFile.path));
    }
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tempProfileImagePath', pickedFile.path);

      setState(() {
        tempProfileImagePath = pickedFile.path;
      });

      _uploadImage(File(pickedFile.path));
    }
  }

  Future<void> _uploadImage(File image) async {
    const apiKey = '4e101c88314158dc6123292f2271d307';
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    final request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decodedData = json.decode(responseData);
        final imageUrl = decodedData['data']['url'];
        final deleteUrl = decodedData['data']['delete_url'];

        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');
        await prefs.setString('profileImage', imageUrl);
        await prefs.remove('tempProfileImagePath');

        final dbUrl = Uri.parse(
          'https://buildmate-db.onrender.com/api/users/$userId',
        );
        final dbResponse = await http.patch(
          dbUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'profile_url': imageUrl, 'delete_url': deleteUrl}),
        );

        if (dbResponse.statusCode == 200) {
          setState(() {
            profileImagePath = imageUrl;
            tempProfileImagePath = null;
          });
        }
      }
    } catch (e) {
      // Handle upload error (optional)
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
              child: Column(
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF615EFC),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF615EFC).withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundImage: tempProfileImagePath != null
                                ? FileImage(File(tempProfileImagePath!))
                                : profileImagePath != null
                                    ? CachedNetworkImageProvider(
                                        profileImagePath!)
                                    : null,
                            backgroundColor: Colors.white,
                            child: tempProfileImagePath == null &&
                                    profileImagePath == null
                                ? const Icon(
                                    Icons.person_outline,
                                    size: 40,
                                    color: Color(0xFF615EFC),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: -5,
                          child: GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: const Icon(
                              Icons.add_circle,
                              color: Color(0xFF615EFC),
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isLoggedIn)
                    Text(
                      username ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF615EFC),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
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
            ),

            const SizedBox(height: 20),

            _buildOption(
              Icons.edit,
              "Edit Profile",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                ).then((_) => _loadProfile());
              },
            ),
            _buildOption(Icons.location_on, "Shipping Address"),
            _buildOption(
              Icons.logout,
              isLoggedIn ? "Logout" : "Login",
              isLogout: !isLoggedIn,
              onTap: () {
                if (!isLoggedIn) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );
                } else {
                  _logout();
                }
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF615EFC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF615EFC), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isLogout
                          ? const Color(0xFF615EFC)
                          : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.withOpacity(0.7),
                ),
              ],
            ),
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
      height: 120,
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF615EFC), size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}