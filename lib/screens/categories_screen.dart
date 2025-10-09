import 'package:buildmate/widgets/categories/grid_view.dart';
import 'package:buildmate/widgets/categories/list_view.dart';
import 'package:flutter/material.dart';
import 'products_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  CategoriesScreenState createState() => CategoriesScreenState();
}

class CategoriesScreenState extends State<CategoriesScreen> {
  bool isGrid = true;

  @override
  void initState() {
    super.initState();
    _loadGridPreference();
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

  final categories = [
    {"title": "Masonry", "icon": Icons.construction},
    {"title": "Cabinets", "icon": Icons.kitchen},
    {"title": "Door & Jambs", "icon": Icons.door_front_door},
    {"title": "Steel Bars", "icon": Icons.precision_manufacturing},
    {"title": "Cement", "icon": Icons.grain},
    {"title": "Paints", "icon": Icons.format_paint},
    {"title": "Electrical", "icon": Icons.electrical_services},
  ];

  void _onCategoryTap(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductsScreen(categoryName: title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Categories",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
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
          ),
          Expanded(
            child: isGrid
                ? gridView(categories, _onCategoryTap)
                : listView(categories, _onCategoryTap),
          ),
        ],
      ),
    );
  }
}
