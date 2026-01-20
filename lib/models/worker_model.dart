// lib/models/worker_model.dart

class Worker {
  /// user uid (NOT postId). profile open/chat open সবকিছুর জন্য এইটা লাগবে।
  final String uid;

  /// (optional) post id যদি এই Worker কোনো পোস্ট/পিন থেকে আসে
  final String? postId;

  final String name;

  /// DB role standard: 'finder' (worker/earner) or 'maker' (supporter/job maker)
  final String userRole;

  final String image;
  final String about;
  final bool kycCompleted;

  final double rating;
  final int completedCount;
  final int reviewsCount;

  final String location;
  final String priceText; // display
  final num? price; // numeric (optional)

  final String? companyName;
  final String? companyContact;

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
    this.companyName,
    this.companyContact,
  });

  /// Backward compat: old code uses worker.id
  /// -> keep a getter so old screens won't break
  String get id => uid;

  bool get isWorker => userRole.toLowerCase().trim() == 'finder';
  bool get isSupporter => userRole.toLowerCase().trim() == 'maker';

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
    String? companyName,
    String? companyContact,
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
      companyName: companyName ?? this.companyName,
      companyContact: companyContact ?? this.companyContact,
    );
  }

  /// ✅ For USERS collection docs: users/{uid}
  factory Worker.fromUserDoc(Map<String, dynamic> map, String uid) {
    final role = (map['userRole'] ?? 'finder').toString().toLowerCase().trim();
    final ratingRaw = map['rating'];

    final doubleRating = (ratingRaw is num)
        ? ratingRaw.toDouble()
        : double.tryParse(ratingRaw?.toString() ?? '') ?? 0.0;

    final priceText = (map['priceText'] ?? map['price'] ?? 'Negotiable').toString();

    return Worker(
      uid: uid,
      name: (map['name'] ?? 'Unknown').toString(),
      userRole: (role == 'maker') ? 'maker' : 'finder',
      image: (map['image'] ?? '').toString(),
      about: (map['about'] ?? '').toString(),
      kycCompleted: map['kyc_completed'] == true,
      rating: doubleRating,
      completedCount: (map['completedCount'] is num)
          ? (map['completedCount'] as num).toInt()
          : int.tryParse(map['completedCount']?.toString() ?? '') ?? 0,
      reviewsCount: (map['reviewsCount'] is num)
          ? (map['reviewsCount'] as num).toInt()
          : int.tryParse(map['reviewsCount']?.toString() ?? '') ?? 0,
      location: (map['location'] ?? 'Bangladesh').toString(),
      priceText: priceText,
      price: (map['price'] is num) ? map['price'] as num : num.tryParse(map['price']?.toString() ?? ''),
      companyName: map['companyName']?.toString(),
      companyContact: map['companyContact']?.toString(),
    );
  }

  /// ✅ For POSTS stream pins: posts/{postId}
  /// Here uid should come from map['ownerId'].
  factory Worker.fromPostPin(Map<String, dynamic> map) {
    final ownerId = (map['ownerId'] ?? '').toString();
    final postId = (map['id'] ?? '').toString();

    return Worker(
      uid: ownerId,
      postId: postId.isEmpty ? null : postId,
      name: (map['name'] ?? '').toString(),
      userRole: 'finder', // NOTE: pins viewer দেখায় opposite role, কিন্তু Worker card/profile খুলতে uid দরকার
      image: (map['image'] ?? '').toString(),
      location: (map['address'] ?? 'Bangladesh').toString(),
      priceText: (map['price'] ?? 'Negotiable').toString(),
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 0.0,
      kycCompleted: map['verified'] == true,
    );
  }

  Map<String, dynamic> toUserMap() {
    return {
      'name': name,
      'userRole': userRole, // finder/maker only
      'image': image,
      'about': about,
      'kyc_completed': kycCompleted,
      'rating': rating,
      'completedCount': completedCount,
      'reviewsCount': reviewsCount,
      'location': location,
      'priceText': priceText,
      'price': price,
      'companyName': companyName,
      'companyContact': companyContact,
    }..removeWhere((k, v) => v == null);
  }
}