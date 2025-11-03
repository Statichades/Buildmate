import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:buildmate/models/product_model.dart' as product_model;
import 'package:buildmate/widgets/product_card.dart';
import 'package:buildmate/screens/product_details_screen.dart';
import 'package:buildmate/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  final List<product_model.Product> allProducts;

  const SearchScreen({super.key, required this.allProducts});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<product_model.Product> _filteredProducts = [];

  // Filter state
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;
  RangeValues? _currentRangeValues;
  double _maxPrice = 5000;
  bool _inStockOnly = false;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _searchController.addListener(_filterProducts);
  }

  void _initializeFilters() {
    _filteredProducts = widget.allProducts;
    if (widget.allProducts.isNotEmpty) {
      final max = widget.allProducts.map((p) => p.price).reduce((a, b) => a > b ? a : b);
      _maxPrice = max > 0 ? max : 5000;
      _currentRangeValues = RangeValues(0, _maxPrice);
    }
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('https://buildmate-db.onrender.com/api/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _categories = List<Map<String, dynamic>>.from(data.map((item) => {'id': item['id'], 'name': item['name']}));
          });
        }
      }
    } catch (e) {
      // Handle error silently
      debugPrint("Failed to fetch categories: $e");
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    setState(() {
      List<product_model.Product> products = widget.allProducts;
      final query = _searchController.text.toLowerCase();


      if (query.isNotEmpty) {
        products = products.where((product) => product.name.toLowerCase().contains(query)).toList();
      }

      if (_selectedCategory != null) {
        products = products.where((product) => product.categoryName == _selectedCategory).toList();
      }

      if (_currentRangeValues != null) {
        products = products.where((product) {
          return product.price >= _currentRangeValues!.start && product.price <= _currentRangeValues!.end;
        }).toList();
      }

      if (_inStockOnly) {
        products = products.where((product) => product.stock > 0).toList();
      }

      _filteredProducts = products;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Wrap(
                runSpacing: 20,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Filters", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategory = null;
                            _currentRangeValues = RangeValues(0, _maxPrice);
                            _inStockOnly = false;
                          });
                        },
                        child: const Text("Reset", style: TextStyle(color: Color(0xFF615EFC))), 
                      )
                    ],
                  ),
                  
                  const Text("Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Wrap(
                    spacing: 8.0,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category['name'];
                      return ChoiceChip(
                        label: Text(category['name']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedCategory = selected ? category['name'] : null;
                          });
                        },
                        selectedColor: const Color(0xFF615EFC).withOpacity(0.2),
                        labelStyle: TextStyle(color: isSelected ? const Color(0xFF615EFC) : Colors.black),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? const Color(0xFF615EFC) : Colors.grey[300]!)),
                      );
                    }).toList(),
                  ),

                  const Text("Price Range", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  RangeSlider(
                    values: _currentRangeValues ?? RangeValues(0, _maxPrice),
                    min: 0,
                    max: _maxPrice,
                    divisions: 100,
                    activeColor: const Color(0xFF615EFC),
                    labels: RangeLabels(
                      '₱${_currentRangeValues?.start.round().toString() ?? "0"}',
                      '₱${_currentRangeValues?.end.round().toString() ?? _maxPrice.round().toString()}',
                    ),
                    onChanged: (RangeValues values) {
                      setModalState(() {
                        _currentRangeValues = values;
                      });
                    },
                  ),

                  SwitchListTile(
                    title: const Text("In Stock Only", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    value: _inStockOnly,
                    onChanged: (bool value) {
                      setModalState(() {
                        _inStockOnly = value;
                      });
                    },
                    activeColor: const Color(0xFF615EFC),
                    contentPadding: EdgeInsets.zero,
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF615EFC),
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _filterProducts();
                      Navigator.pop(context);
                    },
                    child: const Text("Apply Filters", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.1),
        iconTheme: const IconThemeData(color: Color(0xFF615EFC)),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: "Search products...",
              hintStyle: TextStyle(color: Colors.grey.shade600),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade600, size: 20),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.filter_list, color: Color(0xFF615EFC)),
          ),
        ],
      ),
      body: _filteredProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    "No Products Found",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    "Try adjusting your search or filters.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return productCard(
                  imageUrl: product.imageUrl,
                  name: product.name,
                  price: product.price.toString(),
                  stock: product.stock,
                  categoryName: product.categoryName,
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

                    if (!isLoggedIn) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Row(
                            children: const [
                              Icon(Icons.lock_outline, color: Color(0xFF615EFC)),
                              SizedBox(width: 8),
                              Text('Login required'),
                            ],
                          ),
                          content: const Text(
                            'You need to login to view product details or buy products.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Login',
                                style: TextStyle(color: Color(0xFF615EFC)),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(product: product),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}