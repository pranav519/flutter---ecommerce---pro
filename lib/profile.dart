import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_hop_app/address.dart';
import 'package:shop_hop_app/orders.dart';
import 'package:shop_hop_app/viewaddress.dart';
import 'package:shop_hop_app/signin.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
  }

  Future<String> getUserName() async {
    final doc = await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .get();
    return doc.data()?['name'] ?? 'Guest';
  }

  Future<void> updateUserName(String newName) async {
    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .set({'name': newName}, SetOptions(merge: true));
    setState(() {}); // Refresh UI
  }

  void _showEditNameDialog(String currentName) {
    TextEditingController controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter your name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await updateUserName(newName);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
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
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Account',
          style: TextStyle(color: Colors.white, fontSize: 18 * fontScale),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Signin()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.02),
            CircleAvatar(
              radius: screenWidth * 0.15,
              backgroundColor: Colors.grey.shade800,
              child: Icon(Icons.person, size: screenWidth * 0.15, color: Colors.white),
            ),
            SizedBox(height: screenHeight * 0.015),
            FutureBuilder<String>(
              future: getUserName(),
              builder: (context, snapshot) {
                final name = snapshot.data ?? 'Loading...';
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18 * fontScale,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                      onPressed: () {
                        _showEditNameDialog(name);
                      },
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: screenHeight * 0.025),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please verify your email or number',
                    style: TextStyle(color: Colors.white, fontSize: 14 * fontScale),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get newest offers',
                    style: TextStyle(color: Colors.grey, fontSize: 12 * fontScale),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Colors.white12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _currentUser?.phoneNumber ?? _currentUser?.email ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          'Verify now',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            const Divider(color: Colors.white10),
            _profileOption('Address Manager', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ViewAddressPage()),
              );
            }),
            _profileOption('My Order', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrdersPage()),
              );
            }),
            _profileOption('My Offers'),
            _profileOption('Wishlist'),
            _profileOption('Quick Pay Cards'),
            _profileOption('Help Center'),
          ],
        ),
      ),
    );
  }

  Widget _profileOption(String title, {VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          onTap: onTap,
        ),
        const Divider(color: Colors.white10),
      ],
    );
  }
}
