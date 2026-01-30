import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  /// 🔹 আপনার Cloudinary তথ্য
  static const String cloudName = 'dlwkqyh1a';

  /// ⚠️ নিশ্চিত করুন আপনার Cloudinary Dashboard > Settings > Upload > Upload presets
  /// এখানে একটি 'Unsigned' প্রিসেট তৈরি করা আছে এবং সেটির নাম নিচে দিন।
  static const String uploadPreset = 'findus_unsigned';

  static Uri _uploadUri(String resourceType) {
    return Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
    );
  }

  static void _ensureConfigured() {
    // 🛑 ফিক্স: আগের কোডে নিজের নাম থাকলেই এরর দিচ্ছিল, সেটা বাদ দেওয়া হয়েছে।
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception('Cloudinary cloudName অথবা uploadPreset সেট করা নেই!');
    }
  }

  static String _basename(String path) {
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
    return uploadFile(
      file,
      folder: folder,
      resourceType: resourceType,
      publicId: publicId,
      tags: tags,
    );
  }

  /// ✅ ফাইল আপলোড হ্যান্ডলার (File, XFile, বা Path অবজেক্ট)
  static Future<Map<String, dynamic>> uploadFile(
      Object file, {
        String folder = '',
        String resourceType = 'image',
        String publicId = '',
        List<String> tags = const [],
        String? fileName,
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
      try {
        final Uint8List bytes = await (file as dynamic).readAsBytes() as Uint8List;

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