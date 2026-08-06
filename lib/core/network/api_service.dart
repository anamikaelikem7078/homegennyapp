import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../network/dio_client.dart';

/// Shared HTTP helpers for all remote datasources.
abstract class BaseRemoteDataSource {
  BaseRemoteDataSource(this._dio);

  final DioClient _dio;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    return _extractData(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return _extractData(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      path,
      data: data,
    );
    return _extractData(response);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final response = await _dio.delete<Map<String, dynamic>>(path);
    return _extractData(response);
  }

  Future<Map<String, dynamic>> uploadMultipart(
    String path, {
    required FormData formData,
    void Function(int sent, int total)? onProgress,
  }) async {
    final response = await _dio.uploadMultipart<Map<String, dynamic>>(
      path,
      formData: formData,
      onSendProgress: onProgress,
    );
    return _extractData(response);
  }

  Map<String, dynamic> _extractData(Response<Map<String, dynamic>> response) {
    final status = response.statusCode ?? 0;
    final body = response.data;
    if (status < 200 || status >= 300 || body == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Request failed with status $status',
      );
    }
    if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    if (body.containsKey('data') && body['data'] is List) {
      return {'items': body['data']};
    }
    return body;
  }
}

/// Multipart upload service for images, videos, and documents.
class MultipartUploadService extends BaseRemoteDataSource {
  MultipartUploadService(super.dio);

  Future<Map<String, dynamic>> uploadImage({
    required String path,
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? fields,
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      ...?fields,
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return uploadMultipart(
      path.isEmpty ? ApiConstants.uploadImage : path,
      formData: formData,
      onProgress: onProgress,
    );
  }

  Future<Map<String, dynamic>> uploadVideo({
    required String path,
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? fields,
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      ...?fields,
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return uploadMultipart(
      path.isEmpty ? ApiConstants.uploadVideo : path,
      formData: formData,
      onProgress: onProgress,
    );
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String path,
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? fields,
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      ...?fields,
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return uploadMultipart(
      path.isEmpty ? ApiConstants.uploadDocument : path,
      formData: formData,
      onProgress: onProgress,
    );
  }
}
