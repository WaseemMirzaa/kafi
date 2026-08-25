import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/models/user_model.dart';
import 'package:kafi_app/services/interfaces/i_auth_service.dart';
import 'package:kafi_app/utils/validators.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FirebaseAuth phone-OTP implementation per Technical Architecture §3.1.
///
/// Authentication is phone-only — a verified SMS code is the sole credential.
/// There is no password/email linking: returning users simply verify a fresh
/// OTP on the same number and Firebase signs them back into the same account.
class FirebaseAuthService implements IAuthService {
  final _auth = FirebaseAuth.instance;
  final _users = FirebaseFirestore.instance.collection('users');

  // Held in memory for the happy path, but also mirrored to SharedPreferences so
  // an interrupted signup survives an app kill: the verification id must outlive
  // the gap between "code sent" and "code entered", and the chosen role must
  // outlive the gap between OTP and finalisation (otherwise a Family who dies
  // mid-signup gets written as the default `nanny`). Mirrors the mock's prefs
  // persistence.
  static const _keyVerificationId = 'auth_verification_id';
  static const _keyPendingRole = 'auth_pending_role';
  String? _verificationId;
  UserType? _pendingRole;

  Future<void> _persistVerificationId(String id) async {
    _verificationId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVerificationId, id);
  }

  /// The role to write at finalisation: the in-memory choice, else the durable
  /// one from a signup that was interrupted, else the `nanny` default.
  Future<UserType> _resolveRole() async {
    if (_pendingRole != null) return _pendingRole!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPendingRole);
    final role = UserType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => UserType.nanny,
    );
    _pendingRole = role;
    return role;
  }

  Future<void> _clearSignupState() async {
    _verificationId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyVerificationId);
    await prefs.remove(_keyPendingRole);
  }

  /// Builds the E.164 number from a raw national entry + dialing code, stripping
  /// spaces/dashes/parentheses and a leading trunk `0` so Firebase never sees a
  /// malformed number (a stray space is a `verificationFailed`).
  String _toE164(String phone, String countryCode) {
    final national = Validators.sanitizePhone(phone);
    final ccDigits = countryCode.replaceAll(RegExp(r'[^0-9]'), '');
    return '+$ccDigits$national';
  }

  @override
  Future<void> sendOtp(String phone, String countryCode) async {
    final completer = Completer<void>();
    await _auth.verifyPhoneNumber(
      phoneNumber: _toE164(phone, countryCode),
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
        // Fire-and-forget the durable write; the in-memory field is set
        // synchronously inside so verifyOtp works even before the write lands.
        _persistVerificationId(verificationId);
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _persistVerificationId(verificationId);
      },
    );
    await completer.future;
  }

  @override
  Future<void> verifyOtp(String code) async {
    // Fall back to the durable id if the app was killed after the code was sent.
    var id = _verificationId;
    if (id == null) {
      final prefs = await SharedPreferences.getInstance();
      id = prefs.getString(_keyVerificationId);
    }
    if (id == null) throw Exception('no_verification_id');
    final cred = PhoneAuthProvider.credential(verificationId: id, smsCode: code);
    await _auth.signInWithCredential(cred);
  }

  @override
  Future<void> finalizePhoneRegistration() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('no_user');

    final role = await _resolveRole();
    final phone = user.phoneNumber ?? '';
    // Idempotent merge — records the phone + role without clobbering an existing
    // returning-user document.
    await _users.doc(user.uid).set({
      'phone': phone,
      'type': role.name,
      'userType': role.name,
    }, SetOptions(merge: true));

    await _ensureProfileSkeleton(user.uid, role);

    // Signup is complete and the role is now durable in Firestore — drop the
    // transient prefs so a later fresh signup can't inherit this one's role.
    await _clearSignupState();
  }

  /// Creates the role-specific profile skeleton **only if it does not already
  /// exist**. Re-running registration (e.g. a returning user who signs in via
  /// OTP, or a re-tap of "verify") must never reset an approved nanny back to
  /// `draft` or wipe a family's subscription/usage counters.
  Future<void> _ensureProfileSkeleton(String uid, UserType role) async {
    if (role == UserType.family) {
      final ref = FirebaseFirestore.instance.collection('families').doc(uid);
      if ((await ref.get()).exists) return;
      await ref.set({
        'userId': uid,
        'id': uid,
        'freeContactsUsed': 0,
        'viewedProfiles': <String>[],
        // mockDev is stamped by syncMockSubscription when useMockSubscription
        // is on; leave a free baseline so real RevenueCat paths still work.
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
    final typeRaw = (data?['type'] ?? data?['userType']) as String?;
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
    // Persist the choice durably so a signup interrupted before finalisation
    // resumes with the right role instead of the `nanny` default.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingRole, type.name);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _users.doc(uid).set({
        'type': type.name,
        'userType': type.name,
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> logout() async {
    await _clearSignupState();
    _pendingRole = null;
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount(String reason) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('no_user');
    final uid = user.uid;

    // Best-effort audit of why the user left (System Spec §21). This must NEVER
    // block the deletion — a failure here previously threw before anything was
    // deleted, so the whole flow silently did nothing.
    try {
      await FirebaseFirestore.instance.collection('deletionAudits').doc(uid).set({
        'userId': uid,
        'reason': reason,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Audit is non-critical; proceed with deletion.
    }

    // Authoritative step: deleting the user doc fires `onUserDeleted`, which
    // cascades all of the user's data AND removes the Auth account via the
    // admin SDK. If this throws, deletion genuinely failed — let it propagate
    // so the UI surfaces an error instead of a false success.
    await _users.doc(uid).delete();

    // Sign the client out immediately (best-effort; the function also removes
    // the Auth account). `requires-recent-login` is expected on old sessions —
    // the server-side cascade still completes regardless.
    try {
      await user.delete();
    } catch (_) {
      // Handled server-side by onUserDeleted.
    }
    try {
      await _auth.signOut();
    } catch (_) {}
    await _clearSignupState();
    _pendingRole = null;
  }
}
