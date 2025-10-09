import 'package:flutter/material.dart';

class ProductsScreen extends StatelessWidget {
  final String categoryName;

  const ProductsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final products = [
      {"name": "Hollow Blocks", "price": "12.00", "stock": "In Stock"},
      {"name": "Cement Bag", "price": "250.00", "stock": "In Stock"},
      {"name": "Steel Bar", "price": "120.00", "stock": "Low Stock"},
      {"name": "Paint Bucket", "price": "450.00", "stock": "In Stock"},
      {"name": "Nail", "price": "2.00", "stock": "In Stock"},
      {"name": "Angle bar", "price": "20.00", "stock": "In Stock"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: const Color(0xFF615EFC),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(
            product["name"]!,
            product["price"]!,
            product["stock"]!,
          );
        },
      ),
    );
  }

  Widget _buildProductCard(String name, String price, String stock) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300] ?? Colors.grey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  "assets/images/placeholder.png",
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              stock,
              style: TextStyle(
                fontSize: 12,
                color: stock == "In Stock" ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
