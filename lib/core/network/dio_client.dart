import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../exceptions/app_exceptions.dart';


/// Singleton Dio client demonstrating Singleton pattern and Network handling
class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  
  late final Dio _dio;

  DioClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.mock-backend.com/v1', // Dummy base URL
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // Add interceptors to simulate backend or log requests
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // We can add auth tokens here if needed
        debugPrint('REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },

      onResponse: (response, handler) {
        debugPrint('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        return handler.next(response);
      },

      onError: (DioException e, handler) {
        debugPrint('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
        return handler.next(e);
      },

    ));
  }

  Dio get dio => _dio;

  /// Helper wrapper to handle Dio exceptions gracefully
  Future<Response> post(String path, {dynamic data}) async {
    try {
      // In a real app this would be: return await _dio.post(path, data: data);
      // We simulate a network call since we have no backend.
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulating a success response
      if (path == '/login') {
        if (data['email'] != null && data['password'] == 'password123') {
           return Response(
             requestOptions: RequestOptions(path: path),
             statusCode: 200,
             data: {
               'id': '12345',
               'email': data['email'],
               'name': data['email'].split('@')[0],
               'token': 'dummy_dio_jwt_token',
             }
           );
        } else {
           throw DioException(
             requestOptions: RequestOptions(path: path),
             response: Response(requestOptions: RequestOptions(path: path), statusCode: 401),
             type: DioExceptionType.badResponse,
           );
        }
      }
      
      throw NetworkException('Endpoint not found');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Invalid email or password');
      }
      throw NetworkException(e.message ?? 'Unknown network error');
    } catch (e) {
      throw AppException(e.toString());
    }
  }
}
