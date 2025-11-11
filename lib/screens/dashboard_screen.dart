import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:buildmate/widgets/product_card.dart';
import 'package:buildmate/services/api_service.dart';
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

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeContent(),
      const CategoriesScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
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
  List<product_model.Product> displayedProducts = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String error = '';
  int activeIndex = 0;
  int currentBatch = 0;
  final int batchSize = 10;
  final ScrollController _scrollController = ScrollController();
  bool _isOnline = true;
  final carouselImages = [
    "assets/images/logo.png",
    "assets/images/logo.png",
    "assets/images/logo.png",
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _scrollController.addListener(_onScroll);

    // Force refresh products when navigating back to dashboard (e.g., after login)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProductsIfNeeded();
      // Additional check after a longer delay to handle slow login processing
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _refreshProductsIfNeeded();
        }
      });
      // Additional check after login completion
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _refreshProductsIfNeeded();
        }
      });
    });
  }

  Future<void> _refreshProductsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // If user just logged in and products are empty, force refresh
    if (isLoggedIn && products.isEmpty && !isLoading) {
      // Small delay to ensure login is fully processed
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && products.isEmpty) {
        debugPrint('Dashboard: Refreshing products after login');
        await _fetchProducts();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreProducts();
    }
  }

  Future<void> _fetchProducts() async {
    debugPrint('Dashboard: Fetching products...');
    try {
      final response = await ApiService().get('/products');
      if (response.statusCode == 200) {
        final productList = (json.decode(response.body) as List)
            .map((p) => product_model.Product.fromJson(p))
            .toList();
        debugPrint('Dashboard: Fetched ${productList.length} products');
        if (mounted) {
          setState(() {
            products = productList;
            _loadInitialBatch();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Dashboard: Initial fetch failed: $e');
      // Retry multiple times with increasing delays
      for (int attempt = 1; attempt <= 3; attempt++) {
        await Future.delayed(Duration(seconds: attempt));
        if (mounted) {
          try {
            final response = await ApiService().get('/products');
            if (response.statusCode == 200) {
              final productList = (json.decode(response.body) as List)
                  .map((p) => product_model.Product.fromJson(p))
                  .toList();
              debugPrint(
                'Dashboard: Retry $attempt successful, fetched ${productList.length} products',
              );
              setState(() {
                products = productList;
                _loadInitialBatch();
                isLoading = false;
              });
              return; // Success, exit retry loop
            }
          } catch (e2) {
            debugPrint('Dashboard: Retry $attempt failed: $e2');
            if (attempt == 3) {
              // Final attempt failed
              setState(() {
                error = 'Error fetching products: $e2';
                isLoading = false;
              });
            }
          }
        } else {
          return; // Widget disposed
        }
      }
    }
  }

  void _loadInitialBatch() {
    final endIndex = (currentBatch + 1) * batchSize;
    displayedProducts = products.take(endIndex).toList();
  }

  void _loadMoreProducts() {
    if (isLoadingMore || displayedProducts.length >= products.length) return;

    setState(() => isLoadingMore = true);

    // Simulate loading delay for better UX
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          currentBatch++;
          final startIndex = currentBatch * batchSize;
          final endIndex = (currentBatch + 1) * batchSize;
          displayedProducts.addAll(products.skip(startIndex).take(batchSize));
          isLoadingMore = false;
        });
      }
    });
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
          categoryName: '',
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
              categoryName: product.categoryName,
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
        itemCount: displayedProducts.length,
        itemBuilder: (context, index) {
          final product = displayedProducts[index];

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
                if (mounted) {
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
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(color: Color(0xFF615EFC)),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              } else {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(product: product),
                    ),
                  );
                }
              }
            },
          );
        },
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchProducts,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  readOnly: true,
                  onTap: () {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SearchScreen(allProducts: products),
                        ),
                      );
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: "Search products",
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Color(0xFF615EFC)),
                  ),
                ),
              ),
              Skeletonizer(
                enabled: (isLoading || error.isNotEmpty) && products.isEmpty,
                effect: const ShimmerEffect(
                  baseColor: Color(0xFFE0E0E0),
                  highlightColor: Color(0xFFF5F5F5),
                  duration: Duration(milliseconds: 900),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF615EFC).withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                        child: Stack(
                          children: [
                            Skeleton.replace(
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
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Products",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                enabled: (isLoading || error.isNotEmpty) && products.isEmpty,
                effect: const ShimmerEffect(
                  baseColor: Color(0xFFE0E0E0),
                  highlightColor: Color(0xFFF5F5F5),
                  duration: Duration(milliseconds: 900),
                ),
                child: productsSection,
              ),
              if (isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF615EFC)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
