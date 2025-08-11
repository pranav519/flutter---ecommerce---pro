import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['docId'] = doc.id;
      return data;
    }).toList();
  }
  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy, hh:mm a');

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final padding = screenWidth * 0.04;
    final imageSize = screenWidth * 0.18;
    final titleFontSize = screenWidth * 0.045;
    final subtitleFontSize = screenWidth * 0.035;
    final smallFontSize = screenWidth * 0.03;

    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No orders found.", style: TextStyle(color: Colors.white)));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(padding),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final address = order['address'] ?? {};
              final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
              final orderTime = (order['timestamp'] as Timestamp).toDate();
              final formattedDate = formatter.format(orderTime);

              return Card(
                color: Colors.grey[900], // Dark card
                margin: EdgeInsets.only(bottom: padding),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order ID: ${order['orderId']}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: titleFontSize,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        "Date: $formattedDate",
                        style: TextStyle(color: Colors.grey[400], fontSize: subtitleFontSize),
                      ),
                      Divider(height: screenHeight * 0.03, thickness: 1, color: Colors.grey[800]),
                      ...items.map((item) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: screenHeight * 0.015),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  item['imageUrl'],
                                  width: imageSize,
                                  height: imageSize,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.04),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: subtitleFontSize,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      "Size: ${item['size']}",
                                      style: TextStyle(fontSize: smallFontSize, color: Colors.white70),
                                    ),
                                    Text(
                                      "Qty: ${item['quantity']}",
                                      style: TextStyle(fontSize: smallFontSize, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      Divider(height: screenHeight * 0.03, thickness: 1, color: Colors.grey[800]),
                      Text(
                        "Total Amount: ₹${order['totalAmount']}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: subtitleFontSize,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        "Payment: ${order['paymentType']}",
                        style: TextStyle(fontSize: smallFontSize, color: Colors.white70),
                      ),
                      Text(
                        "Status: ${order['status'] ?? 'Pending'}",
                        style: TextStyle(color: Colors.greenAccent, fontSize: smallFontSize),
                      ),
                      Divider(height: screenHeight * 0.03, thickness: 1, color: Colors.grey[800]),
                      Text(
                        "Delivery Address:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: subtitleFontSize,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        "${address['name']} - ${address['phone']}",
                        style: TextStyle(fontSize: smallFontSize, color: Colors.white70),
                      ),
                      Text(
                        "${address['house']}, ${address['landmark']}",
                        style: TextStyle(fontSize: smallFontSize, color: Colors.white70),
                      ),
                      Text(
                        "${address['district']}, ${address['state']} - ${address['pincode']}",
                        style: TextStyle(fontSize: smallFontSize, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

}
