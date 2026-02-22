// lib/models/team_member.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMember {
  final String id;
  final String userId;      // ✅ Added - User's UID
  final String name;
  final String phone;
  final String image;       // ✅ Added
  final String role;
  final bool isPending;
  final DateTime joinedAt;
  final int jobsCompleted;
  final int jobsInProgress;
  final double totalEarnings;
  final double rating;

  TeamMember({
    required this.id,
    this.userId = '',
    required this.name,
    required this.phone,
    this.image = '',
    required this.role,
    required this.isPending,
    required this.joinedAt,
    this.jobsCompleted = 0,
    this.jobsInProgress = 0,
    this.totalEarnings = 0.0,
    this.rating = 0.0,
  });

  factory TeamMember.fromMap(String id, Map<String, dynamic> map) {
    return TeamMember(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      image: map['image'] ?? '',
      role: map['role'] ?? 'staff',
      isPending: map['isPending'] ?? false,
      joinedAt: map['joinedAt'] != null
          ? (map['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
      jobsCompleted: map['jobsCompleted'] ?? 0,
      jobsInProgress: map['jobsInProgress'] ?? 0,
      totalEarnings: (map['totalEarnings'] ?? 0.0).toDouble(),
      rating: (map['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'image': image,
      'role': role,
      'isPending': isPending,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'jobsCompleted': jobsCompleted,
      'jobsInProgress': jobsInProgress,
      'totalEarnings': totalEarnings,
      'rating': rating,
    };
  }
}