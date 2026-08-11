import 'package:flutter/material.dart';

/// Stub implementation of the Google Sign-In button for non-web platforms.
Widget buildGoogleSignInButton({VoidCallback? onPressed}) {
  return const SizedBox.shrink(); // This will be handled by the dispatcher using kIsWeb
}
