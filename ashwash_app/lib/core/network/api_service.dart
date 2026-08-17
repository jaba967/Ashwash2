import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static const String tokenKey = 'jwt_access_token';
  static const String refreshKey = 'jwt_refresh_token';

  static String _activeHost = 'https://ashwash-backend.onrender.com/api';
  static final List<String> _candidateHosts = [
    'https://ashwash-backend.onrender.com/api',
    'http://10.0.2.2:8000/api',
    'http://127.0.0.1:8000/api',
  ];

  static Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requireAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static String _buildUrl(String rawUrl, String host) {
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    String path = rawUrl;
    if (rawUrl.contains('/api/')) {
      path = rawUrl.substring(rawUrl.indexOf('/api/') + 5);
    }
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    return '$host/$path';
  }

  static Future<dynamic> _executeWithFallback(
    String originalUrl,
    Future<http.Response> Function(String url, Map<String, String> headers) requestFn, {
    bool requireAuth = true,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);

    final primaryUrl = _buildUrl(originalUrl, _activeHost);
    http.Response? response;
    try {
      // 75s timeout for Render free tier cold starts (can take up to ~55s)
      response = await requestFn(primaryUrl, headers).timeout(const Duration(seconds: 75));
    } catch (e) {
      final isTimeout = e.toString().toLowerCase().contains('timeout');
      for (final host in _candidateHosts) {
        if (host == _activeHost) continue;
        try {
          final fallbackUrl = _buildUrl(originalUrl, host);
          response = await requestFn(fallbackUrl, headers).timeout(const Duration(seconds: 6));
          _activeHost = host;
          ApiConfig.setCustomBaseUrl(host);
          break;
        } catch (_) {}
      }
      if (response == null && isTimeout) {
        throw Exception('connection_timeout');
      }
    }

    if (response == null) {
      throw Exception('সার্ভারের সাথে সংযোগ পাওয়া যাচ্ছে না। রেন্ডার ক্লাউড ব্যাকএন্ড চালু হচ্ছে, দয়া করে কয়েক সেকেন্ড পর আবার চেষ্টা করুন।');
    }

    return _processResponse(response);
  }

  static Future<dynamic> get(String url, {bool requireAuth = true}) async {
    return _executeWithFallback(
      url,
      (targetUrl, headers) => http.get(Uri.parse(targetUrl), headers: headers),
      requireAuth: requireAuth,
    );
  }

  static Future<List<dynamic>> getList(String url, {bool requireAuth = true}) async {
    final res = await get(url, requireAuth: requireAuth);
    if (res is List) return res;
    if (res is Map && res.containsKey('results') && res['results'] is List) {
      return res['results'] as List<dynamic>;
    }
    return [];
  }

  static Future<dynamic> post(String url, Map<String, dynamic> body, {bool requireAuth = true}) async {
    return _executeWithFallback(
      url,
      (targetUrl, headers) => http.post(Uri.parse(targetUrl), headers: headers, body: jsonEncode(body)),
      requireAuth: requireAuth,
    );
  }

  static Future<dynamic> patch(String url, Map<String, dynamic> body, {bool requireAuth = true}) async {
    return _executeWithFallback(
      url,
      (targetUrl, headers) => http.patch(Uri.parse(targetUrl), headers: headers, body: jsonEncode(body)),
      requireAuth: requireAuth,
    );
  }

  static Future<dynamic> put(String url, Map<String, dynamic> body, {bool requireAuth = true}) async {
    return _executeWithFallback(
      url,
      (targetUrl, headers) => http.put(Uri.parse(targetUrl), headers: headers, body: jsonEncode(body)),
      requireAuth: requireAuth,
    );
  }

  static Future<dynamic> delete(String url, {bool requireAuth = true}) async {
    return _executeWithFallback(
      url,
      (targetUrl, headers) => http.delete(Uri.parse(targetUrl), headers: headers),
      requireAuth: requireAuth,
    );
  }

  static dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }
      throw Exception('Server Error (${response.statusCode})');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      if (body is Map) {
        if (body.containsKey('detail')) {
          final d = body['detail'];
          if (d is List && d.isNotEmpty) throw Exception(d.first.toString());
          throw Exception(d.toString());
        }
        if (body.containsKey('error')) throw Exception(body['error'].toString());
        if (body.containsKey('message')) throw Exception(body['message'].toString());
        if (body.containsKey('non_field_errors')) {
          final errs = body['non_field_errors'];
          if (errs is List && errs.isNotEmpty) throw Exception(errs.first.toString());
        }
        for (var key in body.keys) {
          final val = body[key];
          if (val is List && val.isNotEmpty) {
            throw Exception('$key: ${val.first}');
          }
        }
      }
      throw Exception('API error occurred (${response.statusCode})');
    }
  }
}
