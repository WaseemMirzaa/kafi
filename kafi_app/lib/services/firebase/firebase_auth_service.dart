import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/models/user_model.dart';
import 'package:kafi_app/services/interfaces/i_auth_service.dart';

/// FirebaseAuth phone-OTP implementation per Technical Architecture §3.1.
///
/// Authentication is phone-only — a verified SMS code is the sole credential.
/// There is no password/email linking: returning users simply verify a fresh
/// OTP on the same number and Firebase signs them back into the same account.
class FirebaseAuthService implements IAuthService {
  final _auth = FirebaseAuth.instance;
  final _users = FirebaseFirestore.instance.collection('users');
  String? _verificationId;
  UserType _pendingRole = UserType.nanny;

  @override
  Future<void> sendOtp(String phone, String countryCode) async {
    final completer = Completer<void>();
    await _auth.verifyPhoneNumber(
      phoneNumber: '$countryCode$phone',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {
        if (!completer.isCompleted) completer.complete();
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(Exception(e.message ?? 'verification_failed'));
        }
      },
      codeSent: (verificationId, _) {
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
    await completer.future;
  }

  @override
  Future<void> verifyOtp(String code) async {
    final id = _verificationId;
    if (id == null) throw Exception('no_verification_id');
    final cred = PhoneAuthProvider.credential(verificationId: id, smsCode: code);
    await _auth.signInWithCredential(cred);
  }

  @override
  Future<void> finalizePhoneRegistration() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('no_user');

    final phone = user.phoneNumber ?? '';
    // Idempotent merge — records the phone + role without clobbering an existing
    // returning-user document.
    await _users.doc(user.uid).set({
      'phone': phone,
      'type': _pendingRole.name,
    }, SetOptions(merge: true));

    await _ensureProfileSkeleton(user.uid);
  }

  /// Creates the role-specific profile skeleton **only if it does not already
  /// exist**. Re-running registration (e.g. a returning user who signs in via
  /// OTP, or a re-tap of "verify") must never reset an approved nanny back to
  /// `draft` or wipe a family's subscription/usage counters.
  Future<void> _ensureProfileSkeleton(String uid) async {
    if (_pendingRole == UserType.family) {
      final ref = FirebaseFirestore.instance.collection('families').doc(uid);
      if ((await ref.get()).exists) return;
      await ref.set({
        'userId': uid,
        'id': uid,
        'freeContactsUsed': 0,
        'viewedProfiles': <String>[],
        'subscription': {'status': 'free'},
      });
    } else {
      final ref = FirebaseFirestore.instance.collection('nannies').doc(uid);
      if ((await ref.get()).exists) return;
      await ref.set({
        'userId': uid,
        'id': uid,
        'status': NannyOnboardingStatus.draft.name,
      });
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    return _userFromFirebase(u, phone: u.phoneNumber ?? '');
  }

  Future<UserModel?> _userFromFirebase(User? u, {required String phone}) async {
    if (u == null) return null;
    final doc = await _users.doc(u.uid).get();
    final data = doc.data();
    final typeRaw = data?['type'] as String?;
    final type = typeRaw == UserType.family.name ? UserType.family : UserType.nanny;
    _pendingRole = type;
    return UserModel(
      id: u.uid,
      phone: (data?['phone'] as String?) ?? phone,
      type: type,
      fullName: data?['fullName'] as String?,
    );
  }

  @override
  Future<void> setUserRole(UserType type) async {
    _pendingRole = type;
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _users.doc(uid).set({'type': type.name}, SetOptions(merge: true));
    }
  }

  @override
  Future<void> logout() => _auth.signOut();

  @override
  Future<void> deleteAccount(String reason) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('no_user');

    // Record the deletion request in an audit log BEFORE wiping the doc so we
    // retain why the user left (per System Spec §21).
    await FirebaseFirestore.instance
        .collection('deletionAudits')
        .doc(user.uid)
        .set({
      'userId': user.uid,
      'reason': reason,
      'deletedAt': FieldValue.serverTimestamp(),
    });

    // Deleting the user doc fires `onUserDeleted` which cascades chats,
    // trials, applications, shortlists, jobs, notifications, reviews and the
    // Auth account. We still call `user.delete()` first so the client side
    // is signed out immediately if the function is delayed.
    try {
      await user.delete();
    } catch (_) {
      // Ignore — the function will clean up auth via admin SDK.
    }
    await _users.doc(user.uid).delete();
  }
}
