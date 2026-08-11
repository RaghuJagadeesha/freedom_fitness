import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'google_signin_button_stub.dart'
    if (dart.library.js_interop) 'google_signin_button_web.dart';

/// A cross-platform Google Sign-In button.
/// On Web, it renders the mandatory official GIS button.
/// On Mobile, it returns a placeholder as we use a custom button.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleSignInButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return buildGoogleSignInButton(onPressed: onPressed);
    }
    return const SizedBox.shrink();
  }
}
