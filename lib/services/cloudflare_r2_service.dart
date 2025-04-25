import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType

class CloudflareR2Service {
  // Replace these with your actual Cloudflare R2 credentials
  static const String _accessKey = '25a481dd0b90e825e2013aedf8e344db';
  static const String _secretKey = '3172e77ad80112415fac9d95c21e8b33ee4d74f0091ab0daaf8b5f29a4c8b551';
  
  // Replace with your actual bucket name
  static const String _bucketName = 'dk-manager-storage';
  
  // Create a public URL that can be used with a Cloudflare worker or R2 public access
  static String getPublicUrl(String key) {
    const String workerUrl = 'https://steep-violet-b8d4.arbazdeveloper.workers.dev';
    return '$workerUrl/$key';
  }
  
  // Generate a unique file name to avoid collisions
  String _generateFileName(String originalFileName) {
    final uuid = const Uuid().v4();
    final extension = path.extension(originalFileName);
    return '$uuid$extension';
  }

  // Upload a file to R2 and return the key using the worker
  Future<String> uploadFile(File file, String folder) async {
    try {
      // Generate unique filename
      final fileName = _generateFileName(file.path.split('/').last);
      final key = '$folder/$fileName';
      
      if (kDebugMode) {
        print('Uploading file to worker: $key');
      }
      
      // Create a multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://steep-violet-b8d4.arbazdeveloper.workers.dev/upload'),
      );
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
          contentType: MediaType.parse(_getContentType(file.path)),
        ),
      );
      
      // Add metadata
      request.fields['key'] = key;
      request.fields['accessKey'] = _accessKey;
      request.fields['secretKey'] = _secretKey;
      request.fields['bucket'] = _bucketName;
      
      // Send the request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (kDebugMode) {
        print('Upload response: ${response.statusCode}');
        print('Response body: $responseBody');
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Return the key of the uploaded file
        return key;
      } else {
        throw Exception('Failed to upload file: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading file: $e');
      }
      throw Exception('Failed to upload file: $e');
    }
  }
  
  // Delete a file from R2 using the worker
  Future<bool> deleteFile(String key) async {
    try {
      final response = await http.post(
        Uri.parse('https://steep-violet-b8d4.arbazdeveloper.workers.dev/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': key,
          'accessKey': _accessKey,
          'secretKey': _secretKey,
          'bucket': _bucketName,
        }),
      );
      
      if (kDebugMode) {
        print('Delete response: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting file: $e');
      }
      throw Exception('Failed to delete file: $e');
    }
  }
  
  // Get content type from file extension
  String _getContentType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
  
  // No resources to clean up
  void dispose() {}
} 