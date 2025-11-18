class ShippingAddress {
  final int? id;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;

  ShippingAddress({
    this.id,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.isDefault = false,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['address'] ?? '',
      addressLine2: json['barangay'],
      city: json['municipality'] ?? '',
      state: json['province'] ?? '',
      postalCode: '6333',
      country: 'Philippines',
      isDefault: (json['is_default'] == 1) || (json['is_default'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'full_name': fullName,
      'phone': phone,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
