import 'dart:math';

import 'package:findus_app/services/post_service.dart';

class DemoPostSeed {
  static bool _seededInSession = false;

  /// প্রতিবার অ্যাপ রান করলে একবারই 25 worker + 25 supporter demo পোস্ট যোগ করবে
  /// (Firestore এ আগের demo / real পোস্ট থাকলেও সেগুলোর সাথে mix হবে)
  static Future<void> seedOncePerSession() async {
    if (_seededInSession) return;
    _seededInSession = true;

    final rnd = Random();

    final regions = [
      {'city': 'Dhaka',       'lat': 23.8103, 'lng': 90.4125},
      {'city': 'Chattogram',  'lat': 22.3569, 'lng': 91.7832},
      {'city': 'Sylhet',      'lat': 24.8949, 'lng': 91.8687},
      {'city': 'Rajshahi',    'lat': 24.3636, 'lng': 88.6241},
      {'city': 'Khulna',      'lat': 22.8456, 'lng': 89.5403},
    ];

    final workerRoles = [
      'DRIVER',
      'CLEANER',
      'ELECTRICIAN',
      'PLUMBER',
      'GARDENER',
      'COOK',
      'DELIVERY',
      'PAINTER',
    ];

    final supportTitles = [
      'House Cleaning Job',
      'Furniture Moving Job',
      'AC Repair Work',
      'Painting Job',
      'Office Cleaning',
      'Gardening Work',
      'Food Delivery Help',
      'Electric Repair Job',
    ];

    // ---------- ২৫ worker পোস্ট ----------
    for (int i = 0; i < 25; i++) {
      final reg = regions[i % regions.length];
      final baseLat = reg['lat'] as double;
      final baseLng = reg['lng'] as double;
      final city = reg['city'] as String;

      final latOffset = (rnd.nextDouble() - 0.5) * 0.08;
      final lngOffset = (rnd.nextDouble() - 0.5) * 0.08;

      final roleLabel = workerRoles[i % workerRoles.length];
      final title = '$roleLabel in $city #${i + 1}';

      // 🔹 প্রায় ২০% worker পোস্টকে promoted ধরছি
      final isPromoted = rnd.nextInt(5) == 0;

      await PostService.createPost(
        ownerId: 'demo_worker_${i + 1}',
        ownerRole: 'worker',
        title: title,
        roleLabel: roleLabel,
        lat: baseLat + latOffset,
        lng: baseLng + lngOffset,
        address: '$city, Bangladesh',
        priceLabel: '৳${300 + rnd.nextInt(700)} / day',
        isLive: rnd.nextBool(),
        verified: rnd.nextBool(),
        phone: '+88017${10000000 + rnd.nextInt(8999999)}',
        gender: rnd.nextBool() ? 'Male' : 'Female',
        experience: rnd.nextInt(10),
        rating: 3.5 + rnd.nextDouble() * 1.5,
        language: 'Bangla',
        trusted: rnd.nextBool(),

        // 🔹 নতুন ফিল্ড
        isPromoted: isPromoted,
      );
    }

    // ---------- ২৫ supporter পোস্ট ----------
    for (int i = 0; i < 25; i++) {
      final reg = regions[i % regions.length];
      final baseLat = reg['lat'] as double;
      final baseLng = reg['lng'] as double;
      final city = reg['city'] as String;

      final latOffset = (rnd.nextDouble() - 0.5) * 0.08;
      final lngOffset = (rnd.nextDouble() - 0.5) * 0.08;

      final baseTitle = supportTitles[i % supportTitles.length];
      final title = '$baseTitle in $city #${i + 1}';
      final needRole = workerRoles[i % workerRoles.length];

      // 🔹 প্রায় ২০% supporter পোস্টকেও promoted ধরছি
      final isPromoted = rnd.nextInt(5) == 0;

      await PostService.createPost(
        ownerId: 'demo_supporter_${i + 1}',
        ownerRole: 'supporter',
        title: title,
        roleLabel: needRole,
        lat: baseLat + latOffset,
        lng: baseLng + lngOffset,
        address: '$city, Bangladesh',
        priceLabel: '৳${400 + rnd.nextInt(900)} / job',
        isLive: rnd.nextBool(),
        verified: rnd.nextBool(),
        phone: '+88018${10000000 + rnd.nextInt(8999999)}',
        gender: 'Any',
        experience: 0,
        rating: 4.0 + rnd.nextDouble(),
        language: 'Bangla',
        trusted: rnd.nextBool(),

        // 🔹 নতুন ফিল্ড
        isPromoted: isPromoted,
      );
    }
  }
}