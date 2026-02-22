// lib/screens/settings/block_list_screen.dart

import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/blocked_user_service.dart';
import 'package:findus_app/services/theme_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class BlockListScreen extends StatefulWidget {
  const BlockListScreen({super.key});

  @override
  State<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends State<BlockListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final BlockedUserService _blockedService = BlockedUserService();

  // Selection mode for batch unblock
  bool _isSelectionMode = false;
  final Set<String> _selectedUsers = {};

  @override
  void initState() {
    super.initState();
    // Initialize service
    _blockedService.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, settings, _) {
        // ✅ Theme Colors
        final isDark = settings.isDarkMode;
        final colors = _BlockListColors(
          isDark: isDark,
          useAmoled: settings.useAmoledBlack,
        );

        return FloatingScaffold(
          title: _isSelectionMode
              ? "${_selectedUsers.length} SELECTED"
              : "BLOCKED USERS",
          backgroundColor: colors.bgColor,
          titleColor: colors.titleColor,
          iconColor: colors.iconColor,
          showBack: true,
          scrollable: false,
          bodyPadding: EdgeInsets.zero,
          actions: _buildActions(colors),
          body: Column(
            children: [
              // Search Bar
              _buildSearchBar(colors),

              // User List
              Expanded(
                child: StreamBuilder<List<Map<String, String>>>(
                  stream: _blockedService.streamBlockedUsers(),
                  builder: (context, snapshot) {
                    // Loading State
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState(colors);
                    }

                    // Error State
                    if (snapshot.hasError) {
                      return _buildErrorState(colors, snapshot.error.toString());
                    }

                    // Get Users
                    final allUsers = snapshot.data ?? [];

                    // Filter by search query
                    final users = _searchQuery.isEmpty
                        ? allUsers
                        : allUsers.where((user) {
                      return user['name']!
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                    }).toList();

                    // Empty State
                    if (users.isEmpty) {
                      return _buildEmptyState(
                        colors,
                        isSearching: _searchQuery.isNotEmpty,
                      );
                    }

                    // User List
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        return _buildBlockedUserTile(users[i], colors);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchBar(_BlockListColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(color: colors.textColor),
        decoration: InputDecoration(
          hintText: 'Search blocked users...',
          hintStyle: TextStyle(color: colors.subTextColor),
          prefixIcon: Icon(Icons.search, color: colors.subTextColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: colors.subTextColor),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
          )
              : null,
          filled: true,
          fillColor: colors.isDark ? Colors.white10 : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  List<Widget> _buildActions(_BlockListColors colors) {
    if (!_isSelectionMode) {
      return [
        IconButton(
          icon: const Icon(Icons.checklist_rounded),
          tooltip: 'Select Multiple',
          onPressed: () {
            setState(() {
              _isSelectionMode = true;
            });
          },
        ),
      ];
    }

    return [
      TextButton(
        onPressed: _toggleSelectAll,
        child: Text(
          _selectedUsers.isEmpty ? 'Select All' : 'Deselect All',
          style: TextStyle(color: colors.titleColor),
        ),
      ),
      if (_selectedUsers.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.delete_sweep, color: Colors.red),
          tooltip: 'Unblock Selected',
          onPressed: _unblockSelected,
        ),
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            _isSelectionMode = false;
            _selectedUsers.clear();
          });
        },
      ),
    ];
  }

  void _toggleSelectAll() async {
    final users = await _blockedService.getBlockedUsers();
    setState(() {
      if (_selectedUsers.isEmpty) {
        _selectedUsers.addAll(users.map((u) => u['id']!));
      } else {
        _selectedUsers.clear();
      }
    });
  }

  Future<void> _unblockSelected() async {
    final count = _selectedUsers.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.red),
            SizedBox(width: 12),
            Text("Unblock Users?"),
          ],
        ),
        content: Text("Unblock $count selected user${count > 1 ? 's' : ''}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Unblock"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _blockedService.unblockMultiple(_selectedUsers.toList());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text("$count user${count > 1 ? 's' : ''} unblocked"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        setState(() {
          _isSelectionMode = false;
          _selectedUsers.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to unblock: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI STATES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingState(_BlockListColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.brandMain),
          const SizedBox(height: 16),
          Text(
            'Loading blocked users...',
            style: TextStyle(color: colors.subTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(_BlockListColors colors, {bool isSearching = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.block_outlined,
              size: 80,
              color: colors.subTextColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? "No results found" : "No blocked users",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? "Try a different search term"
                  : "Users you block will appear here",
              style: TextStyle(fontSize: 14, color: colors.subTextColor),
              textAlign: TextAlign.center,
            ),
            if (isSearching) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text("Clear Search"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(_BlockListColors colors, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              "Failed to load blocked users",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 12, color: colors.subTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _blockedService.syncWithFirestore();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER TILE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBlockedUserTile(Map<String, String> user, _BlockListColors colors) {
    final userId = user['id']!;
    final isSelected = _selectedUsers.contains(userId);
    final hasImage = user['image'] != null && user['image']!.isNotEmpty;

    return Dismissible(
      key: Key(userId),
      direction: _isSelectionMode
          ? DismissDirection.none
          : DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmUnblock(user),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'UNBLOCK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: _isSelectionMode ? () => _toggleSelection(userId) : null,
        onLongPress: !_isSelectionMode
            ? () {
          setState(() {
            _isSelectionMode = true;
            _selectedUsers.add(userId);
          });
        }
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandMain.withOpacity(colors.isDark ? 0.2 : 0.1)
                : colors.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: AppColors.brandMain, width: 2)
                : Border.all(
              color: colors.isDark
                  ? Colors.grey.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(colors.isDark ? 0.1 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Selection Checkbox
              if (_isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(userId),
                  activeColor: AppColors.brandMain,
                ),
                const SizedBox(width: 8),
              ],

              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: hasImage ? NetworkImage(user['image']!) : null,
                child: !hasImage
                    ? Icon(Icons.person, color: Colors.grey.shade600)
                    : null,
              ),
              const SizedBox(width: 12),

              // Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'Unknown User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.block,
                          size: 12,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Blocked",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Unblock Button (only in normal mode)
              if (!_isSelectionMode)
                ElevatedButton(
                  onPressed: () =>
                      _unblockUser(userId, user['name'] ?? 'User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "UNBLOCK",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUsers.contains(userId)) {
        _selectedUsers.remove(userId);
      } else {
        _selectedUsers.add(userId);
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UNBLOCK ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> _confirmUnblock(Map<String, String> user) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text("Unblock User?"),
          ],
        ),
        content: Text("${user['name']} will be able to contact you again."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Unblock"),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _unblockUser(String userId, String userName) async {
    final confirmed = await _confirmUnblock({
      'id': userId,
      'name': userName,
      'image': '',
    });

    if (!confirmed) return;

    try {
      await _blockedService.unblockUser(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text("$userName unblocked"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to unblock: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class _BlockListColors {
  final bool isDark;
  final bool useAmoled;

  _BlockListColors({required this.isDark, this.useAmoled = false});

  Color get bgColor {
    if (isDark && useAmoled) return Colors.black;
    if (isDark) return const Color(0xFF1A1A1A);
    return AppColors.bgBlue;
  }

  Color get cardColor {
    if (isDark && useAmoled) return const Color(0xFF121212);
    if (isDark) return const Color(0xFF2C2C2C);
    return Colors.white;
  }

  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  Color get titleColor => isDark ? Colors.white : AppColors.brandDark;
  Color get iconColor => isDark ? Colors.white : AppColors.brandDark;
}