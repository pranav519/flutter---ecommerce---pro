import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shop_hop_app/address.dart';

class ViewAddressPage extends StatelessWidget {
  const ViewAddressPage({super.key});

  Future<List<Map<String, dynamic>>> fetchAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAddresses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error fetching addresses', style: TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No addresses found', style: TextStyle(color: Colors.white70)));
          }

          final addresses = snapshot.data!;
          return ListView.builder(
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final addr = addresses[index];
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name: ${addr['name']}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                      Text("phone:${addr['phone']}",style: const TextStyle(color: Colors.white70),),
                      Text("State: ${addr['state']}", style: const TextStyle(color: Colors.white70)),
                      Text("District: ${addr['district']}", style: const TextStyle(color: Colors.white70)),
                      Text("Pincode: ${addr['pincode']}", style: const TextStyle(color: Colors.white70)),
                      Text("Address: ${addr['address']}", style: const TextStyle(color: Colors.white70)),
                      Text("house:${addr['house']}",style: const TextStyle(color: Colors.white70),),
                      Text("landmark:${addr['landmark']}",style: const TextStyle(color: Colors.white70),),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: (){
        Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext)=>AddAddressPage()));
      },
      child: Icon(Icons.add),
      ),
    );
  }
}
