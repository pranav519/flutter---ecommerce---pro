import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_hop_app/CreateAcount.dart';
import 'package:shop_hop_app/Home.dart';
import 'package:shop_hop_app/Home1.dart';
import 'package:shop_hop_app/admin.dart';
import 'package:shop_hop_app/firebase_options.dart';
import 'package:shop_hop_app/Signin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final adminDoc = await FirebaseFirestore.instance
          .collection('role')
          .doc('admin')
          .collection('admin')
          .doc(uid)
          .get();

      if (adminDoc.exists) {
        return const Admin();
      } else {
        return const Home();
      }
    } else {
      return const Signin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopHop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white), // Back button color
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text("Something went wrong!")),
            );
          } else {
            return snapshot.data!;
          }
        },
      ),
      routes: {
        '/signin': (context) => const Signin(),
        '/create': (context) => const CreateAccount(),
        '/home1': (context) => const Home1(),
        '/admin': (context) => const Admin(),
      },
    );
  }
}
