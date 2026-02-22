import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:findus_app/models/team_invitation.dart';
import 'package:findus_app/models/team_member.dart';

class TeamService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ════════════════════════════════════════════════════════════════════════════
  // 📨 SEND INVITATION
  // ════════════════════════════════════════════════════════════════════════════

  /// Send team invitation to a user by phone number
  static Future<Map<String, dynamic>> sendInvitation({
    required String toPhone,
    required String role,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {'success': false, 'error': 'Not logged in'};
    }

    try {
      // 1. Get current user (owner) data
      final ownerDoc = await _db.collection('users').doc(currentUser.uid).get();
      final ownerData = ownerDoc.data() ?? {};
      final ownerName = ownerData['name'] ?? ownerData['fullName'] ?? 'Team Owner';
      final ownerImage = ownerData['image'] ?? ownerData['imageUrl'] ?? '';
      final ownerPhone = ownerData['phone'] ?? '';

      // 2. Find invited user by phone
      final userQuery = await _db
          .collection('users')
          .where('phone', isEqualTo: toPhone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return {'success': false, 'error': 'No user found with this phone number'};
      }

      final invitedUserDoc = userQuery.docs.first;
      final invitedUserId = invitedUserDoc.id;
      final invitedUserData = invitedUserDoc.data();
      final invitedUserName = invitedUserData['name'] ?? invitedUserData['fullName'] ?? 'User';

      // 3. Check if already in team
      final existingMember = await _db
          .collection('users')
          .doc(currentUser.uid)
          .collection('team_members')
          .where('userId', isEqualTo: invitedUserId)
          .get();

      if (existingMember.docs.isNotEmpty) {
        return {'success': false, 'error': 'This user is already in your team'};
      }

      // 4. Check if invitation already sent
      final existingInvitation = await _db
          .collection('team_invitations')
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('toUserId', isEqualTo: invitedUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingInvitation.docs.isNotEmpty) {
        return {'success': false, 'error': 'Invitation already sent to this user'};
      }

      // 5. Create invitation
      final invitationData = {
        'fromUserId': currentUser.uid,
        'fromUserName': ownerName,
        'fromUserImage': ownerImage,
        'fromUserPhone': ownerPhone,
        'toUserId': invitedUserId,
        'toUserPhone': toPhone,
        'toUserName': invitedUserName,
        'role': role,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
      };

      await _db.collection('team_invitations').add(invitationData);

      // 6. Send notification to invited user
      await _db.collection('notifications').add({
        'toUserId': invitedUserId,
        'fromUserId': currentUser.uid,
        'type': 'team_invitation',
        'title': 'Team Invitation',
        'body': '$ownerName invited you to join their team as ${role.toUpperCase()}',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Invitation sent to $invitedUserName'};
    } catch (e) {
      debugPrint('❌ Send invitation error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ ACCEPT INVITATION
  // ════════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> acceptInvitation(String invitationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {'success': false, 'error': 'Not logged in'};
    }

    try {
      final invitationRef = _db.collection('team_invitations').doc(invitationId);
      final invitationDoc = await invitationRef.get();

      if (!invitationDoc.exists) {
        return {'success': false, 'error': 'Invitation not found'};
      }

      final invitation = TeamInvitation.fromMap(invitationId, invitationDoc.data()!);

      // Verify this invitation is for current user
      if (invitation.toUserId != currentUser.uid) {
        return {'success': false, 'error': 'This invitation is not for you'};
      }

      if (invitation.status != InvitationStatus.pending) {
        return {'success': false, 'error': 'Invitation already responded'};
      }

      // Get current user data
      final myDoc = await _db.collection('users').doc(currentUser.uid).get();
      final myData = myDoc.data() ?? {};

      // Transaction to ensure consistency
      await _db.runTransaction((transaction) async {
        // 1. Update invitation status
        transaction.update(invitationRef, {
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        });

        // 2. Add to team_members collection
        final memberRef = _db
            .collection('users')
            .doc(invitation.fromUserId)
            .collection('team_members')
            .doc();

        transaction.set(memberRef, {
          'userId': currentUser.uid,
          'name': myData['name'] ?? myData['fullName'] ?? invitation.toUserName,
          'phone': invitation.toUserPhone,
          'image': myData['image'] ?? myData['imageUrl'] ?? '',
          'role': invitation.role,
          'isPending': false,
          'joinedAt': FieldValue.serverTimestamp(),
          'jobsCompleted': 0,
          'jobsInProgress': 0,
          'totalEarnings': 0.0,
          'rating': 0.0,
        });

        // 3. Add reference in member's profile (optional - for member to know which teams they're in)
        final myTeamsRef = _db
            .collection('users')
            .doc(currentUser.uid)
            .collection('my_teams')
            .doc(invitation.fromUserId);

        transaction.set(myTeamsRef, {
          'ownerId': invitation.fromUserId,
          'ownerName': invitation.fromUserName,
          'ownerImage': invitation.fromUserImage,
          'role': invitation.role,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      });

      // 4. Notify owner
      await _db.collection('notifications').add({
        'toUserId': invitation.fromUserId,
        'fromUserId': currentUser.uid,
        'type': 'invitation_accepted',
        'title': 'Invitation Accepted! 🎉',
        'body': '${myData['name'] ?? 'User'} accepted your team invitation',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'You joined ${invitation.fromUserName}\'s team!'};
    } catch (e) {
      debugPrint('❌ Accept invitation error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ❌ REJECT INVITATION
  // ════════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> rejectInvitation(String invitationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {'success': false, 'error': 'Not logged in'};
    }

    try {
      final invitationRef = _db.collection('team_invitations').doc(invitationId);
      final invitationDoc = await invitationRef.get();

      if (!invitationDoc.exists) {
        return {'success': false, 'error': 'Invitation not found'};
      }

      final data = invitationDoc.data()!;

      // Verify this invitation is for current user
      if (data['toUserId'] != currentUser.uid) {
        return {'success': false, 'error': 'This invitation is not for you'};
      }

      await invitationRef.update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Invitation declined'};
    } catch (e) {
      debugPrint('❌ Reject invitation error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📋 GET PENDING INVITATIONS (For invited user)
  // ════════════════════════════════════════════════════════════════════════════

  static Stream<List<TeamInvitation>> getMyPendingInvitations() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _db
        .collection('team_invitations')
        .where('toUserId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TeamInvitation.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📋 GET SENT INVITATIONS (For owner)
  // ════════════════════════════════════════════════════════════════════════════

  static Stream<List<TeamInvitation>> getMySentInvitations() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _db
        .collection('team_invitations')
        .where('fromUserId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TeamInvitation.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🗑️ CANCEL INVITATION (For owner)
  // ════════════════════════════════════════════════════════════════════════════

  static Future<bool> cancelInvitation(String invitationId) async {
    try {
      await _db.collection('team_invitations').doc(invitationId).delete();
      return true;
    } catch (e) {
      debugPrint('❌ Cancel invitation error: $e');
      return false;
    }
  }
}