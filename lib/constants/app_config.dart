// lib/constants/app_config.dart

import 'package:flutter/foundation.dart';

/// Debug / Mock flags for development
///
/// kUseMockAuthFlow == true হলে:
///  - Phone verification + OTP ধাপগুলো Firebase ছাড়া mock হিসেবে কাজ করবে
///  - তুমি UI + navigation flow টেস্ট করতে পারবে
/// Production-এর আগে এটাকে false করবে
const bool kUseMockAuthFlow = kDebugMode;
// চাইলে ডাইরেক্ট true/false ও দিতে পারো:
// const bool kUseMockAuthFlow = true;