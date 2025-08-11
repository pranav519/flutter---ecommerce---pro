import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SelectAddressPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddressSelected;
  const SelectAddressPage({super.key, required this.onAddressSelected});

  @override
  State<SelectAddressPage> createState() => _SelectAddressPageState();
}

class _SelectAddressPageState extends State<SelectAddressPage> {
  List<Map<String, dynamic>> _addresses = [];
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .get();

    setState(() {
      _addresses = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
      if (_addresses.isNotEmpty) {
        _selectedAddressId = _addresses.first['id'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black, // ✅ Background set to black
      appBar: AppBar(
        title: const Text('Select Address'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _addresses.isEmpty
          ? Center(
        child: ElevatedButton.icon(
          onPressed: () {
            // Navigate to Add Address page
          },
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Add New Address'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _addresses.length,
        itemBuilder: (context, index) {
          final address = _addresses[index];
          final id = address['id'] as String;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            color: Colors.grey[900], // ✅ Card dark color
            child: RadioListTile<String>(
              contentPadding: const EdgeInsets.all(16),
              value: id,
              groupValue: _selectedAddressId,
              onChanged: (value) {
                setState(() {
                  _selectedAddressId = value;
                });
              },
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${address['name']} (${address['phone']})",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: size.width * 0.04,
                      color: Colors.white, // ✅ Text white
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${address['house']}, ${address['landmark']}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    "${address['district']}, ${address['state']} - ${address['pincode']}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              activeColor: Colors.tealAccent,
            ),
          );
        },
      ),
      bottomNavigationBar: _addresses.isEmpty
          ? null
          : Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_selectedAddressId != null) {
                final selectedAddress = _addresses.firstWhere(
                      (addr) => addr['id'] == _selectedAddressId,
                );
                widget.onAddressSelected(selectedAddress);
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Use This Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ),
    );
  }
}
