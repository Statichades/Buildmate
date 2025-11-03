import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/order_model.dart';

class ShippingAddressScreen extends StatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  List<ShippingAddress> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://buildmate-db.onrender.com/api/shipping-addresses/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _addresses = data.map((addr) => ShippingAddress.fromJson(addr)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAddress(ShippingAddress address) async {
    if (address.id == null) return;

    try {
      final response = await http.delete(
        Uri.parse('https://buildmate-db.onrender.com/api/shipping-addresses/${address.id}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _addresses.remove(address);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete address')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Shipping Addresses',
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
        actions: [
          IconButton(
            onPressed: _addNewAddress,
            icon: const Icon(Icons.add, color: Color(0xFF615EFC)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAddresses,
        child: _addresses.isEmpty && !_isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "No addresses found",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Add your first shipping address",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _isLoading ? 3 : _addresses.length,
                itemBuilder: (context, index) {
                  final address = _isLoading ? null : _addresses[index];
                  return _buildAddressCard(address, index);
                },
              ),
      ),
    );
  }

  Widget _buildAddressCard(ShippingAddress? address, int index) {
    return Skeletonizer(
      enabled: address == null,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  address != null
                      ? address.fullName
                      : 'John Doe',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (address?.isDefault ?? false)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF615EFC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        color: Color(0xFF615EFC),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address != null
                  ? address.phone
                  : '+63 912 345 6789',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              address != null
                  ? '${address.address}\n${address.city}, ${address.province} ${address.zipCode}'
                  : '123 Main St\nManila, Metro Manila 1000',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: address != null ? () => _editAddress(address) : null,
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: address != null ? () => _deleteAddress(address) : null,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addNewAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditAddressScreen(),
      ),
    ).then((_) => _fetchAddresses());
  }

  void _editAddress(ShippingAddress address) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAddressScreen(address: address),
      ),
    ).then((_) => _fetchAddresses());
  }
}

class AddEditAddressScreen extends StatefulWidget {
  final ShippingAddress? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _zipCodeController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _fullNameController.text = widget.address!.fullName;
      _phoneController.text = widget.address!.phone;
      _addressController.text = widget.address!.address;
      _cityController.text = widget.address!.city;
      _provinceController.text = widget.address!.province;
      _zipCodeController.text = widget.address!.zipCode;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final address = ShippingAddress(
      id: widget.address?.id,
      fullName: _fullNameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      city: _cityController.text,
      province: _provinceController.text,
      zipCode: _zipCodeController.text,
      isDefault: _isDefault,
    );

    try {
      final url = widget.address != null
          ? 'https://buildmate-db.onrender.com/api/shipping-addresses/${widget.address!.id}'
          : 'https://buildmate-db.onrender.com/api/shipping-addresses';

      final response = widget.address != null
          ? await http.put(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({...address.toJson(), 'user_id': userId}),
            )
          : await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({...address.toJson(), 'user_id': userId}),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.address != null
                ? 'Address updated successfully'
                : 'Address added successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save address')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.address != null ? 'Edit Address' : 'Add Address',
          style: const TextStyle(
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildModernTextField('Full Name', _fullNameController),
              const SizedBox(height: 16),
              _buildModernTextField('Phone Number', _phoneController,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildModernTextField('Address', _addressController, maxLines: 3),
              const SizedBox(height: 16),
              _buildModernTextField('City', _cityController),
              const SizedBox(height: 16),
              _buildModernTextField('Province', _provinceController),
              const SizedBox(height: 16),
              _buildModernTextField('ZIP Code', _zipCodeController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CheckboxListTile(
                  title: const Text('Set as default address'),
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() => _isDefault = value ?? false);
                  },
                  activeColor: const Color(0xFF615EFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF615EFC),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveAddress,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.address != null ? 'Update Address' : 'Save Address',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  Widget _buildModernTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF615EFC), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
