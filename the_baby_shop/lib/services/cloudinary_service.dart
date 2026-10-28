import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class CloudinaryService {
  static const String cloudName = 'dec646hua';
  static const String uploadPreset = 'The Baby Shop';

  
  /// Helper method called 'uploadToCloudinary' that uploads an image file or bytes
  /// to Cloudinary's REST API using a multipart HTTP POST request.
  /// 
  /// Accepts [imageFile] (mobile) or [webImageBytes] (web/bytes).
  static Future<String> uploadToCloudinary({
    File? imageFile,
    Uint8List? webImageBytes,
  }) async {
    if (imageFile == null && webImageBytes == null) {
      throw Exception('No image file or bytes provided for Cloudinary upload.');
    }
    
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Attach the upload_preset field accurately
      request.fields['upload_preset'] = uploadPreset;
      
      // Attach the file field based on the platform and input types
      if (kIsWeb && webImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            webImageBytes,
            filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      } else if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
          ),
        );
      } else {
        throw Exception('Invalid image data for current platform.');
      }
      
      // Send the multipart HTTP request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String? secureUrl = data['secure_url'];
        if (secureUrl != null) {
          return secureUrl;
        } else {
          throw Exception('Upload succeeded, but Cloudinary did not return a secure_url.');
        }
      } else {
        throw Exception('Cloudinary REST API error [${response.statusCode}]: ${response.body}');
      }
    } catch (e) {
      print('CloudinaryService upload failure: $e');
      rethrow;
    }
  }
}
