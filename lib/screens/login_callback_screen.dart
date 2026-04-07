import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles the /login-callback/ deep link after Google sign-in.
/// Checks Supabase session and navigates to /home if authenticated.
class LoginCallbackScreen extends StatefulWidget {
  const LoginCallbackScreen({super.key});

  @override
  State<LoginCallbackScreen> createState() => _LoginCallbackScreenState();
}

class _LoginCallbackScreenState extends State<LoginCallbackScreen> {
  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // User is authenticated, go to home
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
        }
      } else {
        // Not authenticated, go to login
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Login failed:\n$_error')),
      );
    }
    // Should never reach here
    return const SizedBox.shrink();
  }
}
