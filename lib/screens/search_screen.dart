import 'package:flutter/material.dart';
import 'package:buildmate/models/product_model.dart' as product_model;
import 'package:buildmate/widgets/product_card.dart';
import 'package:buildmate/screens/product_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final List<product_model.Product> allProducts;

  const SearchScreen({super.key, required this.allProducts});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<product_model.Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.allProducts;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterProducts(_searchController.text);
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = widget.allProducts;
      } else {
        _filteredProducts = widget.allProducts
            .where(
              (product) =>
                  product.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF615EFC)),
        title: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF615EFC).withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF615EFC).withOpacity(0.05),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: "Search products...",
              hintStyle: TextStyle(color: Colors.grey.shade600),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: const Color(0xFF615EFC).withOpacity(0.7),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _filterProducts('');
                      },
                    )
                  : null,
            ),
            onChanged: _filterProducts,
          ),
        ),
      ),
      body: _filteredProducts.isEmpty && _searchController.text.isNotEmpty
          ? const Center(
              child: Text(
                "No products found",
                style: TextStyle(fontSize: 18, color: Colors.grey),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
