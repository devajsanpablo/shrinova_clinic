// Firestore types are faked only at the SDK boundary in these unit tests.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/auth/staff/staff_auth_service.dart';
import 'package:rmc_clinic_health/models/models.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'account-uid';
}

class _Credential extends Fake implements UserCredential {
  @override
  User get user => _User();
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => signedOut ? null : _User();
  bool signedOut = false;
  bool rejectPassword = false;
  String? enteredEmail;
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    enteredEmail = email;
    if (rejectPassword) throw FirebaseAuthException(code: 'invalid-credential');
    return _Credential();
  }

  @override
  Future<void> signOut() async => signedOut = true;
}

class _Firestore extends Fake implements FirebaseFirestore {
  String? requestedCollection;
  String? requestedUid;
  Source? source;
  bool profileExists = true;
  bool denyRead = false;
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    requestedCollection = collectionPath;
    return _Collection(this);
  }
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.db);
  final _Firestore db;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    db.requestedUid = path;
    return _Document(db);
  }
}

class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Document(this.db);
  final _Firestore db;
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    db.source = options?.source;
    if (db.denyRead) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
    return _Snapshot(db.profileExists);
  }
}

class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.exists);
  @override
  final bool exists;
  @override
  Map<String, dynamic>? data() => exists
      ? {
          'fullName': 'Alex Cruz',
          'email': 'alex@example.com',
          'phone': '09123456789',
        }
      : null;
}

void main() {
  for (final role in UserRole.values) {
    test(
      '$role loads the signed-in account profile from its collection',
      () async {
        final db = _Firestore();
        final profile = await StaffAuthService(
          auth: _Auth(),
          firestore: db,
        ).loadProfile(role);
        expect(
          db.requestedCollection,
          role == UserRole.doctor ? 'doctor' : 'staff',
        );
        expect(db.requestedUid, 'account-uid');
        expect(db.source, Source.server);
        expect(profile!.name, 'Alex Cruz');
        expect(profile.email, 'alex@example.com');
        expect(profile.initials, 'AC');
      },
    );
    test('$role requires the matching server profile', () async {
      final auth = _Auth();
      final db = _Firestore();
      final service = StaffAuthService(auth: auth, firestore: db);
      await service.signIn(
        email: ' doctor@example.com ',
        password: 'test-only',
        role: role,
      );
      expect(auth.enteredEmail, 'doctor@example.com');
      expect(
        db.requestedCollection,
        role == UserRole.doctor ? 'doctor' : 'staff',
      );
      expect(db.requestedUid, 'account-uid');
      expect(db.source, Source.server);
      expect(auth.signedOut, isFalse);
    });
  }

  test('profile loading does not query Firestore when signed out', () async {
    final db = _Firestore();
    await expectLater(
      StaffAuthService(
        auth: _Auth()..signedOut = true,
        firestore: db,
      ).loadProfile(UserRole.staff),
      throwsStateError,
    );
    expect(db.requestedCollection, isNull);
  });

  test('missing profile returns no fabricated details', () async {
    final profile = await StaffAuthService(
      auth: _Auth(),
      firestore: _Firestore()..profileExists = false,
    ).loadProfile(UserRole.doctor);
    expect(profile, isNull);
  });

  test('missing doctor membership rejects login and signs out', () async {
    final auth = _Auth();
    final service = StaffAuthService(
      auth: auth,
      firestore: _Firestore()..profileExists = false,
    );
    await expectLater(
      service.signIn(
        email: 'staff@example.com',
        password: 'test-only',
        role: UserRole.doctor,
      ),
      throwsA(
        isA<FirebaseAuthException>().having(
          (e) => e.code,
          'code',
          'workspace-access-denied',
        ),
      ),
    );
    expect(auth.signedOut, isTrue);
  });

  test('failed profile read signs out instead of entering workspace', () async {
    final auth = _Auth();
    final service = StaffAuthService(
      auth: auth,
      firestore: _Firestore()..denyRead = true,
    );
    await expectLater(
      service.signIn(
        email: 'doctor@example.com',
        password: 'test-only',
        role: UserRole.doctor,
      ),
      throwsA(
        isA<FirebaseException>().having(
          (e) => e.code,
          'code',
          'permission-denied',
        ),
      ),
    );
    expect(auth.signedOut, isTrue);
  });

  test('invalid password does not query profiles', () async {
    final auth = _Auth()..rejectPassword = true;
    final db = _Firestore();
    await expectLater(
      StaffAuthService(auth: auth, firestore: db).signIn(
        email: 'doctor@example.com',
        password: 'wrong',
        role: UserRole.doctor,
      ),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(db.requestedCollection, isNull);
  });
}
