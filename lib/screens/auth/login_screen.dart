import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/gemini_service.dart';
import '../../providers/providers.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../widgets/google_signin_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _apiKeyController = TextEditingController();
  bool _isSigningIn = false;
  bool _showApiKeyInput = false;
  bool _apiKeyObscured = true;
  String? _errorMessage;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Listen for auth events (important for Web rendered button)
    _authSubscription = AuthService.authenticationEvents.listen((event) {
      if (AuthService.isSignedIn) {
        setState(() {
          _showApiKeyInput = true;
          _isSigningIn = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _apiKeyController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });

    final account = await AuthService.signIn();
    if (account != null) {
      setState(() => _showApiKeyInput = true);
    } else {
      setState(() {
        _errorMessage = 'Sign-in cancelled or failed. Please try again.';
      });
    }

    setState(() => _isSigningIn = false);
  }

  Future<void> _handleApiKeySubmit() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Gemini API key.');
      return;
    }

    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });

    // Store the API key
    await AuthService.saveApiKey(apiKey);

    // Try to initialize Gemini
    final success = await GeminiService.initialize();
    if (!success) {
      setState(() {
        _errorMessage = 'Could not connect to Gemini API. Check your key.';
        _isSigningIn = false;
      });
      return;
    }

    // Build & save user profile
    final profile = AuthService.buildProfile();
    if (profile != null) {
      ref.read(userProfileProvider.notifier).setProfile(profile);
    }

    setState(() => _isSigningIn = false);

    if (mounted) {
      context.go('/home');
    }
  }

  void _handleDebugBypass() {
    // Mock a profile for development
    final mockProfile = AuthService.buildMockProfile();
    ref.read(userProfileProvider.notifier).setProfile(mockProfile);
    context.go('/home');
  }

  void _handleSkip() {
    AuthService.enableOfflineMode();
    final offlineProfile = AuthService.buildMockProfile();
    ref.read(userProfileProvider.notifier).setProfile(offlineProfile);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // ─── Logo / Brand ───
                GestureDetector(
                  onLongPress: _handleDebugBypass,
                  child: _buildLogo(),
                ),
                const SizedBox(height: 48),

                // ─── Title ───
                Text(
                  'Your Private AI Coach',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in with Google to unlock AI-powered features '
                  'using your own Gemini API quota.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // ─── Sign-In Flow ───
                if (!_showApiKeyInput)
                  _buildSignInSection()
                else
                  _buildApiKeySection(),

                // ─── Error Message ───
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ─── Skip Button ───
                TextButton(
                  onPressed: _handleSkip,
                  child: Text(
                    'Skip for now — use offline',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ─── BYOA Explainer ───
                _buildByoaExplainer(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/freedom_fitness_logo.png',
      width: 200,
      height: 200,
      fit: BoxFit.contain,
    );
  }

  Widget _buildSignInSection() {
    return Column(
      children: [
        if (kIsWeb)
          const GoogleSignInButton()
        else
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSigningIn ? null : _handleGoogleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1F1F1F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSigningIn
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF1F1F1F),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Continue with Google',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (kIsWeb) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 14),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Sign-in uses a popup. If blocked, enable popups or use "Skip" below.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildApiKeySection() {
    final user = AuthService.currentUser;
    return Column(
      children: [
        // Signed-in confirmation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.check,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Signed In',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // API Key input
        Text(
          'Enter Your Gemini API Key',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get your free key from ai.google.dev',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _apiKeyController,
          obscureText: _apiKeyObscured,
          style: GoogleFonts.firaCode(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'AIzaSy...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            prefixIcon: const Icon(Icons.key, color: AppColors.textMuted, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _apiKeyObscured ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _apiKeyObscured = !_apiKeyObscured),
            ),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSigningIn ? null : _handleApiKeySubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSigningIn
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Activate AI Coach',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildByoaExplainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.info, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bring Your Own Account',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your data stays on your device. AI features use your own '
            'Google API quota — we never see your data or your key.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
