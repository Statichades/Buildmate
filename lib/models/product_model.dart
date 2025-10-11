class Product {
  final int id;
  final String name;
  final double price;
  final int stock;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    String toStringSafe(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    final image =
        json['image_url'] ??
        json['imageUrl'] ??
        json['image'] ??
        json['image_url'];

    return Product(
      id: toInt(json['id'] ?? json['_id']),
      name: toStringSafe(json['name'] ?? json['title']),
      price: toDouble(json['price']),
      stock: toInt(json['stock']),
      imageUrl: toStringSafe(image),
    );
  }
}
