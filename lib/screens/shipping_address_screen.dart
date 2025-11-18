import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:buildmate/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/shipping_address_model.dart';

class ShippingAddressScreen extends StatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  List<ShippingAddress> _addresses = [];
  bool _isLoading = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await ApiService().get('/shipping_addresses/$userId');
      if (response.statusCode == 200) {
        final addresses = (json.decode(response.body) as List)
            .map((addr) => ShippingAddress.fromJson(addr))
            .toList();
        if (mounted) {
          setState(() {
            _addresses = addresses;
            _isLoading = false;
          });
        }
      } else {
        debugPrint(
          'Fetch addresses failed: ${response.statusCode} - ${response.body}',
        );
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAddress(ShippingAddress address) async {
    if (address.id == null) return;

    try {
      final response = await ApiService().delete(
        '/shipping_addresses/${address.id}',
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _addresses.remove(address);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address deleted successfully')),
          );
        }
      } else {
        debugPrint(
          'Delete address failed: ${response.statusCode} - ${response.body}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete address: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete address')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Shipping Addresses',
              style: TextStyle(
                color: Color(0xFF615EFC),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (!_isOnline)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: const Text(
                  'Offline',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
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
                    Icon(Icons.local_shipping, size: 80, color: Colors.grey),
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
                  address != null ? address.fullName : 'John Doe',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (address?.isDefault ?? false)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
              address != null ? address.phone : '+63 912 345 6789',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              address != null
                  ? '${address.state}, ${address.city}${address.addressLine2 != null ? ', ${address.addressLine2}' : ''}, ${address.addressLine1}'
                  : 'Bohol, Buenavista, Bato, Purok 2',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: address != null
                      ? () => _editAddress(address)
                      : null,
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: address != null && !address.isDefault
                      ? () => _deleteAddress(address)
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: address != null && !address.isDefault
                        ? Colors.red
                        : Colors.grey,
                  ),
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
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddEditAddressScreen()),
      ).then((_) => _fetchAddresses());
    }
  }

  void _editAddress(ShippingAddress address) {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditAddressScreen(address: address),
        ),
      ).then((_) => _fetchAddresses());
    }
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
  final _addressLine1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  List<dynamic> _provinces = [];
  List<String> _barangays = [];
  String? _selectedProvince;
  String? _selectedMunicipality;
  String? _selectedBarangay;

  @override
  void initState() {
    super.initState();
    _selectedProvince = 'Bohol';
    _selectedMunicipality = 'Buenavista';
    if (widget.address != null) {
      _fullNameController.text = widget.address!.fullName;
      _phoneController.text = widget.address!.phone;
      _addressLine1Controller.text = widget.address!.addressLine1;
      _selectedProvince = widget.address!.state;
      _selectedMunicipality = widget.address!.city;
      _selectedBarangay = widget.address!.addressLine2;
      _isDefault = widget.address!.isDefault;
    }
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/buenavista_bohol.json',
      );
      final data = json.decode(response);
      setState(() {
        _provinces = [
          {
            "name": "Bohol",
            "municipalities": [
              {"name": "Buenavista", "barangays": data['barangays'] ?? []},
            ],
          },
        ];
        _selectedProvince = 'Bohol';
        _selectedMunicipality = 'Buenavista';
        _barangays = List<String>.from(data['barangays'] ?? []);
      });
    } catch (e) {
      debugPrint('Error loading locations: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvince == null ||
        _selectedProvince!.isEmpty ||
        _selectedMunicipality == null ||
        _selectedMunicipality!.isEmpty ||
        _selectedBarangay == null ||
        _selectedBarangay!.isEmpty ||
        _addressLine1Controller.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields.')),
        );
      }
      return;
    }

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
      addressLine1: _addressLine1Controller.text,
      addressLine2: _selectedBarangay,
      city: _selectedMunicipality ?? '',
      state: _selectedProvince ?? '',
      postalCode: '6304',
      country: 'Philippines',
      isDefault: _isDefault,
    );

    try {
      final url = widget.address != null
          ? '/shipping_addresses/${widget.address!.id}'
          : '/shipping_addresses';

      final requestBody = {
        'user_id': userId,
        'full_name': _fullNameController.text,
        'phone': _phoneController.text,
        'province': _selectedProvince ?? '',
        'municipality': _selectedMunicipality ?? '',
        'barangay': _selectedBarangay ?? '',
        'address': _addressLine1Controller.text,
        'is_default': _isDefault,
      };

      final response = widget.address != null
          ? await ApiService().put(url, body: requestBody)
          : await ApiService().post(url, body: requestBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.address != null
                    ? 'Address updated successfully'
                    : 'Address added successfully',
              ),
            ),
          );
        }
      } else {
        debugPrint(
          'Save address failed: ${response.statusCode} - ${response.body}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save address: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving address: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('An error occurred')));
      }
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
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF615EFC), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF615EFC).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                widget.address != null
                    ? 'Edit Shipping Address'
                    : 'Add Shipping Address',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.address != null
                    ? 'Update your shipping information'
                    : 'Add your shipping information',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _buildModernTextField(
                controller: _fullNameController,
                label: "Full Name",
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildModernTextField(
                controller: _phoneController,
                label: "Phone Number",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDisabledTextField(
                'Province',
                _selectedProvince ?? '',
                Icons.location_city,
              ),
              const SizedBox(height: 16),
              _buildDisabledTextField(
                'Municipality/City',
                _selectedMunicipality ?? '',
                Icons.location_on,
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                'Barangay',
                _selectedBarangay,
                _barangays,
                (value) => setState(() => _selectedBarangay = value),
                enabled: _selectedMunicipality != null,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _addressLine1Controller,
                label: "Address",
                icon: Icons.home_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
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
                          widget.address != null
                              ? 'Update Address'
                              : 'Save Address',
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

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
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
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF615EFC)),
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
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF615EFC),
            fontWeight: FontWeight.w600,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDisabledTextField(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
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
        initialValue: value,
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: enabled ? onChanged : null,
        items: items.map((item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.place_outlined,
            color: enabled ? const Color(0xFF615EFC) : Colors.grey.shade400,
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
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF615EFC),
            fontWeight: FontWeight.w600,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }
}
