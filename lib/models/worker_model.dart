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

  // ✅ নতুন ফিল্ডসমূহ (এরর ফিক্সের জন্য)
  final bool isVerified;        // এটি মিসিং ছিল
  final List<String>? languages; // এটি মিসিং ছিল

  final double? experience;
  final String? gender;
  final bool isLive;
  final bool isTrusted;
  final bool isPromoted;
  final String? phone;

  // Optional: Backward compatibility getters
  String get id => uid;

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

    // ✅ নতুন ফিল্ডগুলো এখানে ইনিশিয়ালাইজ করা হলো
    this.isVerified = false,
    this.languages,

    this.experience,
    this.gender,
    this.isLive = false,
    this.isTrusted = false,
    this.isPromoted = false,
    this.phone,
  });

  // Factory Constructor (Firestore থেকে ডাটা নেওয়ার জন্য)
  factory Worker.fromUserDoc(Map<String, dynamic> map, String uid) {
    final role = (map['userRole'] ?? 'finder').toString().toLowerCase().trim();

    return Worker(
      uid: uid,
      name: (map['name'] ?? 'Unknown').toString(),
      userRole: (role == 'maker') ? 'maker' : 'finder',
      image: (map['image'] ?? '').toString(),
      about: (map['about'] ?? '').toString(),
      kycCompleted: map['kyc_completed'] == true,

      // isVerified সাধারণত kycCompleted এর সমান হতে পারে বা আলাদা ফিল্ড হতে পারে
      isVerified: (map['isVerified'] == true) || (map['kyc_completed'] == true),

      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 0.0,
      completedCount: (map['completedCount'] ?? 0) as int,
      reviewsCount: (map['reviewsCount'] ?? 0) as int,
      location: (map['location'] ?? 'Bangladesh').toString(),
      priceText: (map['priceText'] ?? 'Negotiable').toString(),
      price: (map['price'] is num) ? map['price'] as num : null,

      // ✅ নতুন ফিল্ড ম্যাপ করা
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