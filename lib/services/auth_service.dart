import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';

/// Manages Google Sign-In and secure API key storage (BYOA model).
///
/// The user signs in with their Google account for identity,
/// then provides their own Gemini API key for AI features.
class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static GoogleSignInAccount? _currentUser;
  static Future<void>? _initFuture;

  static Future<void> _init() async {
    if (_initFuture != null) return _initFuture;
    
    try {
      _initFuture = _googleSignIn.initialize(
        clientId: kIsWeb ? '720073409388-h23bgoalte4r6p9r6itt8p0snvsl5qcp.apps.googleusercontent.com' : null,
      );
      await _initFuture;
      
      _googleSignIn.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _currentUser = null;
        }
      });
    } catch (e) {
      if (e.toString().contains('already been called')) {
        // Ignore this error on Web if it's already initialized
        debugPrint('AuthService: Already initialized (ignored)');
      } else {
        rethrow;
      }
    }
  }

  static const _secureStorage = FlutterSecureStorage();
  static const _apiKeyStorageKey = 'gemini_api_key';

  static Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      _googleSignIn.authenticationEvents;

  // ─── Google Sign-In ─────────────────────────────

  /// Attempt silent sign-in (returning user).
  static Future<GoogleSignInAccount?> trySilentSignIn() async {
    try {
      await _init();
      final account = await _googleSignIn.attemptLightweightAuthentication();
      _currentUser = account;
      return account;
    } catch (_) {
      return null;
    }
  }

  /// Interactive Google Sign-In.
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      await _init();
      
      final account = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );
      _currentUser = account;
      return account;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (kIsWeb && e.toString().contains('idpiframe_initialization_failed')) {
        debugPrint('TIP: For Web, ensure you have a valid Client ID in index.html or constructor.');
      }
      return null;
    }
  }

  /// Sign out of Google (or exit offline mode).
  static Future<void> signOut() async {
    await _init();
    await _googleSignIn.signOut();
    _currentUser = null;
    _offlineMode = false;
    await _secureStorage.delete(key: _apiKeyStorageKey);
  }

  static bool _offlineMode = false;

  /// Whether a Google account is currently signed in (or offline mode).
  static bool get isSignedIn => _currentUser != null || _offlineMode;

  /// Enable offline mode (skip sign-in, use local profile).
  static void enableOfflineMode() {
    _offlineMode = true;
  }

  /// The current Google account, if signed in.
  static GoogleSignInAccount? get currentUser => _currentUser;

  /// Build a [UserProfile] from the current Google account.
  static UserProfile? buildProfile({
    ExperienceLevel experienceLevel = ExperienceLevel.beginner,
  }) {
    final user = _currentUser;
    if (user == null) return null;
    return UserProfile(
      googleId: user.id,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoUrl,
      experienceLevel: experienceLevel,
      joinDate: DateTime.now(),
    );
  }

  /// Create a mock profile for local development/bypass.
  static UserProfile buildMockProfile() {
    return UserProfile(
      googleId: 'debug_user_123',
      displayName: 'Debug User',
      email: 'debug@freedom.fitness',
      experienceLevel: ExperienceLevel.beginner,
      joinDate: DateTime.now(),
    );
  }

  // ─── Gemini API Key (BYOA) ─────────────────────

  /// Store the user's Gemini API key securely.
  static Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey);
  }

  /// Retrieve the stored Gemini API key.
  static Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyStorageKey);
  }

  /// Whether an API key has been saved.
  static Future<bool> hasApiKey() async {
    final key = await _secureStorage.read(key: _apiKeyStorageKey);
    return key != null && key.isNotEmpty;
  }

  /// Delete the stored API key.
  static Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
  }
}
