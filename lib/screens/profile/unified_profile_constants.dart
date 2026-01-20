import 'package:flutter/material.dart';

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