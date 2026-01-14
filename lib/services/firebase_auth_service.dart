import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

/// Firebase Authentication Service
class FirebaseAuthService {
  static final FirebaseAuthService instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcı
  User? get currentUser => _firebaseAuth.currentUser;
  bool get isLoggedIn => currentUser != null;

  /// Email ve şifre ile kayıt
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      AppLogger.log('📝 Registering user: $email');

      // Firebase Auth'ta kullanıcı oluştur
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('User creation failed');

      // Firestore'a kullanıcı verisi kaydet
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'fullName': fullName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.log('✅ User registered successfully: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      AppLogger.log('❌ Registration error: ${e.message}');
      return false;
    } catch (e) {
      AppLogger.log('❌ Unexpected error: $e');
      return false;
    }
  }

  /// Email ve şifre ile giriş
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.log('🔐 Login attempt: $email');

      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppLogger.log('✅ Login successful: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      AppLogger.log('❌ Login error: ${e.message}');
      return false;
    } catch (e) {
      AppLogger.log('❌ Unexpected error: $e');
      return false;
    }
  }

  /// Google ile giriş (UI'dan handle ediliyor)
  Future<bool> signInWithGoogle({
    required String email,
    required String fullName,
  }) async {
    try {
      AppLogger.log('🔐 Google sign-in: $email');

      // Google sign-in başarılı varsayılıyor (UI'dan işlem yapıldı)
      // Firestore'a kullanıcı verisi kaydet
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set(
          {
            'uid': user.uid,
            'email': user.email,
            'fullName': fullName,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      AppLogger.log('✅ Google sign-in successful: $email');
      return true;
    } catch (e) {
      AppLogger.log('❌ Google sign-in error: $e');
      return false;
    }
  }

  /// Çıkış
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      AppLogger.log('✅ Logout successful');
    } catch (e) {
      AppLogger.log('❌ Logout error: $e');
    }
  }

  /// Kullanıcı verisi al
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      AppLogger.log('❌ Get user data error: $e');
      return null;
    }
  }

  /// Şifre sıfırlama
  Future<bool> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      AppLogger.log('✅ Password reset email sent: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      AppLogger.log('❌ Password reset error: ${e.message}');
      return false;
    }
  }

  /// Email doğrulama
  Future<bool> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
      AppLogger.log('✅ Verification email sent');
      return true;
    } catch (e) {
      AppLogger.log('❌ Email verification error: $e');
      return false;
    }
  }
}
