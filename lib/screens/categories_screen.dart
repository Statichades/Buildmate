import 'package:buildmate/widgets/categories/grid_view.dart';
import 'package:buildmate/widgets/categories/list_view.dart';
import 'package:flutter/material.dart';
import 'products_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  CategoriesScreenState createState() => CategoriesScreenState();
}

class CategoriesScreenState extends State<CategoriesScreen> {
  bool isGrid = true;
  List<Map<String, dynamic>> categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGridPreference();
    _fetchCategories();
  }

  Future<void> _loadGridPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGrid = prefs.getBool('isGridPreference') ?? true;
    });
  }

  Future<void> _saveGridPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGridPreference', value);
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://buildmate-db.onrender.com/api/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          // Map API response into your local format
          categories = data.map((cat) {
            return {
              "id": cat['id'],
              "title": cat['name'],
              "icon": _getIconForCategory(cat['name']),
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        debugPrint('Failed to fetch categories: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      setState(() => _isLoading = false);
    }
  }

  IconData _getIconForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'masonry':
        return Icons.construction;
      case 'cabinets':
        return Icons.kitchen;
      case 'door & jambs':
        return Icons.door_front_door;
      case 'steel bars':
        return Icons.precision_manufacturing;
      case 'cement':
        return Icons.grain;
      case 'paints':
        return Icons.format_paint;
      case 'electrical':
        return Icons.electrical_services;
      default:
        return Icons.category;
    }
  }

  void _onCategoryTap(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductsScreen(categoryName: title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        title: const Text(
          "Categories",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGrid = !isGrid;
              });
              _saveGridPreference(isGrid);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isGrid
          ? gridView(categories, _onCategoryTap)
          : listView(categories, _onCategoryTap),
    );
  }
}
