import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewProductsPage extends StatefulWidget {
  const ViewProductsPage({super.key});

  @override
  State<ViewProductsPage> createState() => _ViewProductsPageState();
}

class _ViewProductsPageState extends State<ViewProductsPage> {
  final List<String> _categories = ['Men', 'Women', 'Kids', 'Bags', 'Decor'];

  Future<List<QueryDocumentSnapshot>> _fetchAll() async {
    final result = <QueryDocumentSnapshot>[];
    for (final category in _categories) {
      final snap = await FirebaseFirestore.instance.collection(category).get();
      result.addAll(snap.docs);
    }
    return result;
  }

  void _showEditDialog(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final imC = TextEditingController(text: data['imageUrl']);
    final secondImC = TextEditingController(text: data['secondImageUrl'] ?? '');
    final nameC = TextEditingController(text: data['name']);
    final descC = TextEditingController(text: data['description']);
    final priceC = TextEditingController(text: data['price'].toString());
    final offerC = TextEditingController(text: data['offerPrice'].toString());
    final quantityC = TextEditingController(text: data['quantity'].toString());

    String selectedCategory = data['category'] ?? doc.reference.parent.id;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Edit Product', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: imC, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Image URL', labelStyle: TextStyle(color: Colors.white))),
              TextField(controller: secondImC, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Second Image URL', labelStyle: TextStyle(color: Colors.white))),
              TextField(controller: nameC, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white))),
              TextField(controller: descC, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.white))),
              TextField(controller: priceC, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Price', labelStyle: TextStyle(color: Colors.white))),
              TextField(controller: offerC, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Offer Price', labelStyle: TextStyle(color: Colors.white))),
              TextField(controller: quantityC, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Quantity', labelStyle: TextStyle(color: Colors.white))),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: Colors.grey[850],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: Colors.white)),
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) {
                  if (val != null) selectedCategory = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            onPressed: () async {
              final updatedData = {
                'imageUrl': imC.text.trim(),
                'secondImageUrl': secondImC.text.trim(),
                'name': nameC.text.trim(),
                'description': descC.text.trim(),
                'price': double.tryParse(priceC.text.trim()) ?? 0,
                'offerPrice': double.tryParse(offerC.text.trim()) ?? 0,
                'quantity': int.tryParse(quantityC.text.trim()) ?? 0,
                'category': selectedCategory,
                'timestamp': Timestamp.now(),
              };

              final currentCategory = doc.reference.parent.id;

              if (selectedCategory == currentCategory) {
                await FirebaseFirestore.instance.collection(currentCategory).doc(doc.id).update(updatedData);
              } else {
                await FirebaseFirestore.instance.collection(currentCategory).doc(doc.id).delete();
                await FirebaseFirestore.instance.collection(selectedCategory).add(updatedData);
              }

              if (mounted) setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(QueryDocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this product?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection(doc.reference.parent.id).doc(doc.id).delete();
              if (mounted) setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.16;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _fetchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No products found', style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                color: Colors.grey[850],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: data['imageUrl'] != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(data['imageUrl'], width: imageSize, height: imageSize, fit: BoxFit.cover),
                  )
                      : Icon(Icons.image, color: Colors.white, size: imageSize),
                  title: Text(data['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('₹${data['offerPrice']} | Qty: ${data['quantity']}', style: const TextStyle(color: Colors.white70)),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditDialog(doc)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(doc)),
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
