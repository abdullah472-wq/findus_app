// lib/services/cloudinary_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'dlwkqyh1a';
  static const String uploadPreset = 'findus_unsigned';

  static Uri _uploadUri(String resourceType) {
    return Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
    );
  }

  static void _ensureConfigured() {
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception('Cloudinary cloudName or uploadPreset not configured!');
    }
  }

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    final last = parts.isNotEmpty ? parts.last : '';
    return last.isNotEmpty ? last : 'upload.bin';
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ UPLOAD WITH PROGRESS
  // ════════════════════════════════════════════════════════════════════════════

  /// Upload bytes with progress tracking
  static Future<Map<String, dynamic>> uploadBytes(
      Uint8List bytes, {
        required String fileName,
        String folder = '',
        String resourceType = 'image',
        String publicId = '',
        List<String> tags = const [],
        Function(int sent, int total)? onProgress,
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

    // ✅ Track upload progress (if callback provided)
    if (onProgress != null) {
      int bytesSent = 0;
      final total = req.contentLength;

      resp.stream.listen(
            (chunk) {
          bytesSent += chunk.length;
          onProgress(bytesSent, total);
        },
      );
    }

    final body = await resp.stream.bytesToString();

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Cloudinary upload failed (${resp.statusCode}): $body');
    }

    return (jsonDecode(body) as Map<String, dynamic>);
  }

  /// Upload XFile with progress
  static Future<Map<String, dynamic>> uploadXFile(
      XFile file, {
        String folder = '',
        String resourceType = 'image',
        String publicId = '',
        List<String> tags = const [],
        Function(int sent, int total)? onProgress,
      }) async {
    return uploadFile(
      file,
      folder: folder,
      resourceType: resourceType,
      publicId: publicId,
      tags: tags,
      onProgress: onProgress,
    );
  }

  /// Generic file upload with progress
  static Future<Map<String, dynamic>> uploadFile(
      Object file, {
        String folder = '',
        String resourceType = 'image',
        String publicId = '',
        List<String> tags = const [],
        String? fileName,
        Function(int sent, int total)? onProgress,
      }) async {
    _ensureConfigured();

    // Handle XFile
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
          onProgress: onProgress,
        );
      }

      // Mobile: path-based upload
      final req = http.MultipartRequest('POST', _uploadUri(resourceType))
        ..fields['upload_preset'] = uploadPreset;

      if (folder.isNotEmpty) req.fields['folder'] = folder;
      if (publicId.isNotEmpty) req.fields['public_id'] = publicId;
      if (tags.isNotEmpty) req.fields['tags'] = tags.join(',');

      req.files.add(
        await http.MultipartFile.fromPath('file', file.path, filename: file.name),
      );

      final resp = await req.send();

      // Track progress
      if (onProgress != null) {
        int bytesSent = 0;
        final total = req.contentLength;

        resp.stream.listen((chunk) {
          bytesSent += chunk.length;
          onProgress(bytesSent, total);
        });
      }

      final body = await resp.stream.bytesToString();

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Cloudinary upload failed (${resp.statusCode}): $body');
      }

      return (jsonDecode(body) as Map<String, dynamic>);
    }

    // Handle web bytes
    if (kIsWeb) {
      try {
        final Uint8List bytes = await (file as dynamic).readAsBytes() as Uint8List;
        String inferredName = fileName ?? 'upload.bin';

        try {
          final n = (file as dynamic).name;
          if (n != null && n.toString().trim().isNotEmpty) {
            inferredName = n.toString();
          }
        } catch (_) {}

        return uploadBytes(
          bytes,
          fileName: inferredName,
          folder: folder,
          resourceType: resourceType,
          publicId: publicId,
          tags: tags,
          onProgress: onProgress,
        );
      } catch (_) {
        throw Exception('Web upload requires XFile or bytes');
      }
    }

    // Mobile: File or path object
    String? path;
    try {
      path = (file as dynamic).path?.toString();
    } catch (_) {
      path = null;
    }

    if (path == null || path.isEmpty) {
      final Uint8List bytes = await (file as dynamic).readAsBytes() as Uint8List;
      final inferredName = fileName ?? 'upload.bin';

      return uploadBytes(
        bytes,
        fileName: inferredName,
        folder: folder,
        resourceType: resourceType,
        publicId: publicId,
        tags: tags,
        onProgress: onProgress,
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

    // Track progress
    if (onProgress != null) {
      int bytesSent = 0;
      final total = req.contentLength;

      resp.stream.listen((chunk) {
        bytesSent += chunk.length;
        onProgress(bytesSent, total);
      });
    }

    final body = await resp.stream.bytesToString();

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Cloudinary upload failed (${resp.statusCode}): $body');
    }

    return (jsonDecode(body) as Map<String, dynamic>);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ HELPER METHODS
  // ════════════════════════════════════════════════════════════════════════════

  /// Generate optimized URL
  static String getOptimizedUrl(
      String publicId, {
        int? width,
        int? height,
        String quality = 'auto',
        String format = 'auto',
      }) {
    String transformation = 'q_$quality,f_$format';
    if (width != null) transformation += ',w_$width';
    if (height != null) transformation += ',h_$height';

    return 'https://res.cloudinary.com/$cloudName/image/upload/$transformation/$publicId';
  }

  /// Generate thumbnail URL
  static String getThumbnailUrl(String publicId, {int size = 200}) {
    return 'https://res.cloudinary.com/$cloudName/image/upload/w_$size,h_$size,c_fill,q_auto,f_auto/$publicId';
  }

  /// Delete resource
  static Future<void> deleteResource(
      String publicId, {
        String resourceType = 'image',
      }) async {
    // Note: Deletion requires authenticated API (not unsigned)
    // You'll need to implement server-side deletion with API secret
    throw UnimplementedError(
      'Deletion requires server-side implementation with API secret',
    );
  }

  /// Upload multiple files
  static Future<List<Map<String, dynamic>>> uploadMultiple(
      List<XFile> files, {
        String folder = '',
        String resourceType = 'image',
        Function(int current, int total)? onProgress,
      }) async {
    final results = <Map<String, dynamic>>[];

    for (int i = 0; i < files.length; i++) {
      try {
        final result = await uploadXFile(
          files[i],
          folder: folder,
          resourceType: resourceType,
        );
        results.add(result);

        if (onProgress != null) {
          onProgress(i + 1, files.length);
        }
      } catch (e) {
        debugPrint('❌ Error uploading file ${i + 1}: $e');
        rethrow;
      }
    }

    return results;
  }
}