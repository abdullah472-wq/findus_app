// lib/models/worker_model.dart

class Worker {
  final String uid;
  final String? postId;

  final String name;
  final String userRole;
  final String image;
  final String about;

  final bool kycCompleted;
  final double rating;
  final int completedCount;
  final int reviewsCount;

  final String location;
  final String priceText;
  final num? price;

  final bool isVerified;
  final List<String>? languages;
  final double? experience; // stored as double
  final String? gender;
  final bool isLive;
  final bool isTrusted;
  final bool isPromoted;
  final String? phone;

  // Backward Compatibility Getters
  String get id => uid;
  String get role => userRole;
  String get message => about;

  // convenience getter
  String? get experienceYears => experience?.toStringAsFixed(1);

  const Worker({
    required this.uid,
    this.postId,
    required this.name,
    required this.userRole,
    required this.image,
    this.about = "",
    this.kycCompleted = false,
    this.rating = 0.0,
    this.completedCount = 0,
    this.reviewsCount = 0,
    this.location = "Bangladesh",
    this.priceText = "Negotiable",
    this.price,
    this.isVerified = false,
    this.languages,
    this.experience,
    this.gender,
    this.isLive = false,
    this.isTrusted = false,
    this.isPromoted = false,
    this.phone,
  });

  // --------- Safe parsers ----------
  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    final s = v.toString();
    return s.isEmpty ? fallback : s;
  }

  static List<String>? _asStringList(dynamic v) {
    if (v == null) return null;
    if (v is Iterable) {
      return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return null;
  }

  /// Build from users/{uid} doc data
  factory Worker.fromUserDoc(Map<String, dynamic> map, String uid) {
    final roleRaw = _asString(map['userRole'], fallback: 'finder').toLowerCase().trim();
    final normalizedRole = (roleRaw == 'maker') ? 'maker' : 'finder';

    return Worker(
      uid: uid,

      // postId is not in user doc normally; keep null here
      postId: map['postId']?.toString(),

      name: _asString(map['name'] ?? map['fullName'], fallback: 'Unknown'),
      userRole: normalizedRole,
      image: _asString(map['image'] ?? map['imageUrl'], fallback: ''),

      about: _asString(map['about'], fallback: ''),
      kycCompleted: map['kyc_completed'] == true,
      isVerified: (map['isVerified'] == true) || (map['kyc_completed'] == true),

      rating: _asDouble(map['rating'], fallback: 0.0),

      // ✅ safe parsing (fix)
      completedCount: _asInt(map['completedCount'] ?? map['completed'], fallback: 0),
      reviewsCount: _asInt(map['reviewsCount'] ?? map['reviews'], fallback: 0),

      location: _asString(map['location'] ?? map['address'], fallback: 'Bangladesh'),
      priceText: _asString(map['priceText'] ?? map['priceLabel'], fallback: 'Negotiable'),

      price: (map['price'] is num) ? map['price'] as num : num.tryParse((map['price'] ?? '').toString()),

      experience: (map['experience'] is num)
          ? (map['experience'] as num).toDouble()
          : (map['experienceYears'] is num)
          ? (map['experienceYears'] as num).toDouble()
          : double.tryParse((map['experience'] ?? map['experienceYears'] ?? '').toString()),

      gender: map['gender']?.toString(),
      languages: _asStringList(map['languages']),

      isLive: map['isLive'] == true,
      isTrusted: map['isTrusted'] == true || map['trusted'] == true,
      isPromoted: map['isPromoted'] == true,
      phone: map['phone']?.toString(),
    );
  }
}