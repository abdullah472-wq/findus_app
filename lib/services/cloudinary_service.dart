import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  /// নিজের Cloudinary তথ্য বসান
  static const String cloudName = 'dlwkqyh1a';
  static const String uploadPreset = 'ml_default';

  static Uri _uploadUri(String resourceType) {
    return Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
    );
  }

  static void _ensureConfigured() {
    if (cloudName == 'dlwkqyh1a' || uploadPreset == 'ml_default') {
      throw Exception('Cloudinary cloudName/uploadPreset সেট করা নেই');
    }
  }

  static String _basename(String path) {
    // Windows + Unix path দুটোই হ্যান্ডেল
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    final last = parts.isNotEmpty ? parts.last : '';
    return last.isNotEmpty ? last : 'upload.bin';
  }

  /// ✅ Web-safe bytes upload
  static Future<Map<String, dynamic>> uploadBytes(
      Uint8List bytes, {
        required String fileName,
        String folder = '',
        String resourceType = 'image',
        String publicId = '',
        List<String> tags = const [],
      }) async {
    _ensureConfigured();

    final req = http.MultipartRequest('POST', _uploadUri(resourceType))
      ..fields['upload_preset'] = uploadPreset;

    if (folder.isNotEmpty) req.fields['folder'] = folder;
    if (publicId.isNotEmpty) req.fields['public_id'] = publicId;
    if (tags.isNotEmpty) req.fields['tags'] = tags.join(',');

    req.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final resp = await req.send();
    final body = await resp.stream.bytesToString();

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Cloudinary upload failed (${resp.statusCode}): $body');
    }

    return (jsonDecode(body) as Map<String, dynamic>);
  }

  /// ✅ XFile আপলোড (web+mobile)
  static Future<Map<String, dynamic>> uploadXFile(
      XFile file, {
        String folder = '',
        String resourceType = 'image',
        String publicId = '',
        List<String> tags = const [],
      }) async {
    // XFile দিলে uploadFile() দিয়েই করে দিচ্ছি
    return uploadFile(
      file,
      folder: folder,
      resourceType: resourceType,
      publicId: publicId,
      tags: tags,
    );
  }

  /// ✅ পুরোনো কলগুলো ঠিক রাখার জন্য uploadFile() আবার যোগ করা হলো
  ///
  /// আপনি এখানে `File`, `XFile`, বা এমন অবজেক্ট পাঠাতে পারবেন যার
  /// - `path` আছে (মোবাইল), অথবা
  /// - `readAsBytes()` আছে (ওয়েব/মোবাইল)
  ///
  /// ফলে `dart:io` ইমপোর্ট লাগবে না, কিন্তু মোবাইলে `File` দিয়েও কাজ করবে।
  static Future<Map<String, dynamic>> uploadFile(
      Object file, {
        String folder = '',
        String resourceType = 'image',
        String publicId = '',
        List<String> tags = const [],
        String? fileName, // bytes path না পেলে কাজে লাগবে
      }) async {
    _ensureConfigured();

    // ---------- যদি XFile হয় ----------
    if (file is XFile) {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        return uploadBytes(
          bytes,
          fileName: file.name,
          folder: folder,
          resourceType: resourceType,
          publicId: publicId,
          tags: tags,
        );
      }

      // Mobile: path দিয়ে multipart
      final req = http.MultipartRequest('POST', _uploadUri(resourceType))
        ..fields['upload_preset'] = uploadPreset;

      if (folder.isNotEmpty) req.fields['folder'] = folder;
      if (publicId.isNotEmpty) req.fields['public_id'] = publicId;
      if (tags.isNotEmpty) req.fields['tags'] = tags.join(',');

      req.files.add(
        await http.MultipartFile.fromPath('file', file.path, filename: file.name),
      );

      final resp = await req.send();
      final body = await resp.stream.bytesToString();

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Cloudinary upload failed (${resp.statusCode}): $body');
      }
      return (jsonDecode(body) as Map<String, dynamic>);
    }

    // ---------- ওয়েবে path-based upload চলবে না ----------
    if (kIsWeb) {
      // যদি ফাইলের readAsBytes() থাকে, সেটাই ব্যবহার করব
      try {
        final Uint8List bytes = await (file as dynamic).readAsBytes() as Uint8List;

        // fileName বের করার চেষ্টা
        String inferredName = fileName ?? 'upload.bin';
        try {
          final n = (file as dynamic).name;
          if (n != null && n.toString().trim().isNotEmpty) inferredName = n.toString();
        } catch (_) {}

        return uploadBytes(
          bytes,
          fileName: inferredName,
          folder: folder,
          resourceType: resourceType,
          publicId: publicId,
          tags: tags,
        );
      } catch (_) {
        throw Exception('ওয়েবে uploadFile() এর জন্য XFile/bytes দরকার');
      }
    }

    // ---------- Mobile: File বা path-ওয়ালা অবজেক্ট ----------
    // এখানে আমরা dart:io File টাইপ ব্যবহার করছি না; dynamic দিয়ে path/readAsBytes নেয়া হবে
    String? path;
    try {
      path = (file as dynamic).path?.toString();
    } catch (_) {
      path = null;
    }

    if (path == null || path.isEmpty) {
      // path না থাকলে bytes দিয়ে ট্রাই
      final Uint8List bytes = await (file as dynamic).readAsBytes() as Uint8List;

      final inferredName = fileName ?? 'upload.bin';
      return uploadBytes(
        bytes,
        fileName: inferredName,
        folder: folder,
        resourceType: resourceType,
        publicId: publicId,
        tags: tags,
      );
    }

    final inferredName = fileName ?? _basename(path);

    final req = http.MultipartRequest('POST', _uploadUri(resourceType))
      ..fields['upload_preset'] = uploadPreset;

    if (folder.isNotEmpty) req.fields['folder'] = folder;
    if (publicId.isNotEmpty) req.fields['public_id'] = publicId;
    if (tags.isNotEmpty) req.fields['tags'] = tags.join(',');

    req.files.add(
      await http.MultipartFile.fromPath('file', path, filename: inferredName),
    );

    final resp = await req.send();
    final body = await resp.stream.bytesToString();

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Cloudinary upload failed (${resp.statusCode}): $body');
    }

    return (jsonDecode(body) as Map<String, dynamic>);
  }
}