import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_hop_app/adressconfirmation.dart';
import 'package:shop_hop_app/ordersuccessfulpage.dart';

class BuyNowPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const BuyNowPage({super.key, required this.items});

  @override
  State<BuyNowPage> createState() => _BuyNowPageState();
}

class _BuyNowPageState extends State<BuyNowPage> {
  Map<String, dynamic>? selectedAddress;
  String selectedPayment = 'Google Pay';

  void _selectAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectAddressPage(
          onAddressSelected: (addressMap) {
            setState(() {
              selectedAddress = addressMap;
            });
          },
        ),
      ),
    );
  }

  int _calculateTotal() {
    return widget.items.fold(0, (sum, item) {
      final offerPrice = (item['offerPrice'] ?? 0) as num;
      final quantity = (item['quantity'] ?? 1) as num;
      return sum + (offerPrice * quantity).toInt();
    });
  }

  Future<int> _generateOrderId() async {
    final docRef =
    FirebaseFirestore.instance.collection('ordersIndex').doc('counter');
    final snapshot = await docRef.get();
    int currentId = snapshot.exists ? snapshot['lastOrderId'] ?? 1000 : 1000;
    await docRef.set({'lastOrderId': currentId + 1});
    return currentId;
  }

  Future<void> _confirmOrder() async {
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a delivery address")),
      );
      return;
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "User not logged in";

      final orderId = await _generateOrderId();

      final orderData = {
        'orderId': orderId,
        'items': widget.items,
        'totalAmount': _calculateTotal(),
        'address': selectedAddress,
        'paymentType': selectedPayment,
        'status': 'Pending',
        'timestamp': Timestamp.now(),
        'userId': user.uid,
        'userEmail': user.email ?? '',
      };

      final userRef =
      FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef
          .collection('orders')
          .doc(orderId.toString())
          .set(orderData);
      await FirebaseFirestore.instance
          .collection('admin')
          .doc('orders')
          .collection('orders')
          .doc(orderId.toString())
          .set(orderData);

      final cartItems = await userRef.collection('cart').get();
      for (final doc in cartItems.docs) {
        await doc.reference.delete();
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessPage(orderId: orderId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontScale = size.width / 375;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Buy Now"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(size.width * 0.04),
        children: [
          ...widget.items.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    item['imageUrl'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: TextStyle(
                            fontSize: 16 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Size: ${item['size']}",
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          "Qty: ${item['quantity']}",
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          "₹${item['offerPrice'] * item['quantity']}",
                          style: TextStyle(
                            fontSize: 16 * fontScale,
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Delivery Address",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * fontScale,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: _selectAddress,
                child: const Text(
                  "Select Address",
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              ),
            ],
          ),
          if (selectedAddress != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${selectedAddress!['name']} (${selectedAddress!['phone']})",
                  style: TextStyle(fontSize: 14 * fontScale, color: Colors.white),
                ),
                Text(
                  "${selectedAddress!['house']}, ${selectedAddress!['landmark']}",
                  style: TextStyle(fontSize: 14 * fontScale, color: Colors.white),
                ),
                Text(
                  "${selectedAddress!['district']}, ${selectedAddress!['state']} - ${selectedAddress!['pincode']}",
                  style: TextStyle(fontSize: 14 * fontScale, color: Colors.white70),
                ),
              ],
            )
          else
            Text(
              "No address selected",
              style: TextStyle(fontSize: 14 * fontScale, color: Colors.white54),
            ),
          const SizedBox(height: 20),
          Text(
            "Select Payment Method",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16 * fontScale,
              color: Colors.white,
            ),
          ),
          RadioListTile<String>(
            title: const Text("Google Pay", style: TextStyle(color: Colors.white)),
            value: "Google Pay",
            groupValue: selectedPayment,
            activeColor: Colors.orangeAccent,
            onChanged: (val) => setState(() => selectedPayment = val!),
          ),
          RadioListTile<String>(
            title: const Text("PhonePe", style: TextStyle(color: Colors.white)),
            value: "PhonePe",
            groupValue: selectedPayment,
            activeColor: Colors.orangeAccent,
            onChanged: (val) => setState(() => selectedPayment = val!),
          ),
          RadioListTile<String>(
            title: const Text("Cash on Delivery", style: TextStyle(color: Colors.white)),
            value: "Cash on Delivery",
            groupValue: selectedPayment,
            activeColor: Colors.orangeAccent,
            onChanged: (val) => setState(() => selectedPayment = val!),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: selectedPayment == "Cash on Delivery"
              ? _confirmOrder
              : () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Only Cash on Delivery is supported for now"),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            "Confirm Order - ₹${_calculateTotal()}",
            style: TextStyle(fontSize: 16 * fontScale),
          ),
        ),
      ),
    );
  }
}
