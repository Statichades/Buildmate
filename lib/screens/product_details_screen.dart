import 'dart:convert';
import 'package:buildmate/utils/toast_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;

  Future<void> addToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    final url = Uri.parse('https://buildmate-db.onrender.com/api/cart');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'product_id': widget.product.id,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 201) {
        showModernToast(message: 'Item added to cart!');
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        final responseBody = json.decode(response.body);
        showModernToast(
          message: 'Failed to add to cart: ${responseBody['error']}',
        );
      }
    } catch (e) {
      showModernToast(message: 'An error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.product.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF615EFC),
                ),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3), // Transparent black overlay
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(0, 255, 255, 255),
                    Color.fromARGB(100, 255, 255, 255),
                    Color.fromARGB(200, 255, 255, 255),
                    Colors.white,
                  ],
                  stops: [0.4, 0.6, 0.8, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.price.toString(),
                        style: const TextStyle(
                          color: Color(0xFF615EFC),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            "In Stock (${widget.product.stock})",
                            style: TextStyle(
                              color: widget.product.stock > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.info_outline,
                            color: Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "View Details",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Quantity",
                            style: TextStyle(color: Colors.black, fontSize: 18),
                          ),
                          Row(
                            children: [
                              _quantityButton(Icons.remove, () {
                                if (quantity > 1) {
                                  setState(() => quantity--);
                                }
                              }),
                              Container(
                                width: 40,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[100],
                                ),
                                child: Text(
                                  "$quantity",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              _quantityButton(Icons.add, () {
                                if (quantity < widget.product.stock) {
                                  setState(() => quantity++);
                                } else {
                                  showModernToast(
                                    message:
                                        'Cannot add more than available stock',
                                  );
                                }
                              }),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF615EFC),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              onPressed: () {},
                              child: const Text(
                                "Buy Now",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF615EFC),
                                side: const BorderSide(
                                  color: Color(0xFF615EFC),
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: addToCart,
                              child: const Text(
                                "Add to Cart",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF615EFC),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black, size: 20),
        onPressed: onTap,
      ),
    );
  }
}