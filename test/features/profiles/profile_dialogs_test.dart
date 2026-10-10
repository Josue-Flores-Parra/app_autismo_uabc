import 'package:appy/core/app_theme.dart';
import 'package:appy/features/profiles/model/learner_profile.dart';
import 'package:appy/features/profiles/view/child_settings_screen.dart';
import 'package:appy/features/profiles/view/profile_screens.dart';
import 'package:appy/features/profiles/viewmodel/profile_viewmodel.dart';
import 'package:appy/l10n/gen/app_localizations.dart';
import 'package:appy/shared/services/reminder_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _ProfileViewModelFake extends ProfileViewModel {
  _ProfileViewModelFake({
    List<LearnerProfile> learners = const [],
    bool legacy = false,
  }) : _learners = learners,
       _legacy = legacy;

  List<LearnerProfile> _learners;
  bool _legacy;
  bool _unlocked = false;

  /// Si es `true`, el doble de prueba niega el PIN como un check fallido.
  bool denyUnlock = false;
  AppProfileMode? _mode;
  final addedNames = <String>[];

  @override
  List<LearnerProfile> get learners => _learners;

  @override
  bool get needsInitialLearner => _learners.isEmpty;

  @override
  bool get didMigrateLegacy => _legacy;

  @override
  AppProfileMode? get mode => _mode;

  @override
  bool get parentUnlocked => _unlocked;

  @override
  void unlockParent() {
    _unlocked = true;
    _mode = null;
    notifyListeners();
  }

  @override
  Future<bool> ensureParentUnlocked(BuildContext context) async {
    if (denyUnlock) return false;
    unlockParent();
    return true;
  }

  @override
  Future<void> selectLearner(LearnerProfile learner) async {
    _mode = AppProfileMode.learner;
    notifyListeners();
  }

  @override
  Future<LearnerProfile> addLearner(String name) async {
    addedNames.add(name);
    final learner = LearnerProfile(
      id: 'child-${_learners.length + 1}',
      name: name,
    );
    _learners = [..._learners, learner];
    _mode = null;
    notifyListeners();
    return learner;
  }

  @override
  Future<void> renameLearner(LearnerProfile learner, String name) async {
    _learners = [
      for (final item in _learners)
        if (item.id == learner.id)
          LearnerProfile(
            id: item.id,
            name: name,
            allowedModules: item.allowedModules,
            settings: item.settings,
          )
        else
          item,
    ];
    notifyListeners();
  }

  @override
  Future<void> setLearnerAllowedModules(
    LearnerProfile learner,
    int count,
  ) async {
    _learners = [
      for (final item in _learners)
        if (item.id == learner.id)
          LearnerProfile(
            id: item.id,
            name: item.name,
            allowedModules: count,
            settings: item.settings,
          )
        else
          item,
    ];
    notifyListeners();
  }

  @override
  Future<void> updateLearnerSettings(
    LearnerProfile learner,
    LearnerSettings settings, {
    ReminderMessage? reminderMessage,
  }) async {
    _learners = [
      for (final item in _learners)
        if (item.id == learner.id)
          LearnerProfile(
            id: item.id,
            name: item.name,
            allowedModules: item.allowedModules,
            settings: settings,
          )
        else
          item,
    ];
    notifyListeners();
  }

  @override
  void confirmLegacyName() {
    _legacy = false;
    notifyListeners();
  }

  @override
  Future<void> deleteLearner(LearnerProfile learner) async {
    _learners = [
      for (final item in _learners)
        if (item.id != learner.id) item,
    ];
    notifyListeners();
  }
}

Widget _app(_ProfileViewModelFake profiles) {
  return ChangeNotifierProvider<ProfileViewModel>.value(
    value: profiles,
    child: MaterialApp(
      theme: AppTheme.light(fontScale: 1),
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(1)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      // Hub único para sesiones bloqueadas y desbloqueadas; el modo learner
      // queda fuera del alcance de estos tests de diálogos.
      home: const ProfileSelectorScreen(),
    ),
  );
}

void main() {
  testWidgets('first child submit stays on selector with learner listed', (
    tester,
  ) async {
    final profiles = _ProfileViewModelFake();
    addTearDown(profiles.dispose);
    await tester.pumpWidget(_app(profiles));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear primer perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(profiles.addedNames, ['Alex']);
    expect(find.byType(ProfileSelectorScreen), findsOneWidget);
    expect(find.text('Perfiles de la familia'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling first child dialog keeps selector usable', (
    tester,
  ) async {
    final profiles = _ProfileViewModelFake();
    addTearDown(profiles.dispose);
    await tester.pumpWidget(_app(profiles));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear primer perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(profiles.addedNames, isEmpty);
    expect(find.text('Crear primer perfil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard submission also waits for the dialog to leave', (
    tester,
  ) async {
    final profiles = _ProfileViewModelFake();
    addTearDown(profiles.dispose);
    await tester.pumpWidget(_app(profiles));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear primer perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(profiles.addedNames, ['Alex']);
    expect(find.byType(ProfileSelectorScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('locked hub shows one heading with edit and one-tap select', (
    tester,
  ) async {
    final profiles = _ProfileViewModelFake(
      learners: [const LearnerProfile(id: 'child-1', name: 'Alex')],
    );
    addTearDown(profiles.dispose);
    await tester.pumpWidget(_app(profiles));
    await tester.pumpAndSettle();

    // Texto único: sin pantallas separadas de "quién aprende" vs "perfiles".
    expect(find.text('Perfiles de la familia'), findsOneWidget);
    expect(
      find.text('Elige un perfil para comenzar o edita sus ajustes.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Editar perfil'), findsOneWidget);

    // Elegir un perfil sigue siendo un toque aunque la gestión esté bloqueada.
    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();
    expect(profiles.mode, AppProfileMode.learner);
    expect(tester.takeException(), isNull);
  });

  testWidgets('denied PIN keeps management locked without dialogs', (
    tester,
  ) async {
    final profiles = _ProfileViewModelFake(
      learners: [const LearnerProfile(id: 'child-1', name: 'Alex')],
    )..denyUnlock = true;
    addTearDown(profiles.dispose);
    await tester.pumpWidget(_app(profiles));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar perfil infantil'));
    await tester.pumpAndSettle();

    expect(profiles.addedNames, isEmpty);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ProfileSelectorScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unlocked hub edit opens child settings', (tester) async {
    final profiles = _ProfileViewModelFake(
      learners: [const LearnerProfile(id: 'child-1', name: 'Alex')],
    )..unlockParent();
    addTearDown(profiles.dispose);
    await tester.pumpWidget(_app(profiles));
    await tester.pumpAndSettle();

    expect(find.text('Perfiles de la familia'), findsOneWidget);
    await tester.tap(find.byTooltip('Editar perfil'));
    await tester.pumpAndSettle();

    expect(find.byType(ChildSettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding from unlocked hub keeps the same hub screen', (
    tester,
  ) async {
    final profiles = _ProfileViewModelFake(
      learners: [const LearnerProfile(id: 'child-1', name: 'Alex')],
    )..unlockParent();
    addTearDown(profiles.dispose);
    await tester.pumpWidget(_app(profiles));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar perfil infantil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Sam');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(profiles.addedNames, ['Sam']);
    expect(find.byType(ProfileSelectorScreen), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('child settings toggle persists per-child preference', (
    tester,
  ) async {
    final profiles = _ProfileViewModelFake(
      learners: [const LearnerProfile(id: 'child-1', name: 'Alex')],
    )..unlockParent();
    addTearDown(profiles.dispose);
    await tester.pumpWidget(_app(profiles));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar perfil'));
    await tester.pumpAndSettle();

    final contrast = find.widgetWithText(SwitchListTile, 'Alto contraste');
    expect(contrast, findsOneWidget);
    // Los recordatorios empujan el switch fuera de la pantalla de prueba.
    await tester.ensureVisible(contrast);
    await tester.pumpAndSettle();
    await tester.tap(contrast);
    await tester.pumpAndSettle();

    expect(profiles.learners.single.settings.highContrast, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'confirming migrated name exits dialog before updating selector',
    (tester) async {
      final profiles = _ProfileViewModelFake(
        learners: [const LearnerProfile(id: 'child-1', name: 'Alex')],
        legacy: true,
      );
      addTearDown(profiles.dispose);
      await tester.pumpWidget(_app(profiles));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar nombre'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Sam');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar nombre'));
      await tester.pumpAndSettle();

      expect(profiles.learners.single.name, 'Sam');
      expect(profiles.didMigrateLegacy, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('deleting a profile confirms, removes it and returns', (
    tester,
  ) async {
    final profiles = _ProfileViewModelFake(
      learners: [const LearnerProfile(id: 'child-1', name: 'Alex')],
    )..unlockParent();
    addTearDown(profiles.dispose);
    await tester.pumpWidget(_app(profiles));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar perfil'));
    await tester.pumpAndSettle();
    expect(find.byType(ChildSettingsScreen), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Eliminar perfil'), 200);
    await tester.tap(find.text('Eliminar perfil'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar a Alex?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    // Pumps acotados: pumpAndSettle adelantaría más allá del snackbar de 4s.
    // El aviso se muestra después de que la ruta saliente se elimina.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Se eliminó el perfil de Alex.').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(profiles.learners, isEmpty);
    expect(find.byType(ProfileSelectorScreen), findsOneWidget);
    expect(find.text('Alex'), findsNothing);
    // El aviso rojo de éxito sobrevive al pop de vuelta al hub.
    expect(find.text('Se eliminó el perfil de Alex.'), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final scheme = Theme.of(tester.element(find.byType(ProfileSelectorScreen)));
    expect(snackBar.backgroundColor, scheme.colorScheme.error);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling delete keeps the profile', (tester) async {
    final profiles = _ProfileViewModelFake(
      learners: [const LearnerProfile(id: 'child-1', name: 'Alex')],
    )..unlockParent();
    addTearDown(profiles.dispose);
    await tester.pumpWidget(_app(profiles));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Eliminar perfil'), 200);
    await tester.tap(find.text('Eliminar perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(profiles.learners.single.name, 'Alex');
    expect(find.byType(ChildSettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unconfirmed profile renders dimmed with a pending label', (
    tester,
  ) async {
    final profiles = _ProfileViewModelFake(
      learners: [
        const LearnerProfile(
          id: 'child-1',
          name: 'Alex',
          needsNameConfirmation: true,
        ),
        const LearnerProfile(id: 'child-2', name: 'Sam'),
      ],
    );
    addTearDown(profiles.dispose);
    await tester.pumpWidget(_app(profiles));
    await tester.pumpAndSettle();

    expect(find.text('Pendiente de confirmación'), findsOneWidget);

    final pendingOpacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Alex'), matching: find.byType(Opacity)),
    );
    expect(pendingOpacity.opacity, 0.5);

    final confirmedOpacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Sam'), matching: find.byType(Opacity)),
    );
    expect(confirmedOpacity.opacity, 1.0);
    expect(tester.takeException(), isNull);
  });
}
