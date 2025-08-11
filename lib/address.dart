import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("User not logged in");

        final addressData = {
          "name": _nameController.text.trim(),
          "phone": _phoneController.text.trim(),
          "pincode": _pincodeController.text.trim(),
          "state": _stateController.text.trim(),
          "district": _districtController.text.trim(),
          "house": _houseController.text.trim(),
          "landmark": _landmarkController.text.trim(),
          "timestamp": FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("addresses")
            .add(addressData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Address saved successfully!")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.grey[850],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.orange),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) =>
        (value == null || value.trim().isEmpty) ? 'This field is required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;
    final spacing = size.height * 0.02;
    final buttonHeight = size.height * 0.065;
    final fontSize = size.width * 0.045;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Address',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              _buildTextField(label: "Full Name", controller: _nameController),
              _buildTextField(
                label: "Phone Number",
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                label: "Pin Code",
                controller: _pincodeController,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(label: "State", controller: _stateController),
              _buildTextField(label: "District", controller: _districtController),
              _buildTextField(label: "House No. / Street", controller: _houseController),
              _buildTextField(label: "Landmark (optional)", controller: _landmarkController),
              SizedBox(height: spacing * 1.5),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Save Address",
                    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
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
