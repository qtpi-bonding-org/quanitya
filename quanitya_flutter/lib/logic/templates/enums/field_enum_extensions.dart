import 'package:flutter/material.dart';

import 'field_enum.dart';

/// Extension to provide user-friendly display names and icons for field types
extension FieldEnumDisplayName on FieldEnum {
  /// Returns a user-friendly display name for the field type
  String get displayName {
    return switch (this) {
      FieldEnum.integer => 'Number',
      FieldEnum.float => 'Decimal',
      FieldEnum.text => 'Text',
      FieldEnum.boolean => 'Toggle',
      FieldEnum.datetime => 'Date',
      FieldEnum.enumerated => 'Choice',
      FieldEnum.dimension => 'Measurement',
      FieldEnum.reference => 'Reference',
      FieldEnum.location => 'Location',
      FieldEnum.group => 'Group',
    };
  }

  /// Returns the icon representing this field type
  IconData get icon {
    return switch (this) {
      FieldEnum.integer => Icons.numbers,
      FieldEnum.float => Icons.numbers,
      FieldEnum.text => Icons.text_fields,
      FieldEnum.boolean => Icons.toggle_on,
      FieldEnum.datetime => Icons.calendar_today,
      FieldEnum.enumerated => Icons.list,
      FieldEnum.dimension => Icons.straighten,
      FieldEnum.reference => Icons.link,
      FieldEnum.location => Icons.location_on,
      FieldEnum.group => Icons.dashboard,
    };
  }
}
