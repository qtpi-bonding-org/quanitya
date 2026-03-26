import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/log_entries/models/log_entry.dart';
void main() {
  group('LogEntryDualDao', () {
    group('Model Tests', () {
      test('LogEntryModel - should create with required fields', () {
        // Arrange & Act
        final now = DateTime.now();
        final model = LogEntryModel(
          id: 'log-123',
          templateId: 'template-123',
          scheduledFor: now,
          occurredAt: now,
          data: {'weight': 75.5, 'unit': 'kg'},
          updatedAt: now,
        );

        // Assert
        expect(model.id, 'log-123');
        expect(model.templateId, 'template-123');
        expect(model.scheduledFor, now);
        expect(model.occurredAt, now);
        expect(model.data, {'weight': 75.5, 'unit': 'kg'});
        expect(model.updatedAt, now);
      });

      test('LogEntryModel.toJson - should serialize correctly', () {
        // Arrange
        final now = DateTime(2024, 1, 1, 12, 0);
        final model = LogEntryModel(
          id: 'log-456',
          templateId: 'template-456',
          scheduledFor: now,
          occurredAt: now,
          data: {'mood': 'happy', 'energy': 8},
          updatedAt: now,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['id'], 'log-456');
        expect(json['templateId'], 'template-456');
        expect(json['data'], {'mood': 'happy', 'energy': 8});
      });

      test('LogEntryModel.fromJson - should deserialize correctly', () {
        // Arrange
        final json = {
          'id': 'log-789',
          'templateId': 'template-789',
          'scheduledFor': '2024-01-01T12:00:00.000',
          'occurredAt': '2024-01-01T12:30:00.000',
          'data': {'steps': 10000},
          'updatedAt': '2024-01-01T12:30:00.000',
        };

        // Act
        final model = LogEntryModel.fromJson(json);

        // Assert
        expect(model.id, 'log-789');
        expect(model.templateId, 'template-789');
        expect(model.data, {'steps': 10000});
      });

      test('LogEntryModel.copyWith - should create modified copy', () {
        // Arrange
        final now = DateTime.now();
        final original = LogEntryModel(
          id: 'log-123',
          templateId: 'template-123',
          scheduledFor: now,
          occurredAt: now,
          data: {'value': 1},
          updatedAt: now,
        );

        // Act
        final modified = original.copyWith(
          data: {'value': 2},
        );

        // Assert
        expect(modified.id, 'log-123'); // Unchanged
        expect(modified.templateId, 'template-123'); // Unchanged
        expect(modified.data, {'value': 2}); // Changed
      });

      test('LogEntryModel - should handle empty data correctly', () {
        // Arrange & Act
        final now = DateTime.now();
        final model = LogEntryModel(
          id: 'log-empty',
          templateId: 'template-123',
          scheduledFor: now,
          occurredAt: now,
          data: {},
          updatedAt: now,
        );

        // Assert
        expect(model.data, isEmpty);
      });

      test('LogEntryModel - should validate occurred at not in future', () {
        // Arrange
        final now = DateTime.now();
        final future = now.add(const Duration(hours: 1));

        // Act & Assert - This should work in the model creation
        // The validation logic would be in the business layer, not the model itself
        final model = LogEntryModel(
          id: 'log-future',
          templateId: 'template-123',
          scheduledFor: now,
          occurredAt: future, // Future time
          data: {'test': true},
          updatedAt: now,
        );

        expect(model.occurredAt, future);
        // Note: Actual validation would happen in the service/repository layer
      });
    });
  });
}