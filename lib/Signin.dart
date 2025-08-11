import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email)) {
      _showAlert("Invalid Email", "Please enter a valid email address.");
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      _showAlert("Missing Fields", "Please enter both email and password.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      if (email == 'yokerzpranav@gmail.com' && password == 'pranavvk') {
        await FirebaseFirestore.instance
            .collection('role')
            .doc('admin')
            .collection('admin')
            .doc(uid)
            .set({
          'email': email,
          'role': 'admin',
          'loginTime': Timestamp.now(),
        });

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home1');
      }
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found for that email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'The email address is badly formatted.';
          break;
        default:
          message = e.message ?? 'Login failed.';
      }

      _showAlert("Wrong Password", message = e.message ?? 'please check the password');
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            child: const Text("OK", style: TextStyle(color: Colors.amber)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Sign In"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.06,
          vertical: screenHeight * 0.02,
        ),
        child: ListView(
          children: [
            Text(
              "Welcome Back",
              style: TextStyle(
                fontSize: screenWidth * 0.07,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.email, size: screenWidth * 0.06, color: Colors.white70),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: screenHeight * 0.025),
            TextField(
              controller: passwordController,
              style: const TextStyle(color: Colors.white),
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.lock, size: screenWidth * 0.06, color: Colors.white70),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    size: screenWidth * 0.055,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : SizedBox(
              height: screenHeight * 0.065,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: _signIn,
                child: Text(
                  "Sign In",
                  style: TextStyle(fontSize: screenWidth * 0.045),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.white),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/create');
                  },
                  child: Text(
                    "Create Account",
                    style: TextStyle(fontSize: screenWidth * 0.043, color: Colors.amber),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
