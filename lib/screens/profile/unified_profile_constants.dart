import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class AppProfileConstants {
  static const double avatarRadius = 65.0;
  static const double pillIconSize = 12.0;
  static const EdgeInsets cardPadding = EdgeInsets.all(24);
  static const EdgeInsets sectionPadding = EdgeInsets.all(20);
  static const double statIconSize = 20.0;
  static const double engagementFontSize = 18.0;
}

enum ProfileMenuOwner {
  edit,
  shareProfile,
  previewPublicCard,
  lockAccount,
  theme,
  hideProfile,
  pauseWork,
}

enum ProfileMenuOther {
  report,
  block,
}

// Section Types
enum SuggestionType {
  userPosts,
  sponsored,
  nearbyWorkers,
  nearbySupporters,
  topRated,
  recentlyActive,
  newUsers,
  similarProfiles,
  recommended,
}

extension SuggestionTypeExtension on SuggestionType {
  String get title {
    switch (this) {
      case SuggestionType.userPosts:
        return "User Posts";
      case SuggestionType.sponsored:
        return "✨ Sponsored";
      case SuggestionType.nearbyWorkers:
        return "Nearby Workers";
      case SuggestionType.nearbySupporters:
        return "Nearby Supporters";
      case SuggestionType.topRated:
        return "⭐ Top Rated";
      case SuggestionType.recentlyActive:
        return "Recently Active";
      case SuggestionType.newUsers:
        return "🆕 New on FindUs";
      case SuggestionType.similarProfiles:
        return "Similar Profiles";
      case SuggestionType.recommended:
        return "💡 Recommended for You";
    }
  }

  IconData get icon {
    switch (this) {
      case SuggestionType.userPosts:
        return Icons.article;
      case SuggestionType.sponsored:
        return Icons.star;
      case SuggestionType.nearbyWorkers:
        return Icons.location_on;
      case SuggestionType.nearbySupporters:
        return Icons.business;
      case SuggestionType.topRated:
        return Icons.emoji_events;
      case SuggestionType.recentlyActive:
        return Icons.access_time;
      case SuggestionType.newUsers:
        return Icons.fiber_new;
      case SuggestionType.similarProfiles:
        return Icons.people;
      case SuggestionType.recommended:
        return Icons.recommend;
    }
  }

  Color get color {
    switch (this) {
      case SuggestionType.userPosts:
        return Colors.blue;
      case SuggestionType.sponsored:
        return Colors.amber;
      case SuggestionType.nearbyWorkers:
        return Colors.green;
      case SuggestionType.nearbySupporters:
        return Colors.purple;
      case SuggestionType.topRated:
        return Colors.orange;
      case SuggestionType.recentlyActive:
        return Colors.teal;
      case SuggestionType.newUsers:
        return Colors.pink;
      case SuggestionType.similarProfiles:
        return Colors.indigo;
      case SuggestionType.recommended:
        return AppColors.brandMain;
    }
  }
}