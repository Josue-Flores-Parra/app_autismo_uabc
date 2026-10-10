import 'package:appy/features/profiles/model/learner_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearnerProfile', () {
    test('parses learner settings and clamps module limits', () {
      final profile = LearnerProfile.fromMap('learner-a', {
        'name': ' Alex ',
        'parentUid': 'parent-a',
        'allowedModules': 14,
        'migrationStatus': 'complete',
      });

      expect(profile.id, 'learner-a');
      expect(profile.name, 'Alex');
      expect(profile.parentUid, 'parent-a');
      expect(profile.allowedModules, 10);
      expect(profile.migrationComplete, isTrue);
    });

    test('does not expose a profile while migration is incomplete', () {
      final profile = LearnerProfile.fromMap('learner-a', {
        'name': 'Alex',
        'migrationStatus': 'copying',
      });

      expect(profile.migrationComplete, isFalse);
    });

    test('legacy migration requires the parent to confirm the child name', () {
      final profile = LearnerProfile.fromMap('learner-a', {
        'name': 'Alex',
        'migrationStatus': 'complete',
        'nameConfirmed': false,
      });

      expect(profile.migrationComplete, isTrue);
      expect(profile.needsNameConfirmation, isTrue);
    });

    test('zero module limit means no limit', () {
      final profile = LearnerProfile.fromMap('learner-a', {
        'name': 'Alex',
        'allowedModules': 0,
      });

      expect(profile.allowedModules, 0);
    });

    test('parses per-child settings with safe fallbacks', () {
      final profile = LearnerProfile.fromMap('learner-a', {
        'name': 'Alex',
        'settings': {
          'fontScale': 'large',
          'highContrast': true,
          'reduceAnimations': true,
          'audioFeedback': false,
          'hapticFeedback': false,
          'remindersEnabled': true,
          'reminderTime': '09:30',
        },
      });

      expect(profile.settings.fontScale, 'large');
      expect(profile.settings.highContrast, isTrue);
      expect(profile.settings.reduceAnimations, isTrue);
      expect(profile.settings.audioFeedback, isFalse);
      expect(profile.settings.hapticFeedback, isFalse);
      expect(profile.settings.remindersEnabled, isTrue);
      expect(profile.settings.reminderTime, '09:30');
    });

    test('invalid settings values fall back to defaults', () {
      final profile = LearnerProfile.fromMap('learner-a', {
        'name': 'Alex',
        'settings': {
          'fontScale': 'huge',
          'highContrast': 'yes',
          'reminderTime': '99:99',
        },
      });

      expect(profile.settings.fontScale, 'medium');
      expect(profile.settings.highContrast, isFalse);
      expect(profile.settings.reminderTime, '18:00');
    });

    test('missing settings map uses defaults', () {
      const profile = LearnerProfile(id: 'learner-a', name: 'Alex');

      expect(profile.settings, LearnerSettings.defaults);
    });
  });
}
