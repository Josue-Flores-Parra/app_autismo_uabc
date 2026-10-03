import 'package:appy/features/profiles/data/profile_repository.dart';
import 'package:appy/features/profiles/model/learner_profile.dart';
import 'package:appy/features/profiles/viewmodel/profile_viewmodel.dart';
import 'package:appy/shared/services/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepository implements ProfileRepository {
  @override
  Future<bool> isInitialized(String parentUid) async => true;

  @override
  Future<void> ensureParent(String parentUid) async {}

  @override
  Future<List<LearnerProfile>> listLearners(String parentUid) async => [
    const LearnerProfile(id: 'kid-1', name: 'Ana'),
  ];

  @override
  Future<void> updateLearnerSettings(
    String parentUid,
    String learnerId,
    LearnerSettings settings,
  ) async {}

  @override
  Future<void> deleteLearner(String parentUid, String learnerId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeScheduler implements ReminderScheduler {
  final List<String> calls = [];
  bool granted = true;
  bool failing = false;

  @override
  Future<bool> requestPermission() async {
    calls.add('permission');
    return granted;
  }

  @override
  Future<void> scheduleDaily({
    required String learnerId,
    required String time,
    required ReminderMessage message,
  }) async {
    if (failing) throw StateError('sin sistema de notificaciones');
    calls.add('schedule:$learnerId:$time:${message.title}');
  }

  @override
  Future<void> cancel(String learnerId) async {
    if (failing) throw StateError('sin sistema de notificaciones');
    calls.add('cancel:$learnerId');
  }
}

const _message = ReminderMessage(title: 'Hora de practicar', body: 'Hola');

void main() {
  late _FakeScheduler scheduler;
  late ProfileViewModel profiles;
  late LearnerProfile learner;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    scheduler = _FakeScheduler();
    profiles = ProfileViewModel(
      repository: _FakeRepository(),
      reminders: scheduler,
    );
    await profiles.loadForParent('parent-1');
    learner = profiles.learners.single;
  });

  test('turning reminders on schedules the daily notice', () async {
    await profiles.updateLearnerSettings(
      learner,
      learner.settings.copyWith(remindersEnabled: true, reminderTime: '17:30'),
      reminderMessage: _message,
    );

    expect(scheduler.calls, ['schedule:kid-1:17:30:Hora de practicar']);
  });

  test('turning reminders off cancels the notice', () async {
    await profiles.updateLearnerSettings(
      learner,
      learner.settings.copyWith(remindersEnabled: false),
    );

    expect(scheduler.calls, ['cancel:kid-1']);
  });

  test('changing other settings leaves an active reminder alone', () async {
    final active = learner.settings.copyWith(remindersEnabled: true);
    await profiles.updateLearnerSettings(
      learner,
      active.copyWith(highContrast: true),
    );

    expect(scheduler.calls, isEmpty);
  });

  test('a notification failure does not stop saving the settings', () async {
    scheduler.failing = true;

    await profiles.updateLearnerSettings(
      learner,
      learner.settings.copyWith(remindersEnabled: true),
      reminderMessage: _message,
    );

    expect(profiles.learners.single.settings.remindersEnabled, isTrue);
  });

  test('deleting a profile cancels its notice', () async {
    await profiles.deleteLearner(learner);

    expect(scheduler.calls, ['cancel:kid-1']);
  });

  test('permission is requested through the scheduler', () async {
    scheduler.granted = false;

    expect(await profiles.requestReminderPermission(), isFalse);
    expect(scheduler.calls, ['permission']);
  });
}
