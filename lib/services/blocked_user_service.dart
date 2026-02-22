// lib/services/blocked_user_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockedUserService {
  // ════════════════════════════════════════════════════════════════════════════
  // SINGLETON PATTERN
  // ════════════════════════════════════════════════════════════════════════════

  static final BlockedUserService _instance = BlockedUserService._internal();
  factory BlockedUserService() => _instance;
  BlockedUserService._internal();

  // ════════════════════════════════════════════════════════════════════════════
  // DEPENDENCIES
  // ════════════════════════════════════════════════════════════════════════════

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ════════════════════════════════════════════════════════════════════════════
  // STATE
  // ════════════════════════════════════════════════════════════════════════════

  /// In-memory cache for faster access
  static final Set<String> _blockedUserIds = {};

  /// Initialization flag
  static bool _isInitialized = false;

  /// Stream controller for real-time updates
  final StreamController<List<Map<String, String>>> _blockedUsersController =
  StreamController<List<Map<String, String>>>.broadcast();

  /// Current user ID (cached)
  String? _cachedUserId;

  /// Stream subscription (cleanup on logout)
  StreamSubscription<QuerySnapshot>? _blockedUsersSubscription;

  // ════════════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ════════════════════════════════════════════════════════════════════════════

  static const String _localStorageKey = 'blocked_user_ids';
  static const int _syncTimeoutSeconds = 10;

  // ════════════════════════════════════════════════════════════════════════════
  // 🚀 INITIALIZATION
  // ════════════════════════════════════════════════════════════════════════════

  /// Initialize and sync blocked users
  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('ℹ️ BlockedUserService already initialized');
      return;
    }

    // Listen to auth state changes
    _auth.authStateChanges().listen(_handleAuthStateChange);

    await syncWithFirestore();
  }

  /// Handle auth state changes (logout cleanup)
  void _handleAuthStateChange(User? user) {
    if (user == null) {
      // User logged out - cleanup
      _cleanup();
      debugPrint('🔄 BlockedUserService cleaned up on logout');
    } else if (_cachedUserId != user.uid) {
      // Different user logged in - re-sync
      _cachedUserId = user.uid;
      syncWithFirestore();
      debugPrint('🔄 BlockedUserService re-syncing for new user');
    }
  }

  /// Sync blocked users from Firestore to local cache
  Future<void> syncWithFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('⚠️ Cannot sync: User not logged in');
      await _loadFromLocal(); // Load cached data
      return;
    }

    _cachedUserId = uid;

    try {
      // ✅ 1. Load from Firestore with timeout
      final userDoc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(Duration(seconds: _syncTimeoutSeconds));

      if (!userDoc.exists) {
        debugPrint('⚠️ User document does not exist');
        _blockedUserIds.clear();
        await _saveToLocal();
        _isInitialized = true;
        return;
      }

      final data = userDoc.data() ?? {};
      final List<dynamic> blockedList = data['blockedUsers'] ?? [];

      // ✅ 2. Update in-memory cache
      _blockedUserIds.clear();
      _blockedUserIds.addAll(blockedList.map((e) => e.toString()));

      // ✅ 3. Save to local storage for offline access
      await _saveToLocal();

      _isInitialized = true;
      debugPrint('✅ BlockedUserService synced: ${_blockedUserIds.length} users');

      // ✅ 4. Start real-time listener
      _startRealtimeListener();
    } on TimeoutException {
      debugPrint('⏱️ Sync timeout - using local cache');
      await _loadFromLocal();
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Error syncing blocked users: $e');
      // Fallback to local cache
      await _loadFromLocal();
      _isInitialized = true;
    }
  }

  /// Start real-time listener for blocked users
  void _startRealtimeListener() {
    final uid = _cachedUserId;
    if (uid == null) return;

    // Cancel existing subscription
    _blockedUsersSubscription?.cancel();

    // Listen to blocked_users subcollection
    _blockedUsersSubscription = _db
        .collection('users')
        .doc(uid)
        .collection('blocked_users')
        .orderBy('blockedAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
        // Update cache
        _blockedUserIds.clear();
        _blockedUserIds.addAll(snapshot.docs.map((doc) => doc.id));
        _saveToLocal();

        // Emit to stream
        final users = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': (data['name'] ?? 'Unknown User').toString(),
            'image': (data['image'] ?? '').toString(),
          };
        }).toList();

        _blockedUsersController.add(users);

        debugPrint('🔄 Real-time update: ${users.length} blocked users');
      },
      onError: (error) {
        debugPrint('❌ Real-time listener error: $error');
        _blockedUsersController.addError(error);
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🚫 BLOCK USER
  // ════════════════════════════════════════════════════════════════════════════

  /// Block a user
  Future<bool> blockUser(
      String targetUserId, {
        String? targetName,
        String? targetImage,
      }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('❌ Cannot block: User not logged in');
      return false;
    }

    if (uid == targetUserId) {
      debugPrint('❌ Cannot block yourself');
      return false;
    }

    if (_blockedUserIds.contains(targetUserId)) {
      debugPrint('⚠️ User already blocked: $targetUserId');
      return true; // Already blocked
    }

    try {
      // ✅ Use batch for atomic operation
      WriteBatch batch = _db.batch();

      // 1. Update blockedUsers array
      final userRef = _db.collection('users').doc(uid);
      batch.update(userRef, {
        'blockedUsers': FieldValue.arrayUnion([targetUserId]),
      });

      // 2. Save blocked user details
      final blockedRef = userRef.collection('blocked_users').doc(targetUserId);
      batch.set(blockedRef, {
        'userId': targetUserId,
        'name': targetName ?? 'Unknown User',
        'image': targetImage ?? '',
        'blockedAt': FieldValue.serverTimestamp(),
      });

      // Commit batch
      await batch.commit();

      // ✅ Update local cache
      _blockedUserIds.add(targetUserId);
      await _saveToLocal();

      debugPrint('✅ User blocked: $targetUserId');
      return true;
    } catch (e) {
      debugPrint('❌ Error blocking user: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ UNBLOCK USER
  // ════════════════════════════════════════════════════════════════════════════

  /// Unblock a user (with transaction for race condition prevention)
  Future<bool> unblockUser(String targetUserId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('❌ Cannot unblock: User not logged in');
      return false;
    }

    if (!_blockedUserIds.contains(targetUserId)) {
      debugPrint('⚠️ User not in blocked list: $targetUserId');
      return true; // Already not blocked
    }

    try {
      // ✅ Use batch for atomic operation
      WriteBatch batch = _db.batch();

      // 1. Update blockedUsers array
      final userRef = _db.collection('users').doc(uid);
      batch.update(userRef, {
        'blockedUsers': FieldValue.arrayRemove([targetUserId]),
      });

      // 2. Delete from blocked_users subcollection
      final blockedRef = userRef.collection('blocked_users').doc(targetUserId);
      batch.delete(blockedRef);

      // Commit batch
      await batch.commit();

      // ✅ Update local cache
      _blockedUserIds.remove(targetUserId);
      await _saveToLocal();

      debugPrint('✅ User unblocked: $targetUserId');
      return true;
    } catch (e) {
      debugPrint('❌ Error unblocking user: $e');
      return false;
    }
  }

  /// Unblock multiple users at once (batch operation)
  Future<bool> unblockMultiple(List<String> userIds) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || userIds.isEmpty) {
      debugPrint('❌ Cannot unblock multiple: Invalid params');
      return false;
    }

    try {
      // ✅ Firestore batch has 500 operation limit
      const batchLimit = 500;
      final chunks = _chunkList(userIds, batchLimit ~/ 2); // 2 ops per user

      for (var chunk in chunks) {
        WriteBatch batch = _db.batch();

        // 1. Update main blockedUsers array
        final userRef = _db.collection('users').doc(uid);
        batch.update(userRef, {
          'blockedUsers': FieldValue.arrayRemove(chunk),
        });

        // 2. Delete from blocked_users subcollection
        for (String userId in chunk) {
          final blockedRef = userRef.collection('blocked_users').doc(userId);
          batch.delete(blockedRef);
        }

        await batch.commit();
      }

      // ✅ Update local cache
      _blockedUserIds.removeAll(userIds);
      await _saveToLocal();

      debugPrint('✅ ${userIds.length} users unblocked');
      return true;
    } catch (e) {
      debugPrint('❌ Error unblocking multiple users: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔍 CHECK & GET BLOCKED USERS
  // ════════════════════════════════════════════════════════════════════════════

  /// Check if a user is blocked (fast - uses cache)
  bool isBlocked(String userId) {
    return _blockedUserIds.contains(userId);
  }

  /// Check if a user is blocked (async - checks Firestore)
  Future<bool> isUserBlocked(String userId) async {
    // First check cache
    if (_blockedUserIds.contains(userId)) return true;

    // Then check Firestore
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(Duration(seconds: 5));

      if (!doc.exists) return false;

      final blockedList = List<String>.from(doc.data()?['blockedUsers'] ?? []);

      // Update cache if found
      if (blockedList.contains(userId)) {
        _blockedUserIds.add(userId);
        await _saveToLocal();
        return true;
      }

      return false;
    } on TimeoutException {
      debugPrint('⏱️ Timeout checking blocked status - using cache');
      return _blockedUserIds.contains(userId);
    } catch (e) {
      debugPrint('❌ Error checking blocked status: $e');
      return _blockedUserIds.contains(userId); // Fallback to cache
    }
  }

  /// Get all blocked user IDs
  Set<String> getBlockedUserIds() {
    return Set.from(_blockedUserIds);
  }

  /// Get blocked user count
  int getBlockedCount() {
    return _blockedUserIds.length;
  }

  /// Get blocked users with details (for Block List Screen)
  Future<List<Map<String, String>>> getBlockedUsers() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('⚠️ Cannot get blocked users: Not logged in');
      return [];
    }

    try {
      // ✅ Get from blocked_users subcollection (has name, image)
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('blocked_users')
          .orderBy('blockedAt', descending: true)
          .get()
          .timeout(Duration(seconds: _syncTimeoutSeconds));

      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': (data['name'] ?? 'Unknown User').toString(),
          'image': (data['image'] ?? '').toString(),
        };
      }).toList();

      debugPrint('✅ Retrieved ${users.length} blocked users');
      return users;
    } on TimeoutException {
      debugPrint('⏱️ Timeout getting blocked users - using fallback');
      return await _getBlockedUsersFromArray();
    } catch (e) {
      debugPrint('❌ Error getting blocked users: $e');
      // Fallback: Get just IDs and fetch user details
      return await _getBlockedUsersFromArray();
    }
  }

  /// Fallback method to get blocked users from array
  Future<List<Map<String, String>>> _getBlockedUsersFromArray() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      final userDoc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(Duration(seconds: 5));

      if (!userDoc.exists) return [];

      final blockedList = List<String>.from(userDoc.data()?['blockedUsers'] ?? []);

      if (blockedList.isEmpty) return [];

      final List<Map<String, String>> users = [];

      // Fetch in chunks (Firestore limit: 10 per whereIn)
      final chunks = _chunkList(blockedList, 10);

      for (var chunk in chunks) {
        try {
          final snapshot = await _db
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get()
              .timeout(Duration(seconds: 5));

          for (var doc in snapshot.docs) {
            final data = doc.data();
            users.add({
              'id': doc.id,
              'name': (data['name'] ?? data['fullName'] ?? 'User').toString(),
              'image': (data['image'] ?? data['imageUrl'] ?? '').toString(),
            });
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching chunk: $e');
          // Add unknown users for this chunk
          for (var id in chunk) {
            users.add({
              'id': id,
              'name': 'Unknown User',
              'image': '',
            });
          }
        }
      }

      return users;
    } on TimeoutException {
      debugPrint('⏱️ Timeout in fallback method');
      return [];
    } catch (e) {
      debugPrint('❌ Error in fallback method: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 💾 LOCAL STORAGE
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_localStorageKey, _blockedUserIds.toList());
      debugPrint('💾 Saved ${_blockedUserIds.length} blocked users to local storage');
    } catch (e) {
      debugPrint('❌ Error saving to local: $e');
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_localStorageKey) ?? [];
      _blockedUserIds.clear();
      _blockedUserIds.addAll(list);
      debugPrint('📂 Loaded ${_blockedUserIds.length} blocked users from local storage');
    } catch (e) {
      debugPrint('❌ Error loading from local: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔄 STREAM
  // ════════════════════════════════════════════════════════════════════════════

  /// Stream blocked users (real-time updates)
  Stream<List<Map<String, String>>> streamBlockedUsers() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('⚠️ Cannot stream: User not logged in');
      return Stream.value([]);
    }

    // Start listener if not already started
    if (_blockedUsersSubscription == null) {
      _startRealtimeListener();
    }

    return _blockedUsersController.stream;
  }

  /// Stream blocked user count
  Stream<int> streamBlockedCount() {
    return streamBlockedUsers().map((users) => users.length);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🧹 CLEANUP
  // ════════════════════════════════════════════════════════════════════════════

  /// Cleanup resources on logout
  void _cleanup() {
    _blockedUsersSubscription?.cancel();
    _blockedUsersSubscription = null;
    _blockedUserIds.clear();
    _cachedUserId = null;
    _isInitialized = false;
    debugPrint('🧹 BlockedUserService cleaned up');
  }

  /// Dispose resources
  void dispose() {
    _cleanup();
    _blockedUsersController.close();
    debugPrint('🗑️ BlockedUserService disposed');
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🛠️ HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  /// Split list into chunks
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📊 DEBUG INFO
  // ════════════════════════════════════════════════════════════════════════════

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'cachedUserId': _cachedUserId,
      'blockedCount': _blockedUserIds.length,
      'blockedUserIds': _blockedUserIds.toList(),
      'hasActiveListener': _blockedUsersSubscription != null,
    };
  }

  /// Print debug info
  void printDebugInfo() {
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('BlockedUserService Debug Info:');
    final info = getDebugInfo();
    info.forEach((key, value) {
      debugPrint('  $key: $value');
    });
    debugPrint('═══════════════════════════════════════════════════');
  }
}