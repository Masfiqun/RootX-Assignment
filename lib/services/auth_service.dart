import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get user => _auth.currentUser;

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _ensureUserDoc();
  }

  Future<void> registerWithEmail(String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user!.updateDisplayName(displayName);
    await _ensureUserDoc(displayName: displayName);
  }

  // Simpler Google sign-in (no google_sign_in plugin)
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      await _auth.signInWithPopup(provider);
      await _ensureUserDoc();
      return;
    }
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile')
      ..setCustomParameters({'prompt': 'select_account'});
    await _auth.signInWithProvider(provider);
    await _ensureUserDoc();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<void> _ensureUserDoc({String? displayName}) async {
    final u = _auth.currentUser!;
    final ref = _db.collection('users').doc(u.uid);
    final snap = await ref.get();
    final data = {
      'email': u.email,
      'displayName': displayName ?? u.displayName,
      'photoUrl': u.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!snap.exists) {
      await ref.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await ref.set(data, SetOptions(merge: true));
    }
  }
}