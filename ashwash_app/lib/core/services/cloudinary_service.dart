import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryUploadResult {
  final bool success;
  final String secureUrl;
  final String publicId;
  final String error;

  CloudinaryUploadResult({
    required this.success,
    this.secureUrl = '',
    this.publicId = '',
    this.error = '',
  });
}

class CloudinaryService {
  static const String cloudName = 'a6cztdgv';
  static const String uploadPreset = 'ashwash_upload';
  static const String uploadUrl = 'https://api.cloudinary.com/v1_1/a6cztdgv/auto/upload';

  /// Direct Unsigned Upload to Cloudinary with real-time percentage callback
  static Future<CloudinaryUploadResult> uploadFile({
    required String filePath,
    required Function(double progress) onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return CloudinaryUploadResult(success: false, error: 'Local file not found at path');
      }

      onProgress(0.1); // 10% started

      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['upload_preset'] = uploadPreset;

      final multipartFile = await http.MultipartFile.fromPath('file', filePath);
      request.files.add(multipartFile);

      onProgress(0.4); // 40% sending file

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      onProgress(1.0); // 100% complete

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final secureUrl = data['secure_url']?.toString() ?? '';
        final publicId = data['public_id']?.toString() ?? '';
        return CloudinaryUploadResult(
          success: true,
          secureUrl: secureUrl,
          publicId: publicId,
        );
      } else {
        return CloudinaryUploadResult(
          success: false,
          error: 'Cloudinary upload error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      return CloudinaryUploadResult(success: false, error: e.toString());
    }
  }
}
