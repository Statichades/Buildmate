import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/order_model.dart';
import 'order_details_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String? initialFilter;

  const OrderHistoryScreen({super.key, this.initialFilter});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'all';
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://buildmate-db.onrender.com/api/orders/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _orders = data.map((order) => Order.fromJson(order)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Order> get _filteredOrders {
    if (_selectedFilter == 'all') return _orders;
    return _orders.where((order) {
      switch (_selectedFilter) {
        case 'delivered':
          return order.isDelivered;
        case 'processing':
          return order.isProcessing;
        case 'cancelled':
          return order.isCancelled;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(
            color: Color(0xFF615EFC),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Color(0xFF615EFC)),

      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchOrders,
              child: _filteredOrders.isEmpty && !_isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 20),
                          Text(
                            "No orders found",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _isLoading ? 5 : _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _isLoading
                            ? null
                            : _filteredOrders[index];
                        return _buildOrderCard(order);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFilterButton('All', 'all'),
          _buildFilterButton('Processing', 'processing'),
          _buildFilterButton('Delivered', 'delivered'),
          _buildFilterButton('Cancelled', 'cancelled'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: ElevatedButton(
          onPressed: () => setState(() => _selectedFilter = filter),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? const Color(0xFF615EFC)
                : Colors.white,
            foregroundColor: isSelected
                ? Colors.white
                : Colors.grey,
            elevation: isSelected ? 2 : 0,
            shadowColor: isSelected
                ? Colors.grey.withOpacity(0.2)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order? order) {
    return Skeletonizer(
      enabled: order == null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
        child: InkWell(
          onTap: order != null ? () => _navigateToOrderDetails(order) : null,
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order != null
                        ? 'Order #${order.id}'
                        : 'Order #12345',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusBadge(order?.status ?? 'processing'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order != null
                    ? '${order.items.length} item${order.items.length > 1 ? 's' : ''}'
                    : '2 items',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order != null
                        ? '₱${order.total.toStringAsFixed(2)}'
                        : '₱150.00',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF615EFC),
                    ),
                  ),
                  Text(
                    order != null
                        ? _formatDate(order.createdAt)
                        : 'Dec 15, 2023',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color textColor;
    switch (status.toLowerCase()) {
      case 'delivered':
        textColor = Colors.green;
        break;
      case 'processing':
        textColor = Colors.orange;
        break;
      case 'cancelled':
        textColor = Colors.red;
        break;
      default:
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF615EFC), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _navigateToOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(order: order),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
