import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/local_user.dart';
import '../services/hive_service.dart';
import '../core/data/local_database.dart';
import '../core/services/connectivity_service.dart';

// ── Auth state ────────────────────────────────────────────────────────────────

enum AuthStatus {
  unknown,       // App just opened — checking local cache
  authenticated, // Valid session (local or fresh)
  unauthenticated,
  loading,
  error,
}

// ── Controller ────────────────────────────────────────────────────────────────

class AuthController extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final HiveService _hiveService = HiveService();
  final ConnectivityService _connectivity = ConnectivityService();

  AuthStatus _status = AuthStatus.unknown;
  LocalUser? _currentUser;
  String? _errorMessage;
  bool _hasEverLoggedIn = false; // true once this device has completed first login

  // Secure storage keys
  static const _kUid       = 'myada_uid';
  static const _kIdToken   = 'myada_id_token';
  static const _kTokenTime = 'myada_token_time';
  // Tracks whether this device has previously logged in (enables offline fallback)
  static const _kHasLoggedIn  = 'myada_has_logged_in';
  // Set to 'true' after logout so that session restore skips auto-login,
  // while still preserving _kUid / _kTokenTime for offline re-login.
  static const _kIsLoggedOut  = 'myada_is_logged_out';

  AuthStatus  get status       => _status;
  LocalUser?  get currentUser  => _currentUser;
  String?     get errorMessage => _errorMessage;
  bool        get isLoggedIn   => _status == AuthStatus.authenticated;
  /// True if this device has ever completed a successful login/register.
  /// Used by AuthGate to skip onboarding for returning users.
  bool        get hasEverLoggedIn => _hasEverLoggedIn;

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    // Check the flag before session restore so AuthGate can route correctly.
    final flag = await _secureStorage.read(key: _kHasLoggedIn);
    _hasEverLoggedIn = flag == 'true';
    await _restoreSession();
  }

  // ── Session restore: "Online once, offline forever" ───────────────────────

  Future<void> _restoreSession() async {
    _setStatus(AuthStatus.unknown);

    // If the user explicitly logged out, don't auto-restore their session.
    // The credentials are kept for offline re-login, but the gate stays closed.
    final loggedOut = await _secureStorage.read(key: _kIsLoggedOut);
    if (loggedOut == 'true') {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    final cachedUid = await _secureStorage.read(key: _kUid);
    if (cachedUid == null) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    final localUser = _hiveService.getUserByUid(cachedUid);
    if (localUser == null) {
      await _clearSecureStorage();
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    // UID is known — scope all local DB reads/writes to this user.
    LocalDatabase.setUserId(cachedUid);

    // Try silent Firebase token refresh.
    try {
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser != null && fbUser.uid == cachedUid) {
        final idToken = await fbUser.getIdToken(true);
        await _cacheToken(cachedUid, idToken!);
        await _hiveService.updateLastSeen(cachedUid);
        _currentUser = localUser;
        _setStatus(AuthStatus.authenticated);
        return;
      }
    } catch (_) {
      // No internet — fall through to offline check.
    }

    // Offline fallback: accept cached session if < 30 days old.
    final tokenTimeStr = await _secureStorage.read(key: _kTokenTime);
    if (tokenTimeStr != null) {
      final tokenTime = DateTime.tryParse(tokenTimeStr);
      if (tokenTime != null) {
        final age = DateTime.now().difference(tokenTime);
        if (age.inDays < 30) {
          _currentUser = localUser;
          _setStatus(AuthStatus.authenticated);
          return;
        }
      }
    }

    _setStatus(AuthStatus.unauthenticated);
  }

  // ── Register ──────────────────────────────────────────────────────────────
  // Registration always requires an active internet connection.

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
  }) async {
    // Pre-check: require network for registration.
    if (!await _connectivity.isOnline()) {
      _errorMessage = 'Registration requires an internet connection.';
      _setStatus(AuthStatus.error);
      return false;
    }

    _setStatus(AuthStatus.loading);
    _errorMessage = null;

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = credential.user!;
      await fbUser.updateDisplayName('$firstName $lastName');
      await fbUser.sendEmailVerification();

      final idToken = await fbUser.getIdToken();

      final localUser = LocalUser()
        ..uid = fbUser.uid
        ..email = email
        ..firstName = firstName
        ..lastName = lastName
        ..dateOfBirth = dateOfBirth
        ..cachedIdToken = idToken
        ..tokenCachedAt = DateTime.now();

      await _hiveService.saveUser(localUser);
      await _cacheToken(fbUser.uid, idToken!);
      // Flag that this device has completed first login.
      await _secureStorage.write(key: _kHasLoggedIn, value: 'true');

      // Scope DB to this user immediately.
      LocalDatabase.setUserId(fbUser.uid);

      _currentUser = localUser;
      _setStatus(AuthStatus.authenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception (Register): ${e.code} - ${e.message}');
      _errorMessage = _mapFirebaseError(e.code);
      _setStatus(AuthStatus.error);
      return false;
    } catch (e, st) {
      debugPrint('Exception (Register): $e\n$st');
      _errorMessage = 'Something went wrong. Please try again.';
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  // • First login (no local user):  requires internet.
  // • Subsequent login (cached):    tries online; falls back to local on failure.

  Future<bool> login({required String email, required String password}) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;

    final online = await _connectivity.isOnline();

    // ── Offline path ────────────────────────────────────────────────────────
    if (!online) {
      final cachedUid = await _secureStorage.read(key: _kUid);
      if (cachedUid == null) {
        // No cached session at all — first login must be online.
        _errorMessage = 'Your first login requires an internet connection.';
        _setStatus(AuthStatus.error);
        return false;
      }

      final localUser = _hiveService.getUserByUid(cachedUid);
      if (localUser == null) {
        _errorMessage = 'Your first login requires an internet connection.';
        _setStatus(AuthStatus.error);
        return false;
      }

      // Verify the submitted email matches the cached user.
      // This prevents someone else's credentials from unlocking a cached session.
      if (localUser.email.toLowerCase().trim() != email.toLowerCase().trim()) {
        _errorMessage = 'Incorrect email or password.';
        _setStatus(AuthStatus.error);
        return false;
      }

      // Validate token freshness (< 30 days).
      final tokenTimeStr = await _secureStorage.read(key: _kTokenTime);
      if (tokenTimeStr != null) {
        final tokenTime = DateTime.tryParse(tokenTimeStr);
        if (tokenTime != null && DateTime.now().difference(tokenTime).inDays < 30) {
          // Clear the logged-out flag so session restore works on next launch.
          await _secureStorage.delete(key: _kIsLoggedOut);
          LocalDatabase.setUserId(cachedUid);
          _currentUser = localUser;
          _setStatus(AuthStatus.authenticated);
          debugPrint('AuthController: Offline re-login accepted (cached session).');
          return true;
        }
      }

      _errorMessage = 'Session expired. Please connect to the internet to log back in.';
      _setStatus(AuthStatus.error);
      return false;
    }

    // ── Online path ─────────────────────────────────────────────────────────
    try {
      debugPrint('AuthController: Attempting online login for $email...');
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = credential.user!;
      final idToken = await fbUser.getIdToken();

      var localUser = _hiveService.getUserByUid(fbUser.uid);
      if (localUser == null) {
        final displayName = fbUser.displayName ?? '';
        final parts = displayName.split(' ');
        localUser = LocalUser()
          ..uid = fbUser.uid
          ..email = fbUser.email ?? email
          ..firstName = parts.isNotEmpty ? parts.first : ''
          ..lastName = parts.length > 1 ? parts.last : ''
          ..dateOfBirth = '';
      }

      localUser.cachedIdToken = idToken;
      localUser.tokenCachedAt = DateTime.now();
      localUser.lastSeenAt = DateTime.now();

      await _hiveService.saveUser(localUser);
      await _cacheToken(fbUser.uid, idToken!);
      await _secureStorage.write(key: _kHasLoggedIn, value: 'true');
      // Clear the soft-logout flag so offline session restore works on next launch.
      await _secureStorage.delete(key: _kIsLoggedOut);

      // Scope all local DB reads/writes to this user.
      LocalDatabase.setUserId(fbUser.uid);

      _currentUser = localUser;
      _setStatus(AuthStatus.authenticated);
      debugPrint('AuthController: Online login successful.');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception (Login): ${e.code}');
      _errorMessage = _mapFirebaseError(e.code);
      _setStatus(AuthStatus.error);
      return false;
    } catch (e, st) {
      debugPrint('Exception (Login): $e\n$st');
      _errorMessage = 'Something went wrong. Please try again.';
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await LocalDatabase().clearAllUserData();

    // Sign out of Firebase if we can (may silently fail when offline — that's OK).
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}

    // ── Soft logout: preserve credentials for offline re-login ──────────────
    // We deliberately keep _kUid, _kIdToken, and _kTokenTime in secure storage
    // so that the offline login path can verify the user's cached session.
    // The _kIsLoggedOut flag prevents _restoreSession from auto-logging them in.
    // ⚠️ Do NOT call _clearSecureStorage() here.
    await _secureStorage.write(key: _kIsLoggedOut, value: 'true');

    // LocalUser profile (hasCompletedDiagnostic, startingLevel) stays in Hive.
    _currentUser = null;
    _hasEverLoggedIn = true;
    LocalDatabase.setUserId('anonymous');
    _setStatus(AuthStatus.unauthenticated);
  }

  // ── Forgot password ───────────────────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      return false;
    }
  }

  // ── Diagnostic completion ─────────────────────────────────────────────────

  Future<void> markDiagnosticComplete(String startingLevel) async {
    if (_currentUser == null) return;
    _currentUser!.hasCompletedDiagnostic = true;
    _currentUser!.startingLevel = startingLevel;
    await _hiveService.saveUser(_currentUser!);
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _cacheToken(String uid, String idToken) async {
    await _secureStorage.write(key: _kUid, value: uid);
    await _secureStorage.write(key: _kIdToken, value: idToken);
    await _secureStorage.write(
      key: _kTokenTime,
      value: DateTime.now().toIso8601String(),
    );
  }

  /// Hard-wipes ALL session credentials. Call this only on unrecoverable states
  /// (e.g. Hive user record missing after finding a cached UID).
  Future<void> _clearSecureStorage() async {
    await _secureStorage.delete(key: _kUid);
    await _secureStorage.delete(key: _kIdToken);
    await _secureStorage.delete(key: _kTokenTime);
    await _secureStorage.delete(key: _kIsLoggedOut);
    // Keep _kHasLoggedIn so returning users still go to LoginScreen, not onboarding.
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':       return 'No account found with this email.';
      case 'wrong-password':       return 'Incorrect password.';
      case 'invalid-credential':   return 'Invalid email or password.';
      case 'email-already-in-use': return 'An account with this email already exists.';
      case 'weak-password':        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':        return 'Please enter a valid email address.';
      case 'network-request-failed': return 'No internet connection. Please try again.';
      case 'too-many-requests':    return 'Too many attempts. Please wait and try again.';
      case 'operation-not-allowed': return 'Email/Password accounts are not enabled.';
      default: return 'Authentication error: $code. Please try again.';
    }
  }
}
