import 'dart:convert';
import 'package:buildmate/utils/toast_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import 'checkout_screen.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
  int quantity = 1;
  bool isFavorite = false;
  bool isDescriptionExpanded = false;
  bool isSpecificationsExpanded = false;
  bool isAddingToCart = false;
  late AnimationController _quantityAnimationController;
  late Animation<double> _quantityAnimation;

  @override
  void initState() {
    super.initState();
    _quantityAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _quantityAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _quantityAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _quantityAnimationController.dispose();
    super.dispose();
  }

  Future<bool> _isItemInCart(int userId, int productId) async {
    try {
      final response = await http.get(
        Uri.parse('https://buildmate-db.onrender.com/api/cart/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.any((item) => item['product_id'] == productId);
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> addToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      showModernToast(message: 'Please log in to add items to cart');
      return;
    }

    // Check if item is already in cart
    bool alreadyInCart = await _isItemInCart(userId, widget.product.id);
    if (alreadyInCart) {
      showModernToast(message: 'This item is already in your cart');
      return;
    }

    setState(() => isAddingToCart = true);

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
        String errorMessage = 'Failed to add to cart';

        if (responseBody['error'] != null) {
          final error = responseBody['error'].toString().toLowerCase();
          if (error.contains('already') || error.contains('exists')) {
            errorMessage = 'This item is already in your cart';
          } else {
            errorMessage = 'Failed to add to cart: ${responseBody['error']}';
          }
        }

        showModernToast(message: errorMessage);
      }
    } catch (e) {
      showModernToast(message: 'An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => isAddingToCart = false);
      }
    }
  }

  void _toggleFavorite() {
    setState(() => isFavorite = !isFavorite);
    showModernToast(message: isFavorite ? 'Added to favorites!' : 'Removed from favorites!');
  }

  void _animateQuantityChange() {
    _quantityAnimationController.forward().then((_) {
      _quantityAnimationController.reverse();
    });
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
                // Top bar with close and favorite buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFF615EFC),
                          size: 30,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : const Color(0xFF615EFC),
                          size: 28,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name and rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.product.name,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (widget.product.rating != null) ...[
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.product.rating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₱${widget.product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF615EFC),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.product.stock > 0
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.product.stock > 0
                                  ? "In Stock"
                                  : "Out of Stock",
                              style: TextStyle(
                                color: widget.product.stock > 0 ? Colors.green : Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: const Text(
                                    'Stock Details',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    widget.product.stock > 0
                                        ? 'Available stock: ${widget.product.stock} units'
                                        : 'This product is currently out of stock.',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text(
                                        'Close',
                                        style: TextStyle(color: Color(0xFF615EFC)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "View Details",
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Description section
                      if (widget.product.description != null) ...[
                        _buildExpandableSection(
                          title: "Description",
                          content: widget.product.description!,
                          isExpanded: isDescriptionExpanded,
                          onToggle: () => setState(() => isDescriptionExpanded = !isDescriptionExpanded),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Specifications section
                      if (widget.product.specifications != null && widget.product.specifications!.isNotEmpty) ...[
                        _buildExpandableSection(
                          title: "Specifications",
                          content: widget.product.specifications!.map((spec) => "• $spec").join('\n'),
                          isExpanded: isSpecificationsExpanded,
                          onToggle: () => setState(() => isSpecificationsExpanded = !isSpecificationsExpanded),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Quantity selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Quantity",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              _quantityButton(Icons.remove, () {
                                if (quantity > 1) {
                                  setState(() => quantity--);
                                  _animateQuantityChange();
                                }
                              }),
                              AnimatedBuilder(
                                animation: _quantityAnimation,
                                builder: (context, child) => Transform.scale(
                                  scale: _quantityAnimation.value,
                                  child: Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey[50],
                                    ),
                                    child: Text(
                                      "$quantity",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              _quantityButton(Icons.add, () {
                                if (quantity < widget.product.stock) {
                                  setState(() => quantity++);
                                  _animateQuantityChange();
                                } else {
                                  showModernToast(
                                    message: 'Cannot add more than available stock',
                                  );
                                }
                              }),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF615EFC),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                shadowColor: const Color(0xFF615EFC).withOpacity(0.3),
                              ),
                              onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                final userId = prefs.getInt('user_id');

                                if (userId == null) {
                                  showModernToast(message: 'Please log in to buy products');
                                  return;
                                }

                                // Create a cart item from the current product
                                final cartItem = CartItem(
                                  productId: widget.product.id,
                                  name: widget.product.name,
                                  price: widget.product.price.toString(),
                                  imageUrl: widget.product.imageUrl,
                                  quantity: quantity,
                                  isSelected: true,
                                );

                                // Navigate to checkout with this single item
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CheckoutScreen(cartItems: [cartItem]),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                "Buy Now",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: isAddingToCart ? null : addToCart,
                              child: isAddingToCart
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF615EFC)),
                                      ),
                                    )
                                  : const Text(
                                      "Add to Cart",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF615EFC),
                                        fontWeight: FontWeight.w600,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87, size: 20),
        onPressed: onTap,
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required String content,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF615EFC),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                content,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
