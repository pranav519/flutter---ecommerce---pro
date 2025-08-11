import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shop_hop_app/buynowpage.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];

  Future<void> _fetchCartItems() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cart')
          .doc(userId)
          .collection('items')
          .get();

      setState(() {
        _cartItems = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching cart items: $e');
    }
  }

  Future<void> _removeCartItem(String docId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('cart')
        .doc(userId)
        .collection('items')
        .doc(docId)
        .delete();

    await _fetchCartItems();
  }

  int _calculateTotal() {
    return _cartItems.fold(0, (sum, item) {
      final int price = (item['offerPrice'] ?? 0).toInt();
      final int qty = (item['quantity'] ?? 1).toInt();
      return sum + (price * qty);
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontScale = screenWidth / 375;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Your Cart',
          style: TextStyle(
            fontSize: 18 * fontScale,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _cartItems.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 100),
          child: Text(
            'Your cart is empty.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.02,
        ),
        itemCount: _cartItems.length,
        itemBuilder: (context, index) {
          final item = _cartItems[index];
          return Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.02),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['imageUrl'] ?? '',
                    width: screenWidth * 0.25,
                    height: screenHeight * 0.15,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 60),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? '',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16 * fontScale,
                            color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16, color: Colors.white),
                          Text(
                            item['size'] ?? 'M',
                            style: TextStyle(
                                fontSize: 14 * fontScale,
                                color: Colors.white),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          DropdownButton<int>(
                            dropdownColor: Colors.grey[900],
                            value: item['quantity'],
                            items: List.generate(10, (i) {
                              return DropdownMenuItem(
                                value: i + 1,
                                child: Text(
                                  "Qty: ${i + 1}",
                                  style: const TextStyle(
                                      color: Colors.white),
                                ),
                              );
                            }),
                            onChanged: (value) async {
                              if (value != null) {
                                final userId = FirebaseAuth
                                    .instance.currentUser?.uid;
                                if (userId != null) {
                                  await FirebaseFirestore.instance
                                      .collection('cart')
                                      .doc(userId)
                                      .collection('items')
                                      .doc(item['id'])
                                      .update({'quantity': value});
                                  _fetchCartItems();
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "₹${item['offerPrice']}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16 * fontScale,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "₹${item['price']}",
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 14 * fontScale,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.bookmark_border,
                                    size: 18, color: Colors.white),
                                Text(
                                  "Next time buy",
                                  style: TextStyle(
                                      fontSize: 14 * fontScale,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  _removeCartItem(item['id'] ?? ''),
                              child: Row(
                                children: [
                                  const Icon(Icons.delete,
                                      color: Colors.white),
                                  SizedBox(width: screenWidth * 0.01),
                                  Text(
                                    "Remove",
                                    style: TextStyle(
                                        fontSize: 14 * fontScale,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _cartItems.isNotEmpty
          ? SafeArea(
        child: Container(
          color: Colors.black,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.015,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow("Offer", "Offer not available", fontScale),
                    const SizedBox(height: 4),
                    _buildInfoRow("Shipping Charge", "Free", fontScale),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                        "Total", "₹${_calculateTotal()}", fontScale,
                        isBold: true),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, screenHeight * 0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BuyNowPage(items: _cartItems),
                    ),
                  );
                },
                child: Text(
                  "Continue",
                  style: TextStyle(fontSize: 16 * fontScale),
                ),
              ),
            ],
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildInfoRow(String label, String value, double fontScale,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14 * fontScale,
            )),
        Text(value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14 * fontScale,
            )),
      ],
    );
  }
}
