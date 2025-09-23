import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final primary = Color(0xFFF48A8A);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal:24.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/welcome.png', width:140, height:140),
                      SizedBox(height:18),
                      Text('AidSense', style: TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
                      SizedBox(height:12),
                      Text(
                        'Connect communities with the resources they need.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize:14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: StadiumBorder(),
                        padding: EdgeInsets.symmetric(vertical:14),
                      ),
                      child: Text('Get Started', style: TextStyle(color: Colors.white, fontSize:16)),
                    ),
                  ),
                  SizedBox(height:12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: OutlinedButton.styleFrom(
                        shape: StadiumBorder(),
                        padding: EdgeInsets.symmetric(vertical:14),
                        side: BorderSide(color: primary),
                      ),
                      child: Text('Log In', style: TextStyle(color: primary, fontSize:16)),
                    ),
                  ),
                  SizedBox(height:20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}