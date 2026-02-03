import 'package:injectable/injectable.dart';

/// Simple validator for shareable template security.
///
/// Only validates external security threats - Freezed handles structure validation.
@injectable
class ShareableTemplateValidator {
  
  /// Validate URL format and security.
  void validateUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw ArgumentError('Invalid URL format');
    }

    // Only allow HTTPS for security
    if (uri.scheme != 'https') {
      throw ArgumentError('Only HTTPS URLs are allowed for security');
    }
  }

  /// Check for basic security issues in strings.
  bool containsMaliciousContent(String text) {
    // Basic XSS prevention
    final maliciousPatterns = [
      '<script',
      'javascript:',
      'data:text/html',
      'vbscript:',
    ];

    final lowerText = text.toLowerCase();
    return maliciousPatterns.any((pattern) => lowerText.contains(pattern));
  }

  /// Validate hex color format.
  bool isValidHexColor(String color) {
    final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
    return hexPattern.hasMatch(color);
  }
}