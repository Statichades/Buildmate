class Product {
  final int id;
  final String name;
  final String price;
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
    return Product(
      id: int.parse(json['id']),
      name: json['name'],
      price: json['price'],
      stock: int.parse(json['stock']),
      imageUrl: json['image_url'],
    );
  }
}
