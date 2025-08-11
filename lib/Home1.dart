import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_hop_app/productdetailspage.dart';
import 'package:shop_hop_app/viewallpage.dart';
import 'package:shop_hop_app/cartpage.dart';
import 'package:shop_hop_app/profile.dart';

class Home1 extends StatefulWidget {
  const Home1({super.key});

  @override
  State<Home1> createState() => _Home1State();
}

class _Home1State extends State<Home1> {
  String? saleImageUrl;

  // UI Display Name -> Firestore Collection Name
  final Map<String, String> _categoryMap = {
    'Men': 'Men',
    'Women': 'Women',
    'Baby and Kids': 'Kids',
    'Bags': 'Bags',
    'Decor': 'Decor',
  };

  List<Map<String, dynamic>> newestProducts = [];
  List<Map<String, dynamic>> featuredProducts = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchSaleImage();
    _fetchNewestProducts();
    _fetchFeaturedProducts();
  }

  Future<void> _fetchSaleImage() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Sale')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          saleImageUrl = snapshot.docs.first['imageUrl'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error fetching sale image: $e');
    }
  }

  Future<void> _fetchNewestProducts() async {
    try {
      List<Map<String, dynamic>> allProducts = [];
      for (final displayName in _categoryMap.keys) {
        final collectionName = _categoryMap[displayName]!;
        final snapshot = await FirebaseFirestore.instance
            .collection(collectionName)
            .orderBy('timestamp', descending: true)
            .limit(2)
            .get();
        allProducts.addAll(snapshot.docs.map((doc) => {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
          'category': collectionName,
        }));
      }
      allProducts.sort((a, b) =>
          (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));
      setState(() {
        newestProducts = allProducts;
      });
    } catch (e) {
      debugPrint('Error fetching newest products: $e');
    }
  }

  Future<void> _fetchFeaturedProducts() async {
    try {
      List<Map<String, dynamic>> featured = [];
      for (final displayName in _categoryMap.keys) {
        final collectionName = _categoryMap[displayName]!;
        final snapshot = await FirebaseFirestore.instance
            .collection(collectionName)
            .orderBy('timestamp')
            .limit(2)
            .get();
        featured.addAll(snapshot.docs.map((doc) => {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
          'category': collectionName,
        }));
      }
      setState(() {
        featuredProducts = featured;
      });
    } catch (e) {
      debugPrint('Error fetching featured products: $e');
    }
  }

  void _onCategoryTap(String displayName) {
    final collectionName = _categoryMap[displayName]!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewAllPage(categoryName: collectionName),
      ),
    );
  }

  Widget _buildProductSection({
    required String title,
    required List<Map<String, dynamic>> products,
    required double screenWidth,
    required double screenHeight,
    required VoidCallback onViewAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.02, vertical: screenHeight * 0.01),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              GestureDetector(
                onTap: onViewAll,
                child: Text('View All',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.lightBlueAccent,
                    )),
              ),
            ],
          ),
        ),
        SizedBox(
          height: screenWidth * 0.6,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
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
                  width: screenWidth * 0.4,
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(screenWidth * 0.03),
                            image: DecorationImage(
                              image: NetworkImage(product['imageUrl'] ?? ''),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.007),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product['name'] ?? '',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.035,
                                  color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${product['offerPrice']}',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.03),
                              ),
                              Text(
                                '₹${product['price']}',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: screenWidth * 0.03,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const CartPage()));
    } else if (index == 3) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    }
  }

  Widget _buildCategoryButton(String label, IconData icon, Color color,
      double iconSize, double textSize) {
    return GestureDetector(
      onTap: () => _onCategoryTap(label),
      child: Column(
        children: [
          CircleAvatar(
            radius: iconSize + 2,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          SizedBox(height: iconSize * 0.3),
          Text(label, style: TextStyle(fontSize: textSize, color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final iconSize = screenWidth * 0.07;
    final textSize = screenWidth * 0.035;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Home",
            style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.white)),
        leading: Icon(Icons.menu, size: iconSize, color: Colors.white),
        actions: [
          Icon(Icons.search, size: iconSize, color: Colors.white),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
          child: Column(
            children: [
              saleImageUrl == null
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                width: double.infinity,
                height: screenHeight * 0.25,
                decoration: BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(screenWidth * 0.04),
                  image: DecorationImage(
                    image: NetworkImage(saleImageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCategoryButton(
                      'Men', Icons.man, Colors.blue, iconSize, textSize),
                  _buildCategoryButton(
                      'Women', Icons.woman, Colors.pink, iconSize, textSize),
                  _buildCategoryButton('Baby and Kids', Icons.child_friendly,
                      Colors.orange, iconSize, textSize),
                  _buildCategoryButton(
                      'Bags', Icons.shopping_bag, Colors.teal, iconSize, textSize),
                  _buildCategoryButton(
                      'Decor', Icons.home, Colors.green, iconSize, textSize),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),
              _buildProductSection(
                title: 'Newest Arrivals',
                products: newestProducts,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewAllPage(
                        title: 'Newest Arrivals',
                        products: newestProducts,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: screenHeight * 0.03),
              _buildProductSection(
                title: 'Featured Products',
                products: featuredProducts,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewAllPage(
                        title: 'Featured Products',
                        products: featuredProducts,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        selectedFontSize: screenWidth * 0.03,
        unselectedFontSize: screenWidth * 0.025,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorite'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
