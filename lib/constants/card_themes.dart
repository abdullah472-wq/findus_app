import 'package:flutter/material.dart';

class AppCardThemes {
  static const CardThemeData darkCardTheme = CardThemeData(
    color: Color(0xFF2C2C2C),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
  );

  static const CardThemeData lightCardTheme = CardThemeData(
    color: Colors.white,
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
  );
}