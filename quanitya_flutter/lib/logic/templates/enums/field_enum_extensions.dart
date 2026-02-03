import 'field_enum.dart';

/// Extension to provide user-friendly display names for field types
extension FieldEnumDisplayName on FieldEnum {
  /// Returns a user-friendly display name for the field type
  String get displayName {
    switch (this) {
      case FieldEnum.integer:
        return 'Number';
      case FieldEnum.float:
        return 'Decimal';
      case FieldEnum.text:
        return 'Text';
      case FieldEnum.boolean:
        return 'Toggle';
      case FieldEnum.datetime:
        return 'Date';
      case FieldEnum.enumerated:
        return 'Choice';
      case FieldEnum.dimension:
        return 'Dimension';
      case FieldEnum.reference:
        return 'Reference';
    }
  }
}
