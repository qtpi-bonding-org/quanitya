import 'package:injectable/injectable.dart';

@lazySingleton
class AppConfig {
  static const String _defaultServerpodUrl = 'http://localhost:8080/';
  
  final String serverpodUrl;
  
  AppConfig() : serverpodUrl = const String.fromEnvironment('SERVERPOD_URL', defaultValue: _defaultServerpodUrl);
  
  /// Extract base URL from serverpod URL for health checks
  /// e.g., https://staging.quanitya.com/api/ -> https://staging.quanitya.com
  String get baseUrl {
    final uri = Uri.parse(serverpodUrl);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }
}