import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/models/user_model.dart';
import 'package:kafi_app/services/interfaces/i_auth_service.dart';
import 'package:kafi_app/utils/constants/auth_constants.dart';

/// FirebaseAuth phone-OTP implementation per Technical Architecture §3.1.
class FirebaseAuthService implements IAuthService {
  final _auth = FirebaseAuth.instance;
  final _users = FirebaseFirestore.instance.collection('users');
  String? _verificationId;
  UserType _pendingRole = UserType.nanny;

  static String emailForPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return '${digits.isEmpty ? phone : digits}@kafi.local';
  }

  @override
  Future<void> sendOtp(String phone, String countryCode) async {
    final completer = Completer<void>();
    await _auth.verifyPhoneNumber(
      phoneNumber: '$countryCode$phone',
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
    // Preserve existing hasPassword for returning users — only set false for
    // genuinely new accounts (no existing doc).
    final existing = await _users.doc(user.uid).get();
    final hasPasswordExisting = existing.data()?['hasPassword'] as bool?;
    await _users.doc(user.uid).set({
      'phone': phone,
      'type': _pendingRole.name,
      if (hasPasswordExisting == null) 'hasPassword': false,
    }, SetOptions(merge: true));

    if (_pendingRole == UserType.family) {
      await FirebaseFirestore.instance.collection('families').doc(user.uid).set({
        'userId': user.uid,
        'id': user.uid,
        'freeContactsUsed': 0,
        'viewedProfiles': <String>[],
        'subscription': {'status': 'free'},
      }, SetOptions(merge: true));
    } else {
      await FirebaseFirestore.instance.collection('nannies').doc(user.uid).set({
        'userId': user.uid,
        'id': user.uid,
        'status': NannyOnboardingStatus.draft.name,
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> createPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('no_user');

    final phone = user.phoneNumber ?? '';
    final email = emailForPhone(phone);
    final cred = EmailAuthProvider.credential(email: email, password: password);
    try {
      await user.linkWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'provider-already-linked' && e.code != 'email-already-in-use') {
        rethrow;
      }
    }

    final roleName = _pendingRole.name;
    await _users.doc(user.uid).set({
      'phone': phone,
      'type': roleName,
      'hasPassword': true,
      'email': email,
    }, SetOptions(merge: true));

    if (_pendingRole == UserType.family) {
      await FirebaseFirestore.instance.collection('families').doc(user.uid).set({
        'userId': user.uid,
        'id': user.uid,
        'freeContactsUsed': 0,
        'viewedProfiles': <String>[],
        'subscription': {'status': 'free'},
      }, SetOptions(merge: true));
    } else {
      await FirebaseFirestore.instance.collection('nannies').doc(user.uid).set({
        'userId': user.uid,
        'id': user.uid,
        'status': NannyOnboardingStatus.draft.name,
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<UserModel?> loginWithPassword(String phone, String password) async {
    final email = emailForPhone(phone);
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return _userFromFirebase(result.user, phone: phone);
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
      hasPassword: data?['hasPassword'] == true,
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

  String? _resetVerificationId;
  // When the user successfully verifies the OTP on the reset screen we sign
  // them in with that credential (consuming it) and stash the active user so
  // `resetPassword` doesn't need to re-enter the SMS code.
  User? _resetVerifiedUser;

  @override
  Future<void> sendPasswordResetOtp(String phone, String countryCode) async {
    final completer = Completer<void>();
    await _auth.verifyPhoneNumber(
      phoneNumber: '$countryCode$phone',
      verificationCompleted: (_) {
        if (!completer.isCompleted) completer.complete();
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(Exception(e.message ?? 'verification_failed'));
        }
      },
      codeSent: (verificationId, _) {
        _resetVerificationId = verificationId;
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _resetVerificationId = verificationId;
      },
    );
    await completer.future;
  }

  @override
  Future<void> verifyPasswordResetOtp(String otp) async {
    final id = _resetVerificationId;
    if (id == null) throw Exception('no_verification_id');
    if (otp.length < AuthConstants.otpLength) {
      throw Exception('invalid_otp');
    }
    // Verify the credential by signing in with it. Firebase doesn't expose a
    // "verify-without-consuming" path, so the credential is consumed here and
    // the resulting user is cached for `resetPassword` to reuse. Errors surface
    // as `invalid-verification-code` / `session-expired` etc.
    final cred = PhoneAuthProvider.credential(verificationId: id, smsCode: otp);
    final result = await _auth.signInWithCredential(cred);
    final user = result.user;
    if (user == null) throw Exception('no_user');
    _resetVerifiedUser = user;
  }

  @override
  Future<void> resetPassword(String otp, String newPassword) async {
    // If the screen already verified the OTP, reuse the cached user; otherwise
    // fall back to signing in again with the OTP (covers callers that skip the
    // verify step).
    User? user = _resetVerifiedUser;
    if (user == null) {
      final id = _resetVerificationId;
      if (id == null) throw Exception('no_verification_id');
      final cred = PhoneAuthProvider.credential(verificationId: id, smsCode: otp);
      final result = await _auth.signInWithCredential(cred);
      user = result.user;
    }
    if (user == null) throw Exception('no_user');

    final phone = user.phoneNumber ?? '';
    final email = emailForPhone(phone);
    try {
      await user.unlink('password');
    } catch (_) {}
    final emailCred = EmailAuthProvider.credential(email: email, password: newPassword);
    try {
      await user.linkWithCredential(emailCred);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        await _auth.signInWithEmailAndPassword(email: email, password: newPassword);
      } else {
        rethrow;
      }
    }
    await _users.doc(user.uid).set({'hasPassword': true}, SetOptions(merge: true));
    _resetVerifiedUser = null;
    _resetVerificationId = null;
  }
}
