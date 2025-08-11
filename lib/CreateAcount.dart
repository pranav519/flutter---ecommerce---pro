import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    setState(() => _isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 8 characters")),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      // Save to users collection
      await FirebaseFirestore.instance
          .collection('role')
          .doc('users')
          .collection('users')
          .doc(uid)
          .set({
        'email': email,
        'role': 'user',
        'createdAt': Timestamp.now(),
      });

      // Save to admin if email & password match
      if (email == 'yokerzpranav@gmail.com' && password == 'pranavvk') {
        await FirebaseFirestore.instance
            .collection('role')
            .doc('admin')
            .collection('admin')
            .doc(uid)
            .set({
          'email': email,
          'role': 'admin',
          'createdAt': Timestamp.now(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error creating account')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback toggleVisibility,
    required double iconSize,
    required double fontSize,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: fontSize, color: Colors.white70),
        prefixIcon: Icon(Icons.lock, size: iconSize, color: Colors.white),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            size: iconSize * 0.9,
            color: Colors.white70,
          ),
          onPressed: toggleVisibility,
        ),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final screenHeight = mq.size.height;

    final double headingFont = screenWidth * 0.065;
    final double labelFont = screenWidth * 0.045;
    final double iconSize = screenWidth * 0.06;
    final double spacing = screenHeight * 0.025;
    final double buttonHeight = screenHeight * 0.065;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        elevation: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.06,
          vertical: screenHeight * 0.02,
        ),
        child: ListView(
          children: [
            Text(
              "Create your account",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: headingFont,
                color: Colors.white,
              ),
            ),
            SizedBox(height: spacing),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(fontSize: labelFont, color: Colors.white70),
                prefixIcon: Icon(Icons.email, size: iconSize, color: Colors.white),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: spacing),
            _buildPasswordField(
              controller: passwordController,
              label: "Password",
              obscureText: _obscurePassword,
              toggleVisibility: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              iconSize: iconSize,
              fontSize: labelFont,
            ),
            SizedBox(height: spacing),
            _buildPasswordField(
              controller: confirmPasswordController,
              label: "Confirm Password",
              obscureText: _obscureConfirmPassword,
              toggleVisibility: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
              iconSize: iconSize,
              fontSize: labelFont,
            ),
            SizedBox(height: spacing * 1.3),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SizedBox(
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: _createAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                ),
                child: Text(
                  "Create Account",
                  style: TextStyle(fontSize: labelFont),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
