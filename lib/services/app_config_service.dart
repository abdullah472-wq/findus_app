// lib/services/app_config_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfigService {
  static bool isAppInMaintenance = false;
  static bool isSignupDisabled = false;
  static bool isPostingDisabled = false;
  static String minAppVersion = '1.0.0';
  static String maintenanceNote = '';

  static Future<void> init() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('appConfig')
          .doc('global')
          .get();

      if (!doc.exists) return;
      final data = doc.data() ?? {};

      isAppInMaintenance = data['isAppInMaintenance'] == true;
      isSignupDisabled = data['isSignupDisabled'] == true;
      isPostingDisabled = data['isPostingDisabled'] == true;
      minAppVersion = (data['minAppVersion'] ?? '1.0.0') as String;
      maintenanceNote = (data['maintenanceNote'] ?? '') as String;
    } catch (_) {
      // error holeo app চলবে, শুধু config apply হবে না
    }
  }
}