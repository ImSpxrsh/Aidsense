import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_data.dart';

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
  String? _incomingUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleCallback();
    });
  }

  Future<void> _handleCallback() async {
    // Capture the incoming URL/route for debug purposes.
    try {
      final routeName = ModalRoute.of(context)?.settings.name;
      _incomingUrl = routeName ?? Uri.base.toString();
    } catch (_) {
      _incomingUrl = Uri.base.toString();
    }

    // Wait briefly for Supabase to establish the session (race conditions
    // can occur between the browser redirect and the Flutter auth listener).
    try {
      const attempts = 20; // ~10 seconds total
      const delay = Duration(milliseconds: 500);
      var found = false;
      for (var i = 0; i < attempts; i++) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          found = true;
          break;
        }
        await Future.delayed(delay);
      }

      if (found) {
        try {
          await UserData.ensureProfileRow();
        } catch (_) {}

        // Ensure profile/user data is loaded so UI reflects Apple info.
        try {
          await UserData.loadFromSupabase();
        } catch (_) {}

        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      } else {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _checking = false);
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
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Login failed:\n$_error'),
              const SizedBox(height: 12),
              if (_incomingUrl != null) ...[
                const Text('Incoming URL:'),
                SelectableText(_incomingUrl!),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _checking = true;
                    _error = null;
                  });
                  _handleCallback();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    // Should never reach here
    return const SizedBox.shrink();
  }
}
