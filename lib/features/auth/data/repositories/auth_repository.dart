import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/services/auth_service.dart';
import 'package:lumoni/features/auth/data/datasources/auth_local_datasource.dart';

/// Repository that wraps [AuthService] and handles user profile creation
/// in Firestore on first login, along with local caching of auth state.
class AuthRepository {
  AuthRepository({
    AuthService? authService,
    AuthLocalDatasource? localDatasource,
    FirebaseFirestore? firestore,
  })  : _authService = authService ?? getIt<AuthService>(),
        _localDatasource = localDatasource ?? getIt<AuthLocalDatasource>(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthService _authService;
  final AuthLocalDatasource _localDatasource;
  final FirebaseFirestore _firestore;

  // ──────────────────── Current user ──────────────────────────────────────

  /// The currently signed-in Firebase user, if any.
  User? get currentUser => _authService.currentUser;

  /// A stream that emits whenever the authentication state changes.
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // ──────────────────── Google ────────────────────────────────────────────

  /// Signs in with Google and ensures a Firestore profile document exists.
  Future<User> signInWithGoogle() async {
    final user = await _authService.signInWithGoogle();
    await _ensureUserDocument(user);
    await _localDatasource.cacheAuthState(
      uid: user.uid,
      email: user.email,
      provider: 'google',
    );
    return user;
  }

  // ──────────────────── Apple ─────────────────────────────────────────────

  /// Signs in with Apple and ensures a Firestore profile document exists.
  Future<User> signInWithApple() async {
    final user = await _authService.signInWithApple();
    await _ensureUserDocument(user);
    await _localDatasource.cacheAuthState(
      uid: user.uid,
      email: user.email,
      provider: 'apple',
    );
    return user;
  }

  // ──────────────────── Email / Password ──────────────────────────────────

  /// Signs in with email/password.
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await _authService.signInWithEmail(
      email: email,
      password: password,
    );
    await _localDatasource.cacheAuthState(
      uid: user.uid,
      email: user.email,
      provider: 'email',
    );
    return user;
  }

  /// Creates a new account with email/password and sets up the Firestore profile.
  Future<User> signUp({
    required String email,
    required String password,
  }) async {
    final user = await _authService.signUp(
      email: email,
      password: password,
    );
    await _createUserDocument(user);
    await _localDatasource.cacheAuthState(
      uid: user.uid,
      email: user.email,
      provider: 'email',
    );
    return user;
  }

  // ──────────────────── Sign Out ──────────────────────────────────────────

  /// Signs the user out and clears the local auth cache.
  Future<void> signOut() async {
    await _authService.signOut();
    await _localDatasource.clearAuthState();
  }

  // ──────────────────── Cached auth helpers ───────────────────────────────

  /// Whether we have a locally cached authenticated session.
  bool get hasCachedSession => _localDatasource.cachedUid != null;

  /// The locally cached UID, if available.
  String? get cachedUid => _localDatasource.cachedUid;

  // ──────────────────── Firestore helpers ─────────────────────────────────

  /// Ensures a user document exists in Firestore. If the document is missing
  /// (first login), it creates one. Otherwise it updates `lastLoginAt`.
  Future<void> _ensureUserDocument(User user) async {
    final docRef =
        _firestore.collection(AppConstants.usersCollection).doc(user.uid);

    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await _createUserDocument(user);
    } else {
      await docRef.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Creates a brand-new user document in Firestore with default fields.
  Future<void> _createUserDocument(User user) async {
    final docRef =
        _firestore.collection(AppConstants.usersCollection).doc(user.uid);

    await docRef.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? '',
      'photoUrl': user.photoURL ?? '',
      'provider': _providerFromUser(user),
      'isPremium': false,
      'freeTestsUsed': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  /// Infers the authentication provider string from the [User] object.
  String _providerFromUser(User user) {
    if (user.providerData.isEmpty) return 'email';
    final providerId = user.providerData.first.providerId;
    if (providerId.contains('google')) return 'google';
    if (providerId.contains('apple')) return 'apple';
    return 'email';
  }
}
