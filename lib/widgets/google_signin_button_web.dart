import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;

/// Web implementation of the Google Sign-In button.
Widget buildGoogleSignInButton({VoidCallback? onPressed}) {
  return (GoogleSignInPlatform.instance as web.GoogleSignInPlugin).renderButton();
}
