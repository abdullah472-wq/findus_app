import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus { pending, accepted, rejected }

class TeamInvitation {
  final String id;
  final String fromUserId;      // Owner who sent invitation
  final String fromUserName;
  final String fromUserImage;
  final String fromUserPhone;
  final String toUserId;        // Invited user
  final String toUserPhone;
  final String toUserName;
  final String role;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  TeamInvitation({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserImage = '',
    this.fromUserPhone = '',
    required this.toUserId,
    required this.toUserPhone,
    this.toUserName = '',
    required this.role,
    this.status = InvitationStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  factory TeamInvitation.fromMap(String id, Map<String, dynamic> map) {
    return TeamInvitation(
      id: id,
      fromUserId: map['fromUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? 'Unknown',
      fromUserImage: map['fromUserImage'] ?? '',
      fromUserPhone: map['fromUserPhone'] ?? '',
      toUserId: map['toUserId'] ?? '',
      toUserPhone: map['toUserPhone'] ?? '',
      toUserName: map['toUserName'] ?? '',
      role: map['role'] ?? 'staff',
      status: _parseStatus(map['status']),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: map['respondedAt'] != null
          ? (map['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  static InvitationStatus _parseStatus(String? status) {
    switch (status) {
      case 'accepted':
        return InvitationStatus.accepted;
      case 'rejected':
        return InvitationStatus.rejected;
      default:
        return InvitationStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserImage': fromUserImage,
      'fromUserPhone': fromUserPhone,
      'toUserId': toUserId,
      'toUserPhone': toUserPhone,
      'toUserName': toUserName,
      'role': role,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  bool get isPending => status == InvitationStatus.pending;
  bool get isAccepted => status == InvitationStatus.accepted;
  bool get isRejected => status == InvitationStatus.rejected;
}