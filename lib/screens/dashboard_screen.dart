import 'package:flutter/material.dart';
import 'package:buildmate/widgets/product_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/product_model.dart' as product_model;
import 'categories_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'product_details_screen.dart';
import 'search_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeContent(),
    CategoriesScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF615EFC),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_rounded),
              label: "Categories",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_rounded),
              label: "Cart",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<product_model.Product> products = [];
  bool isLoading = true;
  String error = '';
  int activeIndex = 0;
  final carouselImages = [
    "assets/images/logo.png",
    "assets/images/logo.png",
    "assets/images/logo.png",
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final url = Uri.parse('https://buildmate-db.onrender.com/products');
    final client = http.Client();

    try {
      final response = await client
          .get(url)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        List<dynamic> productJson = json.decode(response.body);
        setState(() {
          products = productJson
              .map((json) => product_model.Product.fromJson(json))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load products: ${response.statusCode}';
          isLoading = false;
        });
      }
    } on TimeoutException {
      setState(() {
        error = 'Request timed out. Please check your internet connection.';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error fetching products: $e';
        isLoading = false;
      });
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    Widget productsSection;
    if (isLoading && products.isEmpty) {
      final fakeProducts = List.generate(
        6,
        (_) => product_model.Product(
          id: 0,
          name: 'Product',
          price: 0.0,
          stock: 0,
          imageUrl: '',
        ),
      );

      productsSection = Skeletonizer(
        enabled: true,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: fakeProducts.length,
          itemBuilder: (context, index) {
            final product = fakeProducts[index];
            return productCard(
              imageUrl: product.imageUrl,
              name: product.name,
              price: product.price.toString(),
              stock: product.stock,
              onPressed: () {},
            );
          },
        ),
      );
    } else if (error.isNotEmpty && products.isEmpty) {
      // error and nothing to show -> show error message
      productsSection = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Text('Error: $error'),
        ),
      );
    } else {
      // either we have products (cached/previous) or loading finished successfully
      productsSection = GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return productCard(
            imageUrl: product.imageUrl,
            name: product.name,
            price: product.price.toString(),
            stock: product.stock,
            onPressed: () async {
              // Check login state
              final prefs = await SharedPreferences.getInstance();
              final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
              if (!isLoggedIn) {
                // show a modern dialog prompting login
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
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(product: product),
                ),
              );
            },
          );
        },
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              readOnly: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchScreen(allProducts: products),
                  ),
                );
              },
              decoration: const InputDecoration(
                hintText: "Search products",
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeletonizer(
                    enabled:
                        (isLoading || error.isNotEmpty) && products.isEmpty,
                    effect: const ShimmerEffect(
                      baseColor: Color(0xFFE0E0E0),
                      highlightColor: Color(0xFFF5F5F5),
                      duration: Duration(milliseconds: 900),
                    ),
                    child: CarouselSlider.builder(
                      options: CarouselOptions(
                        height: size.height * 0.22,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        aspectRatio: 16 / 9,
                        viewportFraction: 1,
                      ),
                      itemCount: carouselImages.length,
                      itemBuilder: (context, index, realIndex) {
                        final image = carouselImages[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Skeleton.replace(
                            width: double.infinity,
                            height: double.infinity,
                            replacement: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                              ),
                            ),
                            child: Image.asset(
                              image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Products",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "See All",
                          style: TextStyle(
                            color: Color(0xFF615EFC),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Skeletonizer(
                    enabled:
                        (isLoading || error.isNotEmpty) && products.isEmpty,
                    effect: const ShimmerEffect(
                      baseColor: Color(0xFFE0E0E0),
                      highlightColor: Color(0xFFF5F5F5),
                      duration: Duration(milliseconds: 900),
                    ),
                    child: productsSection,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
