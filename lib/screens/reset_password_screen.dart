import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;

  Future<void> _reset() async {
    setState(()=>_loading=true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset email sent.')));
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Auth error')));
    } finally {
      setState(()=>_loading=false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Color(0xFFF48A8A);
    return Scaffold(
      appBar: AppBar(backgroundColor: primary, title: Text('Reset Password')),
      body: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(controller: _email, decoration: InputDecoration(labelText: 'Email', filled: true, fillColor: Color(0xFFF0F8FF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            SizedBox(height:18),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading?null:_reset, style: ElevatedButton.styleFrom(backgroundColor: primary, shape: StadiumBorder(), padding: EdgeInsets.symmetric(vertical:14)), child: _loading?CircularProgressIndicator(color: Colors.white):Text('Send Reset Email'))),
          ],
        ),
      ),
    );
  }
}