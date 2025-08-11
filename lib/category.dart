import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_hop_app/productdetailspage.dart';

class CategoryProductsPage extends StatelessWidget {
  final String category;

  const CategoryProductsPage({super.key, required this.category});

  Future<List<Map<String, dynamic>>> _fetchCategoryProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(category)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
          'category': category,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching $category products: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final screenHeight = mq.size.height;
    final theme = Theme.of(context);

    final crossAxisSpacing = screenWidth * 0.04;
    final mainAxisSpacing = screenWidth * 0.04;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$category Products',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchCategoryProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No products found.',
                style: theme.textTheme.titleMedium,
              ),
            );
          }

          final products = snapshot.data!;
          return GridView.builder(
            padding: EdgeInsets.all(screenWidth * 0.04),
            itemCount: products.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return _ProductCard(
                product: product,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
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
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final double screenWidth;
  final double screenHeight;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.screenWidth,
    required this.screenHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(screenWidth * 0.03);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        elevation: 3,
        color: theme.cardColor,
        shadowColor: theme.shadowColor.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: borderRadius.topLeft),
                child: product['imageUrl'] != null
                    ? Image.network(
                  product['imageUrl'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, size: 50),
                  ),
                )
                    : const Center(
                  child: Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),

            // Product info section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenHeight * 0.01,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Row(
                    children: [
                      Text(
                        '₹${product['offerPrice'] ?? ''}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product['price'] != null &&
                          product['price'].toString() != product['offerPrice'].toString())
                        Text(
                          '₹${product['price']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
