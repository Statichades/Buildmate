import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:buildmate/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'checkout_screen.dart';
import '../utils/connectivity_service.dart';

class CartItem {
  final int id;
  final int productId;
  final String name;
  final String price;
  final String? imageUrl;
  int quantity;
  bool isSelected;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.quantity,
    this.isSelected = false,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
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

  static void refreshCart() {
    
    _currentCartState?._fetchCartItems();
  }

  @override
  State<CartScreen> createState() => _CartScreenState();
}


_CartScreenState? _currentCartState;

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  late ConnectivityService _connectivityService;
  
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    
    _currentCartState = this;
    _connectivityService = ConnectivityService();
    _connectivityService.connectionStatus.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
      }
    });
    _fetchCartItems();
  }

  Future<void> _deleteCartItem(CartItem item) async {
    
    final itemIndex = _cartItems.indexOf(item);
    setState(() {
      _cartItems.remove(item);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        
        if (mounted)
          setState(() {
            _cartItems.insert(itemIndex, item);
          });
        return;
      }

      final response = await ApiService().delete(
        '/cart/$userId/${item.productId}',
      );

      if (response.statusCode != 200) {
        
        if (mounted)
          setState(() {
            _cartItems.insert(itemIndex, item);
          });
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to delete item.")),
          );
      }
    } catch (e) {
      
      if (mounted)
        setState(() {
          _cartItems.insert(itemIndex, item);
        });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("An error occurred while deleting item."),
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
      if (mounted)
        setState(() {
          _isLoading = false;
        });
      return;
    }

    try {
      final response = await ApiService().get('/cart/$userId');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final cartItems = data.map((json) => CartItem.fromJson(json)).toList();
        if (mounted) {
          setState(() {
            _cartItems = cartItems;
            _isLoading = false;
          });
        }
      } else {
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      }
    } catch (e) {
      debugPrint('Error fetching cart: $e');
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _refreshCartItems() async {
    await _fetchCartItems();
  }

  Future<void> _updateCartQuantity(CartItem item, int quantity) async {
    
    final oldQuantity = item.quantity;
    setState(() {
      item.quantity = quantity;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId != null) {
        final response = await ApiService().put(
          '/cart/$userId/${item.productId}',
          body: {'quantity': quantity},
        );
        if (response.statusCode != 200) {
          
          if (mounted)
            setState(() {
              item.quantity = oldQuantity;
            });
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("An error occurred while updating quantity."),
              ),
            );
        }
      }
    } catch (e) {
      
      if (mounted)
        setState(() {
          item.quantity = oldQuantity;
        });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("An error occurred while updating quantity."),
          ),
        );
    }
  }

  void toggleSelection(int index) {
    setState(() {
      _cartItems[index].isSelected = !_cartItems[index].isSelected;
    });
  }

  void increment(int index) {
    final newQuantity = _cartItems[index].quantity + 1;
    _updateCartQuantity(_cartItems[index], newQuantity);
  }

  void decrement(int index) {
    if (_cartItems[index].quantity > 1) {
      final newQuantity = _cartItems[index].quantity - 1;
      _updateCartQuantity(_cartItems[index], newQuantity);
    }
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
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: Color(0xFF615EFC),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.1),
        iconTheme: const IconThemeData(color: Color(0xFF615EFC)),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (hasSelected)
            IconButton(
              onPressed: _deleteSelectedCartItems,
              icon: const Icon(Icons.delete_outline, color: Color(0xFF615EFC)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCartItems,
        child: _cartItems.isEmpty && !_isLoading
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
                                id: 0,
                                productId: 0,
                                name: 'Product Name',
                                price: '0.00',
                                quantity: 1,
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
                    final selectedItems = _cartItems
                        .where((item) => item.isSelected)
                        .toList();
                    if (selectedItems.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(
                            cartItems: selectedItems
                                .map(
                                  (item) => CartItem(
                                    id: item.id,
                                    productId: item.productId,
                                    name: item.name,
                                    price: item.price,
                                    imageUrl: item.imageUrl,
                                    quantity: item.quantity,
                                    isSelected: item.isSelected,
                                  ),
                                )
                                .toList(),
                          ),
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

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }
}
