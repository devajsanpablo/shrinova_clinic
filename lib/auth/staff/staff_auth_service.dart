import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../models/models.dart';
import '../../model/clinic_profile.dart';
import '../../core/notification_service.dart';

/// Handles clinic credentials and verifies the selected workspace membership.
///
/// Passwords are accepted by Firebase Authentication and are never written to
/// Firestore. The corresponding profile is stored at `staff/{uid}`.
class StaffAuthService {
  static Future<StaffAuthService> initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    return StaffAuthService();
  }

  StaffAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _staffCollection =>
      _firestore.collection('staff');

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase did not return the newly created staff user.');
    }

    await _staffCollection.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
    UserRole role = UserRole.staff,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    try {
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }
      final collection = role == UserRole.doctor ? 'doctor' : 'staff';
      final profile = await _firestore
          .collection(collection)
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      if (!profile.exists) {
        throw FirebaseAuthException(code: 'workspace-access-denied');
      }
      return credential;
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await ClinicNotifications.instance.signOut();
    await _auth.signOut();
  }

  Future<ClinicProfile?> loadProfile(UserRole role) async {
    final user = currentUser;
    if (user == null) throw StateError('Clinic sign-in is required.');
    final snapshot = await _firestore
        .collection(role == UserRole.doctor ? 'doctor' : 'staff')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));
    final data = snapshot.data();
    return data == null ? null : ClinicProfile.fromMap(user.uid, data);
  }

  DocumentReference<Map<String, dynamic>> profileReference(String uid) =>
      _staffCollection.doc(uid);
}
