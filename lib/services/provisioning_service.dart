import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NextScreenAfterAuth {
  roleSelection,
  completeProfile,
  explore,
  blocked,
}

class ProvisioningService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  /// pendingRole: 'maker' বা 'finder' (Sign up path থেকে আসবে)
  static Future<NextScreenAfterAuth> ensureUserDoc({String? pendingRole}) async {
    final user = _auth.currentUser;
    if (user == null) return NextScreenAfterAuth.roleSelection;

    final uid = user.uid;
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();

    // 1) ডক না থাকলে: pendingRole ছাড়া create করা যাবে না (আপনার ফ্লো অনুযায়ী)
    if (!snap.exists) {
      if (pendingRole == null || pendingRole.isEmpty) {
        return NextScreenAfterAuth.roleSelection;
      }

      final coreRole = pendingRole == 'maker' ? 'supporter' : 'worker';

      await ref.set({
        'userRole': coreRole,
        'roles': [coreRole],
        'isSupporter': coreRole == 'supporter',
        'isWorker': coreRole == 'worker',
        'profileCompleted': false,
        'isBlocked': false,
        'kycStatus': 'none',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // লোকাল ক্যাশ (আপনার ExploreScreen এইটা পড়ে)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', pendingRole);

      return NextScreenAfterAuth.completeProfile;
    }

    // 2) ডক থাকলে: রোল ওভাররাইট করবেন না
    final data = snap.data() as Map<String, dynamic>;

    final isBlocked = data['isBlocked'] == true;
    if (isBlocked) return NextScreenAfterAuth.blocked;

    final completed = data['profileCompleted'] == true;

    // লোকাল ক্যাশ আপডেট (ডক থেকে map করে)
    final userRole = (data['userRole'] ?? '').toString(); // 'supporter'/'worker'
    final makerFinder = userRole == 'supporter' ? 'maker' : 'finder';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', makerFinder);

    // টাচ/লাস্ট লগইন আপডেট (ঐচ্ছিক)
    await ref.set({'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

    return completed ? NextScreenAfterAuth.explore : NextScreenAfterAuth.completeProfile;
  }
}