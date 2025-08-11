import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Adminorderconfirmationpage extends StatefulWidget {
  const Adminorderconfirmationpage({super.key});

  @override
  State<Adminorderconfirmationpage> createState() =>
      _AdminorderconfirmationpageState();
}

class _AdminorderconfirmationpageState
    extends State<Adminorderconfirmationpage> {
  final DateFormat formatter = DateFormat('dd MMM yyyy, hh:mm a');

  Future<List<Map<String, dynamic>>> _fetchAllOrders() async {
    List<Map<String, dynamic>> allOrders = [];

    final adminOrdersSnapshot = await FirebaseFirestore.instance
        .collection('admin')
        .doc('orders')
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .get();

    for (var doc in adminOrdersSnapshot.docs) {
      final order = doc.data();
      order['docId'] = doc.id;
      allOrders.add(order);
    }

    return allOrders;
  }

  Future<void> _updateOrderStatus(
      String userId, String docId, String status) async {
    try {
      final userOrderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(docId);

      final adminOrderRef = FirebaseFirestore.instance
          .collection('admin')
          .doc('orders')
          .collection('orders')
          .doc(docId);

      await Future.wait([
        userOrderRef.update({'status': status}),
        adminOrderRef.update({'status': status}),
      ]);

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _confirmAndDeleteOrder(String userId, String docId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Order"),
        content: const Text(
            "Are you sure you want to permanently delete this order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      _deleteOrder(userId, docId);
    }
  }

  Future<void> _deleteOrder(String userId, String docId) async {
    try {
      await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(docId)
            .delete(),
        FirebaseFirestore.instance
            .collection('admin')
            .doc('orders')
            .collection('orders')
            .doc(docId)
            .delete(),
      ]);

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No orders found.",
                  style: TextStyle(color: Colors.white)),
            );
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final address = order['address'] ?? {};
              final items =
              List<Map<String, dynamic>>.from(order['items'] ?? []);
              final orderTime = (order['timestamp'] as Timestamp).toDate();
              final formattedDate = formatter.format(orderTime);
              final status = order['status'] ?? 'Pending';

              return Card(
                margin: const EdgeInsets.all(12),
                elevation: 4,
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Order ID: ${order['orderId']}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16)),
                      Text("Date: $formattedDate",
                          style: const TextStyle(color: Colors.white70)),
                      const Divider(color: Colors.white24),
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['imageUrl'],
                                width: screenWidth * 0.18,
                                height: screenWidth * 0.18,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  Text("Size: ${item['size']}",
                                      style: const TextStyle(
                                          color: Colors.white)),
                                  Text("Qty: ${item['quantity']}",
                                      style: const TextStyle(
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                      const Divider(color: Colors.white24),
                      Text("Total Amount: ₹${order['totalAmount']}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text("Payment: ${order['paymentType']}",
                          style: const TextStyle(color: Colors.white)),
                      Text("Status: $status",
                          style: const TextStyle(color: Colors.greenAccent)),
                      const Divider(color: Colors.white24),
                      const Text("Delivery Address:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text("${address['name']} - ${address['phone']}",
                          style: const TextStyle(color: Colors.white)),
                      Text("${address['house']}, ${address['landmark']}",
                          style: const TextStyle(color: Colors.white)),
                      Text(
                          "${address['district']}, ${address['state']} - ${address['pincode']}",
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _updateOrderStatus(
                                order['userId'], order['docId'], "Confirmed"),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text("Confirm"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _updateOrderStatus(
                                order['userId'], order['docId'], "Shipped"),
                            icon: const Icon(Icons.local_shipping_outlined),
                            label: const Text("Shipped"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _updateOrderStatus(
                                order['userId'],
                                order['docId'],
                                "Out for Delivery"),
                            icon: const Icon(Icons.delivery_dining_outlined),
                            label: const Text("Out for Delivery"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _updateOrderStatus(
                                order['userId'], order['docId'], "Delivered"),
                            icon: const Icon(Icons.check_circle),
                            label: const Text("Delivered"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _updateOrderStatus(
                                order['userId'], order['docId'], "Rejected"),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text("Reject"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                          ),
                          if (status == 'Delivered')
                            ElevatedButton.icon(
                              onPressed: () => _confirmAndDeleteOrder(
                                  order['userId'], order['docId']),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text("Delete"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                        ],
                      )
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
