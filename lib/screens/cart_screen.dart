import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CartItem {
  final int productId;
  final String name;
  final String price;
  final String? imageUrl;
  int quantity;
  bool isSelected;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.quantity,
    this.isSelected = false,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id'],
      name: json['name'],
      price: json['price'],
      imageUrl: json['image_url'],
      quantity: json['quantity'],
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _deleteCartItem(CartItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        print("Delete failed: User ID is null.");
        return;
      }

      final url = Uri.parse(
        'https://buildmate-db.onrender.com/cart/$userId/${item.productId}',
      );
      print("Attempting to delete from URL: $url");

      final response = await http.delete(url);

      print("Delete response status code: ${response.statusCode}");
      print("Delete response body: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          _cartItems.remove(item);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to delete item. Check console for details."),
          ),
        );
      }
    } catch (e) {
      print("An error occurred during deletion: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An error occurred. Check console for details."),
        ),
      );
    }
  }

  Future<void> _deleteSelectedCartItems() async {
    final selectedItems = _cartItems.where((item) => item.isSelected).toList();
    for (var item in selectedItems) {
      await _deleteCartItem(item);
    }
  }

  Future<void> _fetchCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://buildmate-db.onrender.com/cart/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _cartItems = data.map((item) => CartItem.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void toggleSelection(int index) {
    setState(() {
      _cartItems[index].isSelected = !_cartItems[index].isSelected;
    });
  }

  void increment(int index) {
    setState(() {
      _cartItems[index].quantity++;
    });
  }

  void decrement(int index) {
    setState(() {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      }
    });
  }

  bool get hasSelected => _cartItems.any((item) => item.isSelected);

  double get totalPrice => _cartItems
      .where((item) => item.isSelected)
      .fold(0, (sum, item) => sum + (double.parse(item.price) * item.quantity));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        title: const Text(
          "My Cart",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (hasSelected)
            IconButton(
              onPressed: _deleteSelectedCartItems,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _cartItems.isEmpty && !_isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Your cart is empty",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    itemCount: _isLoading ? 6 : _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _isLoading
                          ? CartItem(
                              productId: 0,
                              name: 'Product Name',
                              price: '0.00',
                              quantity: 1,
                              isSelected: false,
                            )
                          : _cartItems[index];
                      return _buildCartItemCard(item, index);
                    },
                  ),
                ),
                if (!_isLoading && _cartItems.isNotEmpty)
                  _buildCheckoutSection(),
              ],
            ),
    );
  }

  Widget _buildCartItemCard(CartItem item, int index) {
    return Skeletonizer(
      enabled: _isLoading,
      child: InkWell(
        onTap: _isLoading ? null : () => toggleSelection(index),
        borderRadius: BorderRadius.circular(15),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF615EFC).withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Checkbox(
                value: item.isSelected,
                onChanged: _isLoading
                    ? null
                    : (bool? value) {
                        toggleSelection(index);
                      },
                activeColor: const Color(0xFF615EFC),
              ),
              SizedBox(
                width: 70,
                height: 70,
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        ),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${item.price}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF615EFC),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildQuantityControl(item, index),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControl(CartItem item, int index) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _isLoading ? null : () => decrement(index),
          icon: const Icon(Icons.remove_circle_outline),
          color: Colors.grey[700],
          iconSize: 24,
        ),
        Text(
          '${item.quantity}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        IconButton(
          onPressed: _isLoading ? null : () => increment(index),
          icon: const Icon(Icons.add_circle_outline),
          color: Colors.grey[700],
          iconSize: 24,
        ),
      ],
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF615EFC).withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₱${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF615EFC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _cartItems.isNotEmpty
                  ? const Color(0xFF615EFC)
                  : Colors.grey,
              minimumSize: const Size.fromHeight(55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _cartItems.isNotEmpty
                ? () {
                    if (totalPrice > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Proceeding to checkout..."),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please select at least one item to checkout.",
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                : null,
            child: const Text(
              "Checkout",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
    );
  }
}
