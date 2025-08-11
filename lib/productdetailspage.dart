import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shop_hop_app/buynowpage.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  final String category;

  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.category,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Map<String, dynamic>? product;
  String? selectedSize;
  int selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(widget.category)
          .doc(widget.productId)
          .get();

      if (doc.exists) {
        setState(() {
          product = doc.data();
        });
      }
    } catch (e) {
      debugPrint('Error fetching product: $e');
    }
  }

  Future<void> _addToCart() async {
    if (selectedSize == null) {
      _showAlert('Please select a size before adding to cart.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('cart')
          .doc(user.uid)
          .collection('items');

      // Check if product with same ID and size already exists
      final query = await cartRef
          .where('productId', isEqualTo: widget.productId)
          .where('size', isEqualTo: selectedSize)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        // Show alert - item already in cart with this size
        _showAlert('This product with selected size is already in the cart.');
        return;
      } else {
        // Add new product to cart
        await cartRef.add({
          'productId': widget.productId,
          'category': widget.category,
          'name': product!['name'],
          'price': product!['price'],
          'offerPrice': product!['offerPrice'],
          'imageUrl': product!['imageUrl'],
          'size': selectedSize,
          'quantity': selectedQuantity,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          selectedSize = null;
          selectedQuantity = 1;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added to cart!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add product to cart.')),
        );
      }
    }
  }

  void _showAlert(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Product Details',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        backgroundColor: Colors.black87,
      ),
      body: product == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Product images horizontal scroll
            SizedBox(
              height: screenHeight * 0.3,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  if (product!['imageUrl'] != null)
                    _buildImage(product!['imageUrl'], screenWidth),
                  if (product!['secondImageUrl'] != null)
                    _buildImage(product!['secondImageUrl'], screenWidth),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Product name
            Text(
              product!['name'] ?? '',
              style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.06,color: Colors.white),
            ),
            SizedBox(height: screenHeight * 0.01),

            // Prices Row
            Row(
              children: <Widget>[
                Text(
                  '₹${product!['offerPrice']}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  '₹${product!['price']}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    color: Colors.red,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.015),

            // Stock Info
            Text(
              'In stock: ${product!['quantity'] ?? 'N/A'}',
              style: TextStyle(fontSize: screenWidth * 0.045,color: Colors.white),
            ),

            SizedBox(height: screenHeight * 0.025),

            // Size selector label
            Text(
              'Select Size:',
              style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.w600,color: Colors.white),
            ),

            // Size dropdown
            Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.black, // Dropdown popup background color
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: Colors.black, // optional, also ensures dark popup
                value: selectedSize,
                hint: const Text(
                  'Choose a size',
                  style: TextStyle(color: Colors.white),
                ),
                items: const ['S', 'M', 'L', 'XL', 'XXL'].map((size) {
                  return DropdownMenuItem<String>(
                    value: size,
                    child: Text(
                      size,
                      style: TextStyle(color: Colors.white), // Text color in dropdown
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedSize = value),
                iconEnabledColor: Colors.white, // Dropdown icon color
              ),
            ),
            SizedBox(height: screenHeight * 0.025),
            Row(
              children: <Widget>[
                const Text('Quantity:', style: TextStyle(fontSize: 16,color: Colors.white)),
                IconButton(
                  icon: const Icon(Icons.remove,color: Colors.white,),
                  onPressed: selectedQuantity > 1
                      ? () => setState(() => selectedQuantity--)
                      : null,
                ),
                Text('$selectedQuantity', style: const TextStyle(fontSize: 18,color: Colors.white)),
                IconButton(
                  icon: const Icon(Icons.add,color: Colors.white,),
                  onPressed: () => setState(() => selectedQuantity++),
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.03),

            // Product description
            Text(
              'Product Details:',
              style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold,color: Colors.white),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              product!['description'] ?? 'No description available.',
              style: TextStyle(fontSize: screenWidth * 0.04,color: Colors.white),
            ),

            SizedBox(height: screenHeight * 0.12), // Space before bottom buttons
          ],
        ),
      ),

      // Bottom buttons bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, -2)),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Add to Cart', style: TextStyle(color: Colors.white)),
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (selectedSize == null) {
                    _showAlert('Please select a size before proceeding to buy.');
                    return;
                  }

                  final item = {
                    'productId': widget.productId,
                    'category': widget.category,
                    'name': product?['name'] ?? 'Product',
                    'imageUrl': product?['imageUrl'] ?? '',
                    'offerPrice': product?['offerPrice'] ?? 0,
                    'quantity': selectedQuantity,
                    'size': selectedSize!,
                  };

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BuyNowPage(items: [item]),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Buy Now', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url, double screenWidth) {
    return Container(
      width: screenWidth * 0.5,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.fill
        ),
      ),
    );
  }
}
