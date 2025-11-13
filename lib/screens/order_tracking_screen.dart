import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Order order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Track Order',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF615EFC),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Placed on ${_formatDate(order.createdAt)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '₱${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF615EFC),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildTrackingTimeline(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shipping Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    order.shippingAddress.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.shippingAddress.phone,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.shippingAddress.addressLine1}${order.shippingAddress.addressLine2 != null ? '\n${order.shippingAddress.addressLine2}' : ''}\n${order.shippingAddress.city}, ${order.shippingAddress.state} ${order.shippingAddress.postalCode}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    final steps = [
      {
        'title': 'Order Placed',
        'subtitle': 'Your order has been received',
        'date': _formatDate(order.createdAt),
        'isCompleted': true,
        'isCurrent': order.status == 'pending',
      },
      {
        'title': 'Processing',
        'subtitle': 'Your order is being prepared',
        'date': order.status == 'processing' || order.status == 'delivered'
            ? _formatDate(order.createdAt.add(const Duration(days: 1)))
            : null,
        'isCompleted':
            order.status == 'processing' || order.status == 'delivered',
        'isCurrent': order.status == 'processing',
      },
      {
        'title': 'Shipped',
        'subtitle': 'Your order is on the way',
        'date': order.status == 'delivered'
            ? _formatDate(order.createdAt.add(const Duration(days: 2)))
            : null,
        'isCompleted': order.status == 'delivered',
        'isCurrent': false,
      },
      {
        'title': 'Delivered',
        'subtitle': 'Your order has been delivered',
        'date': order.status == 'delivered'
            ? _formatDate(order.createdAt.add(const Duration(days: 3)))
            : 'Estimated: ${_formatDate(order.createdAt.add(const Duration(days: 3)))}',
        'isCompleted': order.status == 'delivered',
        'isCurrent': false,
      },
    ];

    if (order.status == 'cancelled') {
      steps.add({
        'title': 'Cancelled',
        'subtitle': 'Your order has been cancelled',
        'date': _formatDate(order.updatedAt ?? order.createdAt),
        'isCompleted': true,
        'isCurrent': true,
      });
    }

    return Column(
      children: steps
          .map(
            (step) => _buildTrackingStep(
              title: step['title'] as String,
              subtitle: step['subtitle'] as String,
              date: step['date'] as String?,
              isCompleted: step['isCompleted'] as bool,
              isCurrent: step['isCurrent'] as bool,
              isLast: steps.last == step,
            ),
          )
          .toList(),
    );
  }

  Widget _buildTrackingStep({
    required String title,
    required String subtitle,
    required String? date,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? const Color(0xFF615EFC) : Colors.grey[300],
                border: isCurrent
                    ? Border.all(color: const Color(0xFF615EFC), width: 2)
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isCompleted ? const Color(0xFF615EFC) : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isCompleted || isCurrent ? Colors.black : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              if (date != null) ...[
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: isCurrent ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
