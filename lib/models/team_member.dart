// lib/models/team_member.dart

class TeamMember {
  final String id;        // userId
  final String name;
  final String phone;
  final String role;      // owner / manager / staff
  final bool isPending;   // invite accepted হয়েছে কিনা

  // 🔹 স্ট্যাটিসটিক্স
  final int jobsCompleted;
  final int jobsInProgress;
  final double totalEarnings; // double করা হয়েছে হিসাবের সুবিধার্থে
  final double rating;
  final DateTime? joinedAt;   // নতুন যুক্ত করা হয়েছে (কবে জয়েন করেছে)

  TeamMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.isPending = false,    // ডিফল্ট false
    this.jobsCompleted = 0,    // ডিফল্ট 0
    this.jobsInProgress = 0,   // ডিফল্ট 0
    this.totalEarnings = 0.0,  // ডিফল্ট 0.0
    this.rating = 0.0,         // ডিফল্ট 0.0
    this.joinedAt,
  });

  // 🔹 Firestore এ ডাটা পাঠানোর জন্য (Map এ কনভার্ট করা)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'role': role,
      'isPending': isPending,
      'jobsCompleted': jobsCompleted,
      'jobsInProgress': jobsInProgress,
      'totalEarnings': totalEarnings,
      'rating': rating,
      'joinedAt': joinedAt?.toIso8601String(),
    };
  }

  // 🔹 Firestore থেকে ডাটা আনার জন্য (Object এ কনভার্ট করা)
  factory TeamMember.fromMap(String id, Map<String, dynamic> map) {
    return TeamMember(
      id: id,
      name: map['name'] ?? 'Unknown',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'staff',
      isPending: map['isPending'] ?? false,
      jobsCompleted: (map['jobsCompleted'] ?? 0).toInt(),
      jobsInProgress: (map['jobsInProgress'] ?? 0).toInt(),
      // নিচে double কনভার্শন নিশ্চিত করা হয়েছে যাতে অ্যাপ ক্র্যাশ না করে
      totalEarnings: (map['totalEarnings'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0).toDouble(),
      joinedAt: map['joinedAt'] != null ? DateTime.tryParse(map['joinedAt']) : null,
    );
  }
}