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
  final double? experience; // ✅ আপনার মডেলে এটি double
  final String? gender;
  final bool isLive;
  final bool isTrusted;
  final bool isPromoted;
  final String? phone;

  // ✅ Backward Compatibility Getters
  String get id => uid;
  String get role => userRole;
  String get message => about;

  // 🔥 এই লাইনটি নতুন যোগ করুন (এরর ফিক্স করার জন্য)
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

  factory Worker.fromUserDoc(Map<String, dynamic> map, String uid) {
    final role = (map['userRole'] ?? 'finder').toString().toLowerCase().trim();
    return Worker(
      uid: uid,
      name: (map['name'] ?? 'Unknown').toString(),
      userRole: (role == 'maker') ? 'maker' : 'finder',
      image: (map['image'] ?? '').toString(),
      about: (map['about'] ?? '').toString(),
      kycCompleted: map['kyc_completed'] == true,
      isVerified: (map['isVerified'] == true) || (map['kyc_completed'] == true),
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 0.0,
      completedCount: (map['completedCount'] ?? 0) as int,
      reviewsCount: (map['reviewsCount'] ?? 0) as int,
      location: (map['location'] ?? 'Bangladesh').toString(),
      priceText: (map['priceText'] ?? 'Negotiable').toString(),
      price: (map['price'] is num) ? map['price'] as num : null,
      experience: (map['experience'] is num) ? (map['experience'] as num).toDouble() : null,
      gender: map['gender']?.toString(),
      languages: (map['languages'] as List?)?.map((e) => e.toString()).toList(),
      isLive: map['isLive'] == true,
      isTrusted: map['isTrusted'] == true,
      isPromoted: map['isPromoted'] == true,
      phone: map['phone']?.toString(),
    );
  }
}