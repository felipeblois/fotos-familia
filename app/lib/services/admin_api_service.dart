import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/config/app_config.dart';

class AdminApiService {
  AdminApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: '${AppConfig.backendBaseUrl}/api/v1/admin',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  final Dio _dio;

  Future<Options> _authorizedOptions() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return Options(
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  Future<Map<String, dynamic>> _authorizedGet(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      options: await _authorizedOptions(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _authorizedDelete(String path) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      path,
      options: await _authorizedOptions(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> fetchAlbums() async {
    final data = await _authorizedGet('/albums');
    return List<Map<String, dynamic>>.from(
      (data['data']?['albums'] as List?) ?? const [],
    );
  }

  Future<List<Map<String, dynamic>>> fetchAlbumPhotos(String albumId) async {
    final data = await _authorizedGet('/albums/$albumId/photos');
    return List<Map<String, dynamic>>.from(
      (data['data']?['photos'] as List?) ?? const [],
    );
  }

  Future<void> deletePhoto(String albumId, String photoId) async {
    await _authorizedDelete('/albums/$albumId/photos/$photoId');
  }

  Future<List<Map<String, dynamic>>> fetchAuditLogs() async {
    final data = await _authorizedGet('/audit-logs');
    return List<Map<String, dynamic>>.from(
      (data['data']?['logs'] as List?) ?? const [],
    );
  }
}
