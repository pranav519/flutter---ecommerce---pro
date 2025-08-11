import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_hop_app/adminorderconfirmationpage.dart';
import 'package:shop_hop_app/saleaddedpage.dart';
import 'package:shop_hop_app/viewproduct.dart' show ViewProductsPage;

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    AddProductPage(),
    ViewProductsPage(),
    SalePage(),
    SaleAddedPage(),
    Adminorderconfirmationpage(),
  ];

  void _onTabTapped(int index) => setState(() => _selectedIndex = index);

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final iconSize = width * 0.07;
    final textSize = width * 0.035;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box, size: iconSize),
            label: 'Add Prod',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt, size: iconSize),
            label: 'View Prods',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera, size: iconSize),
            label: 'New Sale',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image, size: iconSize),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle, size: iconSize),
            label: 'Orders',
          ),
        ],
        selectedLabelStyle: TextStyle(fontSize: textSize),
        unselectedLabelStyle: TextStyle(fontSize: textSize),
      ),
    );
  }
}

// =================== ADD PRODUCT PAGE ===================

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _img1 = TextEditingController();
  final _img2 = TextEditingController();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _offer = TextEditingController();
  final _qty = TextEditingController();

  bool _submitting = false;
  String? _selectedCategory;

  final List<String> _categories = const [
    'Men',
    'Women',
    'Kids',
    'Bags',
    'Decor',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all fields & category')),
      );
      return;
    }

    setState(() => _submitting = true);

    final col = FirebaseFirestore.instance.collection(_selectedCategory!).doc();

    final data = {
      'id': col.id,
      'imageUrl': _img1.text,
      'secondImageUrl': _img2.text,
      'name': _name.text,
      'description': _desc.text,
      'price': double.tryParse(_price.text) ?? 0,
      'offerPrice': double.tryParse(_offer.text) ?? 0,
      'quantity': int.tryParse(_qty.text) ?? 0,
      'category': _selectedCategory,
      'timestamp': Timestamp.now(),
    };

    try {
      await col.set(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
      _formKey.currentState!.reset();
      setState(() => _selectedCategory = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  Widget _buildField(
      TextEditingController ctrl,
      String label, {
        bool isNumeric = false,
      }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.orangeAccent),
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final vspace = w * 0.04;
    final font = w * 0.045;
    final btnHeight = w * 0.12;

    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(vspace),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Add Product',
                style: TextStyle(
                  fontSize: w * 0.07,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: vspace),
              _buildField(_img1, 'Primary Image URL'),
              SizedBox(height: vspace),
              _buildField(_img2, 'Secondary Image URL'),
              SizedBox(height: vspace),
              _buildField(_name, 'Product Name'),
              SizedBox(height: vspace),
              _buildField(_desc, 'Description'),
              SizedBox(height: vspace),
              _buildField(_price, 'Price', isNumeric: true),
              SizedBox(height: vspace),
              _buildField(_offer, 'Offer Price', isNumeric: true),
              SizedBox(height: vspace),
              _buildField(_qty, 'Stock Quantity', isNumeric: true),
              SizedBox(height: vspace),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orangeAccent),
                  ),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: TextStyle(fontSize: font)),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Select category' : null,
              ),
              SizedBox(height: vspace + 8),
              SizedBox(
                width: double.infinity,
                height: btnHeight,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    'Save Product',
                    style: TextStyle(fontSize: font),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== SALE PAGE ===================

class SalePage extends StatefulWidget {
  const SalePage({super.key});

  @override
  State<SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  final TextEditingController _saleUrl = TextEditingController();

  Future<void> _addSale() async {
    final url = _saleUrl.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter image URL')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('Sale').add({
        'imageUrl': url,
        'timestamp': Timestamp.now(),
      });
      _saleUrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale image added')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final padding = w * 0.05;
    final font = w * 0.045;
    final btnSize = w * 0.12;

    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Sale',
            style: TextStyle(
              color: Colors.white,
              fontSize: w * 0.065,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: padding),
          TextFormField(
            controller: _saleUrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Image URL',
              labelStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orangeAccent),
              ),
            ),
          ),
          SizedBox(height: padding),
          SizedBox(
            width: double.infinity,
            height: btnSize,
            child: ElevatedButton(
              onPressed: _addSale,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
              ),
              child: Text(
                'Upload Sale',
                style: TextStyle(fontSize: font),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
