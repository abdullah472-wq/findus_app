// lib/services/profile_completion_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ProfileCompletionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ Prefs keys (match your UnifiedProfileEditScreen)
  static const String _kName = 'user_name';
  static const String _kPhone = 'user_phone';
  static const String _kLocation = 'user_location';
  static const String _kRole = 'user_role'; // 'finder' or 'maker'
  static const String _kImage = 'user_image';

  // Optional prefs (you may or may not store them)
  static const String _kEmail = 'user_email';
  static const String _kFacebook = 'user_facebook';
  static const String _kInstagram = 'user_instagram';
  static const String _kLinkedin = 'user_linkedin';
  static const String _kKyc = 'kyc_completed';

  // If you ever store these in prefs later, we will use them too:
  static const String _kGender = 'user_gender';
  static const String _kAge = 'user_age';

  static bool _notEmpty(String? v) => (v ?? '').trim().isNotEmpty;

  static Future<DocumentSnapshot<Map<String, dynamic>>?> _getUserDoc() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).get();
  }

  static String _roleFromPrefs(SharedPreferences prefs) {
    final r = (prefs.getString(_kRole) ?? '').toLowerCase().trim();
    // ✅ standardize
    if (r == 'finder' || r == 'maker') return r;
    // fallback default
    return 'finder';
  }

  static String _safeString(dynamic v) => v == null ? '' : v.toString().trim();

  static bool _isFilledStringField(dynamic v) => _safeString(v).isNotEmpty;

  static bool _isFilledNumField(dynamic v) {
    if (v == null) return false;
    if (v is num) return true;
    return num.tryParse(v.toString()) != null;
  }

  // -----------------------------
  // ✅ REQUIRED CHECK (role aware)
  // -----------------------------
  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final role = _roleFromPrefs(prefs);

    // Common from prefs (these are the ones you actually save today)
    final hasName = _notEmpty(prefs.getString(_kName));
    final hasPhone = _notEmpty(prefs.getString(_kPhone));
    final hasLocation = _notEmpty(prefs.getString(_kLocation));

    // Gender/Age: in your edit screen you store in Firestore,
    // prefs may not have them. So we will treat them as required
    // but read from Firestore (fallback to prefs if present).
    final userDoc = await _getUserDoc();
    final data = userDoc?.data() ?? <String, dynamic>{};

    final gender = _notEmpty(prefs.getString(_kGender))
        ? prefs.getString(_kGender)
        : _safeString(data['gender']);
    final ageVal = prefs.getInt(_kAge) ?? (data['age'] is int ? data['age'] as int : int.tryParse(_safeString(data['age'])));

    final hasGender = _notEmpty(gender);
    final hasAge = ageVal != null && ageVal > 0;

    bool allFilled = hasName && hasPhone && hasLocation && hasGender && hasAge;

    // Role-specific required from Firestore (since you don't store them in prefs)
    if (allFilled) {
      if (role == 'finder') {
        // Worker required fields (align with UnifiedProfileEditScreen save fields)
        final hasServiceType = _isFilledStringField(data['roleKey']) || _isFilledStringField(data['role']);
        final hasPrice = _isFilledStringField(data['priceText']) || _isFilledNumField(data['price']);
        final hasExperience = _isFilledNumField(data['experienceYears']) || _isFilledStringField(data['experienceYears']);
        final hasLanguages = _isFilledStringField(data['languages']);
        final hasWorkStart = _isFilledStringField(data['workStart']);
        final hasWorkEnd = _isFilledStringField(data['workEnd']);

        allFilled = hasServiceType && hasPrice && hasExperience && hasLanguages && hasWorkStart && hasWorkEnd;
      } else {
        // Supporter required fields
        final hasCompanyName = _isFilledStringField(data['companyName']);
        final hasCompanyContact = _isFilledStringField(data['companyContact']);
        final hasCompanyAddress = _isFilledStringField(data['companyAddress']);

        allFilled = hasCompanyName && hasCompanyContact && hasCompanyAddress;
      }
    }

    await _syncCompletionToFirestore(
      prefs: prefs,
      userData: data,
      isCompletedFlag: allFilled,
    );

    return allFilled;
  }

  // -----------------------------------
  // ✅ COMPLETION PERCENT (role aware)
  // -----------------------------------
  static Future<double> completionPercent() async {
    final prefs = await SharedPreferences.getInstance();
    final role = _roleFromPrefs(prefs);

    final userDoc = await _getUserDoc();
    final data = userDoc?.data() ?? <String, dynamic>{};

    // We count a realistic total based on what you actually collect.
    // Common 5 + role-specific 6(worker) or 3(supporter) + social 4 + kyc 1 + image 1
    // Worker total = 5 + 6 + 4 + 1 + 1 = 17
    // Supporter total = 5 + 3 + 4 + 1 + 1 = 14
    final int total = (role == 'finder') ? 17 : 14;

    int filled = 0;

    // Common (5): name, phone, location, gender, age
    if (_notEmpty(prefs.getString(_kName)) || _isFilledStringField(data['name'])) filled++;
    if (_notEmpty(prefs.getString(_kPhone)) || _isFilledStringField(data['phone'])) filled++;
    if (_notEmpty(prefs.getString(_kLocation)) || _isFilledStringField(data['location'])) filled++;

    final gender = _notEmpty(prefs.getString(_kGender))
        ? prefs.getString(_kGender)
        : _safeString(data['gender']);
    if (_notEmpty(gender)) filled++;

    final ageVal = prefs.getInt(_kAge) ??
        (data['age'] is int ? data['age'] as int : int.tryParse(_safeString(data['age'])));
    if (ageVal != null && ageVal > 0) filled++;

    // Profile image (1)
    final img = _notEmpty(prefs.getString(_kImage)) ? prefs.getString(_kImage) : _safeString(data['image']);
    if (_notEmpty(img)) filled++;

    // Role-specific
    if (role == 'finder') {
      // Worker (6): service type, price, expYears, languages, workStart, workEnd
      if (_isFilledStringField(data['roleKey']) || _isFilledStringField(data['role'])) filled++;
      if (_isFilledStringField(data['priceText']) || _isFilledNumField(data['price'])) filled++;
      if (_isFilledNumField(data['experienceYears']) || _isFilledStringField(data['experienceYears'])) filled++;
      if (_isFilledStringField(data['languages'])) filled++;
      if (_isFilledStringField(data['workStart'])) filled++;
      if (_isFilledStringField(data['workEnd'])) filled++;
    } else {
      // Supporter (3)
      if (_isFilledStringField(data['companyName'])) filled++;
      if (_isFilledStringField(data['companyContact'])) filled++;
      if (_isFilledStringField(data['companyAddress'])) filled++;
    }

    // Social (4) - prefer Firestore fields used in your app: email/facebookUrl/instagramUrl/linkedInUrl
    final email = _notEmpty(prefs.getString(_kEmail)) ? prefs.getString(_kEmail) : _safeString(data['email']);
    final fb = _notEmpty(prefs.getString(_kFacebook)) ? prefs.getString(_kFacebook) : _safeString(data['facebookUrl']);
    final ig = _notEmpty(prefs.getString(_kInstagram)) ? prefs.getString(_kInstagram) : _safeString(data['instagramUrl']);
    final li = _notEmpty(prefs.getString(_kLinkedin)) ? prefs.getString(_kLinkedin) : _safeString(data['linkedInUrl']);

    if (_notEmpty(email)) filled++;
    if (_notEmpty(fb)) filled++;
    if (_notEmpty(ig)) filled++;
    if (_notEmpty(li)) filled++;

    // KYC (1)
    final kyc = (prefs.getBool(_kKyc) ?? false) || (data['kyc_completed'] == true);
    if (kyc) filled++;

    final percent = (total == 0) ? 0.0 : (filled / total);

    await _syncCompletionToFirestore(
      prefs: prefs,
      userData: data,
      completionPercent: percent,
    );

    return percent;
  }

  // -----------------------------
  // ✅ FORCE SYNC (optional use)
  // -----------------------------
  static Future<void> forceSyncFromLocal() async {
    final completed = await isCompleted();
    final percent = await completionPercent();
    final prefs = await SharedPreferences.getInstance();

    final userDoc = await _getUserDoc();
    final data = userDoc?.data() ?? <String, dynamic>{};

    await _syncCompletionToFirestore(
      prefs: prefs,
      userData: data,
      isCompletedFlag: completed,
      completionPercent: percent,
    );
  }

  // ------------------------------------
  // ✅ Firestore sync (aligned fields)
  // ------------------------------------
  static Future<void> _syncCompletionToFirestore({
    required SharedPreferences prefs,
    required Map<String, dynamic> userData,
    bool? isCompletedFlag,
    double? completionPercent,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    final role = _roleFromPrefs(prefs);

    final data = <String, dynamic>{
      // common identity (prefer existing firestore if prefs empty)
      'name': _notEmpty(prefs.getString(_kName)) ? prefs.getString(_kName) : userData['name'],
      'phone': _notEmpty(prefs.getString(_kPhone)) ? prefs.getString(_kPhone) : userData['phone'],
      'location': _notEmpty(prefs.getString(_kLocation)) ? prefs.getString(_kLocation) : userData['location'],
      'image': _notEmpty(prefs.getString(_kImage)) ? prefs.getString(_kImage) : userData['image'],

      // role
      'userRole': role, // keep consistent: finder/maker

      // completion flags
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    // gender/age (prefer prefs if you store later, else keep firestore)
    if (_notEmpty(prefs.getString(_kGender))) data['gender'] = prefs.getString(_kGender);
    if (prefs.getInt(_kAge) != null) data['age'] = prefs.getInt(_kAge);

    if (isCompletedFlag != null) data['isProfileCompleted'] = isCompletedFlag;
    if (completionPercent != null) data['completionPercent'] = completionPercent;

    // Keep existing fields as-is; don't overwrite with null
    data.removeWhere((_, v) => v == null);

    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }
}