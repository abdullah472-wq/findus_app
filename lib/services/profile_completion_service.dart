import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ProfileCompletionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // কমন কি-সমূহ যা সবার জন্য প্রয়োজন
  static const List<String> _commonKeys = [
    'user_name',
    'user_phone',
    'user_location',
    'user_gender',
    'user_age',
  ];

  // সাপোর্টারদের জন্য অতিরিক্ত কি-সমূহ
  static const List<String> _supporterExtraKeys = [
    'company_name',
    'company_contact',
    'company_address',
  ];

  // ওয়ার্কারদের জন্য অতিরিক্ত কি-সমূহ
  static const List<String> _workerExtraKeys = [
    'worker_price',
    'worker_experience',
    'worker_languages',
  ];

  /// প্রোফাইল কমপ্লিট কি না চেক করা (এখন এটি রোল অনুযায়ী কাজ করবে)
  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final role = (prefs.getString('user_role') ?? '').toLowerCase();

    bool allFilled = true;

    // ১. কমন ফিল্ড চেক
    for (final key in _commonKeys) {
      if ((prefs.getString(key) ?? '').trim().isEmpty && prefs.getInt(key) == null) {
        allFilled = false;
        break;
      }
    }

    // ২. রোল অনুযায়ী অতিরিক্ত ফিল্ড চেক
    if (allFilled) {
      final extraKeys = (role == 'finder') ? _workerExtraKeys : _supporterExtraKeys;
      for (final key in extraKeys) {
        if ((prefs.getString(key) ?? '').trim().isEmpty) {
          allFilled = false;
          break;
        }
      }
    }

    await _syncLocalToFirestore(prefs: prefs, isCompletedFlag: allFilled);
    return allFilled;
  }

  /// কমপ্লিশন পারসেন্টেজ ক্যালকুলেশন (0.0 to 1.0)
  static Future<double> completionPercent() async {
    final prefs = await SharedPreferences.getInstance();
    final role = (prefs.getString('user_role') ?? '').toLowerCase();

    int filled = 0;

    // টোটাল ফিল্ড হিসাব: কমন (৫) + রোল স্পেসিফিক (৩) + সোশ্যাল (৪) + KYC (১) = ১৩টি
    const int total = 13;

    bool notEmpty(String? v) => (v ?? '').trim().isNotEmpty;

    // কমন ৫টি
    if (notEmpty(prefs.getString('user_name'))) filled++;
    if (notEmpty(prefs.getString('user_phone'))) filled++;
    if (notEmpty(prefs.getString('user_location'))) filled++;
    if (notEmpty(prefs.getString('user_gender'))) filled++;
    if (prefs.getInt('user_age') != null) filled++;

    // রোল অনুযায়ী ৩টি
    if (role == 'finder') {
      if (notEmpty(prefs.getString('worker_price'))) filled++;
      if (notEmpty(prefs.getString('worker_experience'))) filled++;
      if (notEmpty(prefs.getString('worker_languages'))) filled++;
    } else {
      if (notEmpty(prefs.getString('company_name'))) filled++;
      if (notEmpty(prefs.getString('company_contact'))) filled++;
      if (notEmpty(prefs.getString('company_address'))) filled++;
    }

    // সোশ্যাল ৪টি
    if (notEmpty(prefs.getString('user_email'))) filled++;
    if (notEmpty(prefs.getString('user_facebook'))) filled++;
    if (notEmpty(prefs.getString('user_instagram'))) filled++;
    if (notEmpty(prefs.getString('user_linkedin'))) filled++;

    // KYC ১টি
    if (prefs.getBool('kyc_completed') ?? false) filled++;

    final percent = filled / total;

    await _syncLocalToFirestore(prefs: prefs, completionPercent: percent);
    return percent;
  }

  /// প্রোফাইল এডিট স্ক্রিন থেকে ফোর্স সিঙ্ক
  static Future<void> forceSyncFromLocal() async {
    final completed = await isCompleted();
    final percent = await completionPercent();
    final prefs = await SharedPreferences.getInstance();

    await _syncLocalToFirestore(
      prefs: prefs,
      isCompletedFlag: completed,
      completionPercent: percent,
    );
  }

  /// ফায়ারবেস সিঙ্ক লজিক (সব নতুন ফিল্ডসহ)
  static Future<void> _syncLocalToFirestore({
    required SharedPreferences prefs,
    bool? isCompletedFlag,
    double? completionPercent,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    final data = <String, dynamic>{
      'name': prefs.getString('user_name'),
      'phone': prefs.getString('user_phone'),
      'location': prefs.getString('user_location'),
      'gender': prefs.getString('user_gender'),
      'age': prefs.getInt('user_age'),
      'email': prefs.getString('user_email'),
      'facebook': prefs.getString('user_facebook'),
      'instagram': prefs.getString('user_instagram'),
      'linkedin': prefs.getString('user_linkedin'),
      'kyc_completed': prefs.getBool('kyc_completed') ?? false,
      'image': prefs.getString('user_profile_image'), // আপনার আপলোড করা ইমেজ লিঙ্ক

      // রোল অনুযায়ী ডাটা
      'companyName': prefs.getString('company_name'),
      'companyContact': prefs.getString('company_contact'),
      'companyAddress': prefs.getString('company_address'),

      'workerPrice': prefs.getString('worker_price'),
      'experience': prefs.getString('worker_experience'),

      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (isCompletedFlag != null) data['isProfileCompleted'] = isCompletedFlag;
    if (completionPercent != null) data['completionPercent'] = completionPercent;

    // ক্লিনআপ: নাল ভ্যালু রিমুভ করা যাতে ফায়ারবেস ক্লিন থাকে
    data.removeWhere((key, value) => value == null);

    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }
}