import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(()=>_loading=true);
    try {
      // Developer bypass login
      if (_email.text.trim() == 'dev@aidsense.com' && _pass.text.trim() == 'dev123') {
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }
      
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
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
      appBar: AppBar(backgroundColor: primary, title: Text('Log In')),
      body: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          children: [
            SizedBox(height:8),
            TextField(controller: _email, decoration: InputDecoration(labelText: 'Email', filled: true, fillColor: Color(0xFFF0F8FF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            SizedBox(height:12),
            TextField(controller: _pass, obscureText: true, decoration: InputDecoration(labelText: 'Password', filled: true, fillColor: Color(0xFFF0F8FF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            SizedBox(height:18),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading?null:_login, style: ElevatedButton.styleFrom(backgroundColor: primary, shape: StadiumBorder(), padding: EdgeInsets.symmetric(vertical:14)), child: _loading?CircularProgressIndicator(color: Colors.white):Text('Log In'))),
            SizedBox(height:12),
            TextButton(onPressed: ()=>Navigator.pushNamed(context, '/reset'), child: Text('Forgot password?')),
            SizedBox(height:8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Text('Developer Login:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])),
                  Text('Email: dev@aidsense.com', style: TextStyle(fontSize: 12, color: Colors.blue[700])),
                  Text('Password: dev123', style: TextStyle(fontSize: 12, color: Colors.blue[700])),
                ],
              ),
            ),
            Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('No account? '), GestureDetector(onTap: ()=>Navigator.pushNamed(context, '/signup'), child: Text('Sign up', style: TextStyle(color: primary)))])
          ],
        ),
      ),
    );
  }
}