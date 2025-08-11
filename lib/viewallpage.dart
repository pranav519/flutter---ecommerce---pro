import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_hop_app/productdetailspage.dart';

class ViewAllPage extends StatefulWidget {
  final String? categoryName;
  final String? title;
  final List<Map<String, dynamic>>? products;

  const ViewAllPage({
    super.key,
    this.categoryName,
    this.title,
    this.products,
  });

  @override
  State<ViewAllPage> createState() => _ViewAllPageState();
}

class _ViewAllPageState extends State<ViewAllPage> {
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    if (widget.products != null) {
      _products = widget.products!;
    } else if (widget.categoryName != null) {
      _fetchCategoryProducts(widget.categoryName!);
    }
  }

  Future<void> _fetchCategoryProducts(String categoryName) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection(categoryName).get();
      setState(() {
        _products = snapshot.docs
            .map((doc) => {
          ...doc.data(),
          'id': doc.id,
          'category': categoryName,
        })
            .toList()
            .cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Error fetching category products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final title = widget.title ?? widget.categoryName ?? 'Products';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title, style: TextStyle(color: Colors.white)),
      ),
      body: _products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 600 ? 4 : 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final product = _products[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(
                    productId: product['id'],
                    category: product['category'],
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product['imageUrl'] ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['name'] ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product['offerPrice']}',
                    style: const TextStyle(color: Colors.greenAccent),
                  ),
                  Text(
                    '₹${product['price']}',
                    style: const TextStyle(
                      color: Colors.red,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
