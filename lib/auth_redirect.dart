import 'package:flutter/foundation.dart' show kIsWeb;

/// Return URL **after** Supabase finishes OAuth — register in Supabase only (not in Google Cloud):
/// Supabase Dashboard → Authentication → URL Configuration → Redirect URLs:
///   com.aidsense.app://login-callback/
/// Flutter web: also allow your site origin here.
///
/// **Google Cloud "redirect_uri_mismatch" fix:** In Google Cloud Console, open the **Web** OAuth
/// client used in Supabase (same Client ID as Supabase → Google provider). Under **Authorized
/// redirect URIs** add **exactly** (use your real project ref from `.env` `SUPABASE_URL`):
///   https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
/// Optional **Authorized JavaScript origins**: https://YOUR_PROJECT_REF.supabase.co
String supabaseOAuthRedirectUrl() {
  if (kIsWeb) {
    return Uri.base.origin;
  }
  return 'com.aidsense.app://login-callback/';
}
