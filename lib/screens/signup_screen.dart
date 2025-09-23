import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  Future<void> _signup() async {
    setState(()=>_loading=true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );
      // After sign up, send email verification optionally
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account created. Verification email sent.')));
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Auth error')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(()=>_loading=false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Color(0xFFF48A8A);
    return Scaffold(
      appBar: AppBar(backgroundColor: primary, title: Text('Create Account')),
      body: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(controller: _email, decoration: InputDecoration(labelText: 'Email', filled: true, fillColor: Color(0xFFF0F8FF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            SizedBox(height:12),
            TextField(controller: _pass, obscureText: true, decoration: InputDecoration(labelText: 'Password', filled: true, fillColor: Color(0xFFF0F8FF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            SizedBox(height:18),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading?null:_signup, style: ElevatedButton.styleFrom(backgroundColor: primary, shape: StadiumBorder(), padding: EdgeInsets.symmetric(vertical:14)), child: _loading?CircularProgressIndicator(color: Colors.white):Text('Sign Up'))),
            Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Already have an account? '), GestureDetector(onTap: ()=>Navigator.pushReplacementNamed(context, '/login'), child: Text('Log in', style: TextStyle(color: primary)))])
          ],
        ),
      ),
    );
  }
}