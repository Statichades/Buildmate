import 'shipping_address_model.dart';

class OrderItem {
  final int productId;
  final String name;
  final double price;
  final String? imageUrl;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      imageUrl: json['image_url'],
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'quantity': quantity,
    };
  }
}

class Order {
  final int id;
  final int userId;
  final List<OrderItem> items;
  final ShippingAddress shippingAddress;
  final double subtotal;
  final double shippingFee;
  final double total;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Handle nested response structure
    final orderData = json['order'] ?? json;

    return Order(
      id: orderData['id'] ?? 0,
      userId: orderData['user_id'] ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      shippingAddress: ShippingAddress(
        id: orderData['shipping_address_id'],
        fullName: orderData['shipping_name'] ?? '',
        phone: orderData['phone'] ?? '',
        addressLine1: orderData['address'] ?? '',
        addressLine2: orderData['barangay'],
        city: orderData['municipality'] ?? '',
        state: orderData['province'] ?? '',
        postalCode: '6333',
        country: 'Philippines',
        isDefault: false,
      ),
      subtotal:
          double.tryParse(orderData['subtotal']?.toString() ?? '0.0') ?? 0.0,
      shippingFee:
          double.tryParse(orderData['shipping_fee']?.toString() ?? '0.0') ??
          0.0,
      total: double.tryParse(orderData['total']?.toString() ?? '0.0') ?? 0.0,
      status: orderData['status'] ?? 'pending',
      createdAt: DateTime.parse(
        orderData['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: orderData['updated_at'] != null
          ? DateTime.parse(orderData['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'shipping_address': shippingAddress.toJson(),
      'subtotal': subtotal,
      'shipping_fee': shippingFee,
      'total': total,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isDelivered => status.toLowerCase() == 'delivered';
  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
}
