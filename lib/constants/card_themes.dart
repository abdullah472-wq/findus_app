import 'package:flutter/material.dart';

class CardThemes {
  // টাইপ 'CardTheme' সরিয়ে দেওয়া হয়েছে, শুধু 'static const' রাখা হয়েছে
  static const darkCardTheme = CardTheme(
    color: Color(0xFF2C2C2C),
    elevation: 2,
    shadowColor: Colors.black45,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  static const lightCardTheme = CardTheme(
    color: Colors.white,
    elevation: 1,
    surfaceTintColor: Colors.white, // Material 3 সাপোর্টের জন্য
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );
}