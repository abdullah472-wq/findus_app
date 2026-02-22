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
  final double? experience;
  final String? gender;
  final bool isLive;
  final bool isTrusted;
  final bool isPromoted;
  final String? phone;

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ BACKWARD COMPATIBILITY GETTERS
  // ════════════════════════════════════════════════════════════════════════════

  String get id => uid;
  String get role => userRole;
  String get message => about;

  /// Convenience getter for experience display
  String? get experienceYears {
    if (experience == null || experience == 0.0) return null;
    return '${experience!.toStringAsFixed(1)} years';
  }

  /// Get display price
  String get displayPrice {
    if (price != null && price! > 0) {
      return '৳${price!.toInt()}';
    }
    return priceText;
  }

  /// Get role display name
  String get roleDisplayName {
    switch (userRole.toLowerCase()) {
      case 'maker':
        return 'Maker';
      case 'finder':
        return 'Finder';
      case 'supporter':
        return 'Supporter';
      default:
        return userRole.toUpperCase();
    }
  }

  /// Check if worker is available
  bool get isAvailable => isLive && !isPromoted;

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ CONSTRUCTOR
  // ════════════════════════════════════════════════════════════════════════════

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

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ SAFE TYPE CONVERTERS
  // ════════════════════════════════════════════════════════════════════════════

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
    final s = v.toString().trim();
    if (s.isEmpty || s == 'null' || s == 'undefined') return fallback;
    return s;
  }

  static List<String>? _asStringList(dynamic v) {
    if (v == null) return null;
    if (v is Iterable) {
      return v
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty && e != 'null')
          .toList();
    }
    return null;
  }

  static num? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ FACTORY: FROM USER DOCUMENT
  // ════════════════════════════════════════════════════════════════════════════

  /// Build Worker from users/{uid} document
  factory Worker.fromUserDoc(Map<String, dynamic> map, String uid) {
    final roleRaw = _asString(map['userRole'], fallback: 'finder')
        .toLowerCase()
        .trim();

    final normalizedRole = (roleRaw == 'maker') ? 'maker' : 'finder';

    // ✅ Image priority: profileImage > image > imageUrl
    final imageUrl = _asString(
      map['profileImage'] ?? map['image'] ?? map['imageUrl'],
      fallback: '',
    );

    // ✅ Name priority: name > fullName > displayName
    final displayName = _asString(
      map['name'] ?? map['fullName'] ?? map['displayName'],
      fallback: 'Unknown',
    );

    // ✅ Experience parsing
    double? experienceYears;
    final expRaw = map['experience'] ?? map['experienceYears'];
    if (expRaw != null) {
      if (expRaw is num) {
        experienceYears = expRaw.toDouble();
      } else {
        experienceYears = double.tryParse(expRaw.toString());
      }
    }

    // ✅ Price parsing
    num? priceValue;
    final priceRaw = map['price'];
    if (priceRaw != null) {
      priceValue = _asNum(priceRaw);
    }

    return Worker(
      uid: uid,
      postId: _asString(map['postId']),

      name: displayName,
      userRole: normalizedRole,
      image: imageUrl,
      about: _asString(map['about'] ?? map['bio'] ?? map['description'], fallback: ''),

      kycCompleted: map['kyc_completed'] == true || map['kycCompleted'] == true,
      isVerified: (map['isVerified'] == true) ||
          (map['kyc_completed'] == true) ||
          (map['kycCompleted'] == true),

      rating: _asDouble(map['rating'], fallback: 0.0),
      completedCount: _asInt(
        map['completedCount'] ?? map['completed'] ?? map['jobsCompleted'],
        fallback: 0,
      ),
      reviewsCount: _asInt(
        map['reviewsCount'] ?? map['reviews'] ?? map['totalReviews'],
        fallback: 0,
      ),

      location: _asString(
        map['location'] ?? map['address'] ?? map['city'],
        fallback: 'Bangladesh',
      ),

      priceText: _asString(
        map['priceText'] ?? map['priceLabel'] ?? map['price_label'],
        fallback: 'Negotiable',
      ),

      price: priceValue,
      experience: experienceYears,
      gender: _asString(map['gender']),
      languages: _asStringList(map['languages'] ?? map['skills']),

      isLive: map['isLive'] == true || map['is_live'] == true,
      isTrusted: map['isTrusted'] == true ||
          map['trusted'] == true ||
          map['is_trusted'] == true,
      isPromoted: map['isPromoted'] == true ||
          map['promoted'] == true ||
          map['is_promoted'] == true,

      phone: _asString(map['phone'] ?? map['phoneNumber']),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ FACTORY: FROM POST DOCUMENT
  // ════════════════════════════════════════════════════════════════════════════

  /// Build Worker from posts/{postId} document
  factory Worker.fromPostDoc(Map<String, dynamic> map, String postId) {
    final ownerId = _asString(map['ownerId'], fallback: '');
    final roleRaw = _asString(
      map['ownerRole'] ?? map['roleLabel'] ?? map['userRole'],
      fallback: 'finder',
    ).toLowerCase().trim();

    final normalizedRole = (roleRaw == 'maker') ? 'maker' : 'finder';

    // ✅ Image priority for post owner
    final imageUrl = _asString(
      map['ownerImage'] ??
          map['profileImage'] ??
          map['image'] ??
          map['imageUrl'],
      fallback: '',
    );

    // ✅ Name priority for post owner
    final displayName = _asString(
      map['ownerName'] ?? map['title'] ?? map['name'],
      fallback: 'Unknown',
    );

    return Worker(
      uid: ownerId,
      postId: postId,

      name: displayName,
      userRole: normalizedRole,
      image: imageUrl,
      about: _asString(map['description'] ?? map['details'], fallback: ''),

      kycCompleted: map['verified'] == true,
      isVerified: map['verified'] == true || map['isVerified'] == true,

      rating: _asDouble(map['rating'], fallback: 0.0),
      completedCount: _asInt(map['completedCount'] ?? map['approvedCount'], fallback: 0),
      reviewsCount: _asInt(map['reviewsCount'] ?? map['reviews'], fallback: 0),

      location: _asString(map['address'] ?? map['location'], fallback: 'Bangladesh'),
      priceText: _asString(map['priceLabel'] ?? map['price'], fallback: 'Negotiable'),
      price: _asNum(map['price']),

      experience: _asDouble(map['experience'], fallback: 0.0),
      gender: _asString(map['gender']),
      languages: _asStringList(map['languages']),

      isLive: map['isLive'] == true,
      isTrusted: map['trusted'] == true || map['isTrusted'] == true,
      isPromoted: map['isPromoted'] == true,

      phone: _asString(map['phone']),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ COPY WITH
  // ════════════════════════════════════════════════════════════════════════════

  Worker copyWith({
    String? uid,
    String? postId,
    String? name,
    String? userRole,
    String? image,
    String? about,
    bool? kycCompleted,
    double? rating,
    int? completedCount,
    int? reviewsCount,
    String? location,
    String? priceText,
    num? price,
    bool? isVerified,
    List<String>? languages,
    double? experience,
    String? gender,
    bool? isLive,
    bool? isTrusted,
    bool? isPromoted,
    String? phone,
  }) {
    return Worker(
      uid: uid ?? this.uid,
      postId: postId ?? this.postId,
      name: name ?? this.name,
      userRole: userRole ?? this.userRole,
      image: image ?? this.image,
      about: about ?? this.about,
      kycCompleted: kycCompleted ?? this.kycCompleted,
      rating: rating ?? this.rating,
      completedCount: completedCount ?? this.completedCount,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      location: location ?? this.location,
      priceText: priceText ?? this.priceText,
      price: price ?? this.price,
      isVerified: isVerified ?? this.isVerified,
      languages: languages ?? this.languages,
      experience: experience ?? this.experience,
      gender: gender ?? this.gender,
      isLive: isLive ?? this.isLive,
      isTrusted: isTrusted ?? this.isTrusted,
      isPromoted: isPromoted ?? this.isPromoted,
      phone: phone ?? this.phone,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ TO MAP
  // ════════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'postId': postId,
      'name': name,
      'userRole': userRole,
      'image': image,
      'about': about,
      'kycCompleted': kycCompleted,
      'rating': rating,
      'completedCount': completedCount,
      'reviewsCount': reviewsCount,
      'location': location,
      'priceText': priceText,
      'price': price,
      'isVerified': isVerified,
      'languages': languages,
      'experience': experience,
      'gender': gender,
      'isLive': isLive,
      'isTrusted': isTrusted,
      'isPromoted': isPromoted,
      'phone': phone,
    };
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ EQUALITY & HASH CODE
  // ════════════════════════════════════════════════════════════════════════════

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Worker &&
        other.uid == uid &&
        other.postId == postId;
  }

  @override
  int get hashCode => uid.hashCode ^ (postId?.hashCode ?? 0);

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ TO STRING
  // ════════════════════════════════════════════════════════════════════════════

  @override
  String toString() {
    return 'Worker(uid: $uid, name: $name, role: $userRole, rating: $rating)';
  }
}