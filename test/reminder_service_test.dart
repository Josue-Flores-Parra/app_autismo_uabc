import 'package:appy/shared/services/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('reminderIdFor', () {
    test('is stable and fits a 32 bit signed integer', () {
      final id = ReminderService.reminderIdFor('learner-123');
      expect(ReminderService.reminderIdFor('learner-123'), id);
      expect(id, inInclusiveRange(0, 0x7fffffff));
    });

    test('differs between learners', () {
      expect(
        ReminderService.reminderIdFor('learner-a'),
        isNot(ReminderService.reminderIdFor('learner-b')),
      );
    });
  });

  group('parseReminderTime', () {
    test('reads a valid HH:mm time', () {
      final time = ReminderService.parseReminderTime('07:05');
      expect(time.hour, 7);
      expect(time.minute, 5);
    });

    test('falls back to 18:00 when the value is not valid', () {
      for (final value in ['', 'abc', '25:00', '10:75', '10', '10:20:30']) {
        final time = ReminderService.parseReminderTime(value);
        expect((time.hour, time.minute), (18, 0), reason: value);
      }
    });
  });

  group('nextReminderMoment', () {
    late tz.Location tijuana;

    setUpAll(() {
      tz_data.initializeTimeZones();
      tijuana = tz.getLocation('America/Tijuana');
    });

    test('is today when the time has not passed yet', () {
      final now = tz.TZDateTime(tijuana, 2026, 10, 1, 9, 30);
      final next = ReminderService.nextReminderMoment(now, 18, 0);
      expect(next, tz.TZDateTime(tijuana, 2026, 10, 1, 18, 0));
    });

    test('is tomorrow when the time already passed', () {
      final now = tz.TZDateTime(tijuana, 2026, 10, 1, 19, 0);
      final next = ReminderService.nextReminderMoment(now, 18, 0);
      expect(next, tz.TZDateTime(tijuana, 2026, 10, 2, 18, 0));
    });

    test('is tomorrow when it is exactly the reminder time', () {
      final now = tz.TZDateTime(tijuana, 2026, 10, 1, 18, 0);
      final next = ReminderService.nextReminderMoment(now, 18, 0);
      expect(next, tz.TZDateTime(tijuana, 2026, 10, 2, 18, 0));
    });

    test('rolls over to the next month', () {
      final now = tz.TZDateTime(tijuana, 2026, 10, 31, 20, 0);
      final next = ReminderService.nextReminderMoment(now, 8, 0);
      expect(next, tz.TZDateTime(tijuana, 2026, 11, 1, 8, 0));
    });
  });
}
