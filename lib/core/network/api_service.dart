import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../network/dio_client.dart';
import '../utils/json_normalizer.dart';

/// Shared HTTP helpers for all remote datasources.
abstract class BaseRemoteDataSource {
  BaseRemoteDataSource(this._dio);

  final DioClient _dio;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<dynamic>(
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
    final response = await _dio.post<dynamic>(
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
    final response = await _dio.put<dynamic>(
      path,
      data: data,
    );
    return _extractData(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.patch<dynamic>(
      path,
      data: data,
    );
    return _extractData(response);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final response = await _dio.delete<dynamic>(path);
    return _extractData(response);
  }

  Future<Map<String, dynamic>> uploadMultipart(
    String path, {
    required FormData formData,
    void Function(int sent, int total)? onProgress,
  }) async {
    final response = await _dio.uploadMultipart<dynamic>(
      path,
      formData: formData,
      onSendProgress: onProgress,
    );
    return _extractData(response);
  }

  // Requesting `Map<String, dynamic>` as Dio's response generic makes Dio
  // cast the decoded JSON body to that exact type internally — but on
  // Flutter Web, the JSON decoder (via the XHR path) produces untyped
  // maps at every level of the tree, including nested objects, and that
  // internal cast throws a TypeError instead of the intended DioException.
  // Requesting `dynamic` and recursively normalizing via `asStringKeyedMap`
  // (see `json_normalizer.dart`) fixes this for nested fields too, not
  // just the top-level body.
  Map<String, dynamic> _extractData(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final rawBody = response.data;
    if (status < 200 || status >= 300 || rawBody == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Request failed with status $status',
      );
    }
    final body = asStringKeyedMap(rawBody);
    if (body.containsKey('data') && body['data'] is Map) {
      return asStringKeyedMap(body['data']);
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
