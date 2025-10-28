import 'dart:convert';
import 'package:buildmate/models/product_model.dart';
import 'package:buildmate/screens/product_details_screen.dart';
import 'package:buildmate/screens/login_screen.dart';
import 'package:buildmate/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProductsScreen extends StatefulWidget {
  final String categoryName;

  const ProductsScreen({super.key, required this.categoryName});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final url = Uri.parse('https://buildmate-db.onrender.com/api/products');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allProducts = data.map((item) => Product.fromJson(item)).toList();

        // Filter products by category on the client-side
        final filteredProducts = allProducts
            .where((product) => product.categoryName == widget.categoryName)
            .toList();

        if (mounted) {
          setState(() {
            _products = filteredProducts;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.categoryName),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProducts,
        child: _isLoading
            ? _buildLoadingSkeleton()
            : _products.isEmpty
                ? _buildEmptyState()
                : _buildProductGrid(),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          return productCard(
            imageUrl: '',
            name: 'Loading Product',
            price: '0.00',
            stock: 0,
            categoryName: '',
            onPressed: () {},
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No Products Found",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          Text(
            "There are no products in this category yet.",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}