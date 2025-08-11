import 'package:flutter/material.dart';
import 'package:shop_hop_app/Signin.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (BuildContext)=>Signin()));
        },
            child: Text("Get Started")),
      ),
    );
  }
}
