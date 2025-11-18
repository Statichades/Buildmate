import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buildmate/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/order_model.dart';
import 'order_details_screen.dart';

const String baseUrl = 'https://buildmate-db.onrender.com/api';

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
  final Set<int> _selectedOrderIds = {};

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
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await ApiService().get('/orders/user/$userId');

      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final orders = data.map((order) => Order.fromJson(order)).toList();

          for (var order in orders) {
            try {
              final orderResponse = await ApiService().get(
                '/orders/${order.id}',
              );
              if (orderResponse.statusCode == 200) {
                final orderData = json.decode(orderResponse.body);
                final fullOrder = Order.fromJson(orderData);
                order = Order(
                  id: order.id,
                  userId: order.userId,
                  items: fullOrder.items,
                  shippingAddress: order.shippingAddress,
                  subtotal: order.subtotal,
                  shippingFee: order.shippingFee,
                  total: order.total,
                  status: order.status,
                  createdAt: order.createdAt,
                  updatedAt: order.updatedAt,
                );
              }
            } catch (e) {
              debugPrint('Error fetching items for order ${order.id}: $e');
            }
          }

          setState(() {
            _orders = orders;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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

  bool get _hasSelected => _selectedOrderIds.isNotEmpty;

  bool get _allSelected =>
      _filteredOrders.every((order) => _selectedOrderIds.contains(order.id));

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
        actions: [
          if (_filteredOrders.isNotEmpty)
            IconButton(
              onPressed: _toggleSelectAll,
              icon: Icon(
                _allSelected ? Icons.check_box : Icons.check_box_outline_blank,
                color: const Color(0xFF615EFC),
              ),
            ),
        ],
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
          _buildFilterButton('Orders', 'all'),
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
            foregroundColor: isSelected ? Colors.white : Colors.grey,
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
                  Row(
                    children: [
                      if (order != null)
                        Checkbox(
                          value: _selectedOrderIds.contains(order.id),
                          onChanged: (value) => _toggleOrderSelection(order.id),
                          activeColor: const Color(0xFF615EFC),
                        ),
                      Text(
                        order != null ? 'Order #${order.id}' : 'Order #12345',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
              if (order != null &&
                  (order.status == 'pending' || order.status == 'processing'))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _cancelOrder(order),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel Order',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'delivered':
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case 'processing':
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case 'pending':
        backgroundColor = Colors.yellow.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
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

  void _toggleOrderSelection(int orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedOrderIds.removeAll(_filteredOrders.map((order) => order.id));
      } else {
        _selectedOrderIds.addAll(_filteredOrders.map((order) => order.id));
      }
    });
  }

  void _navigateToOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: order)),
    );
  }

  Future<void> _cancelOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/${order.id}/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': 'cancelled'}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled successfully')),
          );
          _fetchOrders();
        }
      } else {
        debugPrint(
          'Cancel order failed: ${response.statusCode} - ${response.body}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel order: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
