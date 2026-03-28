import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/schedules/models/schedule.dart';
void main() {
  group('ScheduleDualDao', () {
    group('Model Tests', () {
      test('ScheduleModel - should create with required fields', () {
        // Arrange & Act
        final now = DateTime.now();
        final model = ScheduleModel(
          id: 'schedule-123',
          templateId: 'template-123',
          recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
          reminderOffsetMinutes: 30,
          isActive: true,
          lastGeneratedAt: now,
          updatedAt: now,
        );

        // Assert
        expect(model.id, 'schedule-123');
        expect(model.templateId, 'template-123');
        expect(model.recurrenceRule, 'FREQ=DAILY;INTERVAL=1');
        expect(model.reminderOffsetMinutes, 30);
        expect(model.isActive, true);
        expect(model.lastGeneratedAt, now);
        expect(model.updatedAt, now);
      });

      test('ScheduleModel.toJson - should serialize correctly', () {
        // Arrange
        final now = DateTime(2024, 1, 1, 12, 0);
        final model = ScheduleModel(
          id: 'schedule-456',
          templateId: 'template-456',
          recurrenceRule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR',
          reminderOffsetMinutes: 60,
          isActive: false,
          lastGeneratedAt: now,
          updatedAt: now,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['id'], 'schedule-456');
        expect(json['templateId'], 'template-456');
        expect(json['recurrenceRule'], 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR');
        expect(json['reminderOffsetMinutes'], 60);
        expect(json['isActive'], false);
      });

      test('ScheduleModel.fromJson - should deserialize correctly', () {
        // Arrange
        final json = {
          'id': 'schedule-789',
          'templateId': 'template-789',
          'recurrenceRule': 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=1',
          'reminderOffsetMinutes': 120,
          'isActive': true,
          'lastGeneratedAt': '2024-01-01T12:00:00.000',
          'updatedAt': '2024-01-01T12:00:00.000',
        };

        // Act
        final model = ScheduleModel.fromJson(json);

        // Assert
        expect(model.id, 'schedule-789');
        expect(model.templateId, 'template-789');
        expect(model.recurrenceRule, 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=1');
        expect(model.reminderOffsetMinutes, 120);
        expect(model.isActive, true);
      });

      test('ScheduleModel.copyWith - should create modified copy', () {
        // Arrange
        final now = DateTime.now();
        final original = ScheduleModel(
          id: 'schedule-123',
          templateId: 'template-123',
          recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
          reminderOffsetMinutes: 30,
          isActive: true,
          lastGeneratedAt: now,
          updatedAt: now,
        );

        // Act
        final modified = original.copyWith(
          reminderOffsetMinutes: 60,
          isActive: false,
        );

        // Assert
        expect(modified.id, 'schedule-123'); // Unchanged
        expect(modified.templateId, 'template-123'); // Unchanged
        expect(modified.recurrenceRule, 'FREQ=DAILY;INTERVAL=1'); // Unchanged
        expect(modified.reminderOffsetMinutes, 60); // Changed
        expect(modified.isActive, false); // Changed
      });

      test('ScheduleModel - should handle different recurrence patterns', () {
        // Test various recurrence rule patterns
        final testCases = [
          'FREQ=DAILY;INTERVAL=1',
          'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR',
          'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=15',
          'FREQ=YEARLY;INTERVAL=1;BYMONTH=1;BYMONTHDAY=1',
        ];

        for (final rule in testCases) {
          final model = ScheduleModel(
            id: 'schedule-test',
            templateId: 'template-test',
            recurrenceRule: rule,
            reminderOffsetMinutes: 0,
            isActive: true,
            lastGeneratedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          expect(model.recurrenceRule, rule);
        }
      });

      test('ScheduleModel - should handle different reminder offsets', () {
        // Test various reminder offset values
        final testCases = [0, 15, 30, 60, 120, 1440]; // 0 min to 24 hours

        for (final offset in testCases) {
          final model = ScheduleModel(
            id: 'schedule-test',
            templateId: 'template-test',
            recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
            reminderOffsetMinutes: offset,
            isActive: true,
            lastGeneratedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          expect(model.reminderOffsetMinutes, offset);
        }
      });

      test('ScheduleModel - should handle active/inactive states', () {
        final now = DateTime.now();
        
        // Test active schedule
        final activeSchedule = ScheduleModel(
          id: 'schedule-active',
          templateId: 'template-123',
          recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
          reminderOffsetMinutes: 30,
          isActive: true,
          lastGeneratedAt: now,
          updatedAt: now,
        );

        // Test inactive schedule
        final inactiveSchedule = ScheduleModel(
          id: 'schedule-inactive',
          templateId: 'template-123',
          recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
          reminderOffsetMinutes: 30,
          isActive: false,
          lastGeneratedAt: now,
          updatedAt: now,
        );

        expect(activeSchedule.isActive, true);
        expect(inactiveSchedule.isActive, false);
      });
    });
  });
}