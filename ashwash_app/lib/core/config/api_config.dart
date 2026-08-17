enum Environment { development, staging, production, tunnel }

class ApiConfig {
  // Active environment set to development for physical device testing
  static Environment currentEnvironment = Environment.production;

  // Custom environment override for Cloudflare Tunnel, Ngrok, or custom IP/domain
  static String? _customBaseUrl;

  // Environment Base URLs (127.0.0.1 for ADB Reverse, 192.168.43.197 for Wi-Fi)
  static const String _localAdbUrl = 'http://127.0.0.1:8000/api';
  static const String _emulatorUrl = 'http://10.0.2.2:8000/api';
  static const String _stagingUrl = 'https://ashwash-staging.up.railway.app/api';
  static const String _prodUrl = 'https://ashwash-backend.onrender.com/api';

  /// Returns active Base API URL
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    switch (currentEnvironment) {
      case Environment.development:
        return _localAdbUrl;
      case Environment.staging:
        return _stagingUrl;
      case Environment.production:
        return _prodUrl;
      case Environment.tunnel:
        return _emulatorUrl;
    }
  }

  /// Override Base API URL dynamically without modifying code
  static void setCustomBaseUrl(String url) {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.endsWith('/api')) {
      cleanUrl = '$cleanUrl/api';
    }
    _customBaseUrl = cleanUrl;
  }

  /// Helper to convert relative media/image paths from backend to full HTTPS URLs
  static String getMediaUrl(String relativePath) {
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    final domain = baseUrl.replaceAll('/api', '');
    final cleanPath = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$domain$cleanPath';
  }
}