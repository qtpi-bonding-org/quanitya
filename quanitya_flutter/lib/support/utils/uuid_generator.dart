import 'package:uuid/uuid.dart';
import 'package:injectable/injectable.dart';

/// Service for UUID generation with format consistency guarantees.
/// 
/// Provides UUID v4 generation with proper validation and normalization
/// to ensure consistency across the application.
@injectable
class UuidGenerator {
  static const Uuid _uuid = Uuid();
  
  /// Regular expression pattern for validating UUID format.
  /// 
  /// Matches the standard UUID format with proper version and variant bits:
  /// - 8 hex digits, hyphen
  /// - 4 hex digits, hyphen  
  /// - 4 hex digits starting with '4' (version), hyphen
  /// - 4 hex digits starting with [89AB] (variant), hyphen
  /// - 12 hex digits
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
  );
  
  String generate() {
    return _uuid.v4();
  }
  
  bool isValid(String uuid) {
    return _uuidPattern.hasMatch(uuid);
  }
  
  String normalize(String uuid) {
    // Remove any whitespace
    final trimmed = uuid.trim();
    
    // Check if it's a valid UUID format
    if (!isValid(trimmed)) {
      throw FormatException('Invalid UUID format: $uuid');
    }
    
    // Convert to lowercase for consistency
    return trimmed.toLowerCase();
  }
  
  /// Generates a UUID and immediately normalizes it.
  /// 
  /// This is a convenience method that combines generation and normalization
  /// in a single call, ensuring the returned UUID is always in the standard format.
  String generateNormalized() {
    return normalize(generate());
  }
  
  /// Validates and normalizes a UUID in a single operation.
  /// 
  /// Returns the normalized UUID if valid, or null if invalid.
  /// This is useful for scenarios where you want to handle invalid UUIDs
  /// gracefully without throwing exceptions.
  /// 
  /// [uuid] The UUID string to validate and normalize
  String? tryNormalize(String uuid) {
    try {
      return normalize(uuid);
    } catch (e) {
      return null;
    }
  }
}

