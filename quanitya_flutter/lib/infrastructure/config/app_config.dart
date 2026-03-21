import 'package:injectable/injectable.dart';

@lazySingleton
class AppConfig {
  static const String _defaultServerpodUrl = 'http://localhost:8080/';
  static const String _defaultTemplateCatalogUrl =
      'https://raw.githubusercontent.com/qtpi-bonding-org/quanitya-templates/main';

  final String serverpodUrl;
  final String templateCatalogUrl;

  AppConfig()
      : serverpodUrl = const String.fromEnvironment('SERVERPOD_URL',
            defaultValue: _defaultServerpodUrl),
        templateCatalogUrl = const String.fromEnvironment(
            'TEMPLATE_CATALOG_URL',
            defaultValue: _defaultTemplateCatalogUrl);

  /// Extract base URL from serverpod URL for health checks
  /// e.g., https://staging.quanitya.com/api/ -> https://staging.quanitya.com
  String get baseUrl {
    final uri = Uri.parse(serverpodUrl);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }
}