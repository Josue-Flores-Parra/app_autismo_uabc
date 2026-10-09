import 'dart:async';
import 'data/services/network_connection_service.dart';
import 'package:flutter/material.dart';
import 'features/learning_module/data/completion_sync_service.dart';
import 'core/preference_text_scaler.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appy/l10n/gen/app_localizations.dart';

// Firebase
import 'package:appy/core/app_environment.dart';

// Auth
import 'package:appy/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:appy/features/authentication/view/auth_gate.dart';
import 'package:appy/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:appy/features/profiles/viewmodel/profile_viewmodel.dart';

// Avatar
import 'package:appy/features/avatar/model/avatar_models.dart';
import 'package:appy/features/avatar/data/avatar_repository.dart';
import 'package:appy/features/avatar/viewmodel/avatar_viewmodel.dart';

// Learning Module
import 'package:appy/features/learning_module/viewmodel/learning_viewmodel.dart';

// Legal
import 'package:appy/features/legal/viewmodel/legal_viewmodel.dart';

// Shared Services
import 'package:appy/data/services/offline_assets_service.dart';
import 'package:appy/shared/services/loading_service.dart';
import 'package:appy/shared/widgets/loading_wrapper.dart';

// Minigames
import 'package:appy/features/minigames/view/types/simple_selection_minigame.dart';
import 'package:appy/features/minigames/view/types/pictogram_minigame.dart';
import 'package:appy/features/minigames/view/types/audio_minigame.dart';
import 'package:appy/features/minigames/view/types/puzzle_minigame.dart';
import 'package:appy/core/app_theme.dart';

// Telemetry
import 'features/telemetry/data/telemetry_repository.dart';
import 'features/telemetry/service/activity_telemetry_service.dart';
import 'features/telemetry/service/pending_session_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La app se usa en vertical. Solo el reproductor de video pide horizontal
  // al entrar a pantalla completa y lo devuelve al salir.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: currentFirebaseOptions);

  // Lee lo descargado para usarlo sin conexión. Si falla, la app sigue con red.
  try {
    await OfflineAssetsService.instance.init();
  } catch (e) {
    debugPrint('OfflineAssetsService no se pudo iniciar: $e');
  }

  // Registrar minijuegos
  registerSimpleSelectionMinigame();
  registerPictogramMinigame();
  registerAudioMinigame();
  registerPuzzleMinigame();

  final prefs = await SharedPreferences.getInstance();
  final network = NetworkConnectionService();
  unawaited(network.start());
  final completions = CompletionSyncService(
    prefs: prefs,
    confirm: CompletionRepository(FirebaseFirestore.instance).confirm,
    actorProvider: () => FirebaseAuth.instance.currentUser?.uid,
    network: network,
  );
  CompletionSyncService.instance = completions;
  completions.start();
  final telemetryService = ActivityTelemetryService(
    repository: TelemetryRepository(FirebaseFirestore.instance),
    pendingStore: PendingSessionStore(prefs),
    uidProvider: () => FirebaseAuth.instance.currentUser?.uid,
  );

  runApp(MyApp(telemetryService: telemetryService));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.telemetryService});

  final ActivityTelemetryService telemetryService;

  @override
  Widget build(BuildContext context) {
    // Estado de arranque del avatar. Es un marcador hasta que se lee la
    // cuenta; los valores reales viven en Firestore desde el registro.
    final estadoInicial = AvatarEstado.inicial(
      skin: AvatarRepository.obtenerSkinsDisponibles().first,
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProxyProvider2<
          AuthViewModel,
          ProfileViewModel,
          SettingsViewModel
        >(
          create: (_) => SettingsViewModel(),
          update: (context, auth, profiles, previous) {
            final settings = previous ?? SettingsViewModel();
            // El consentimiento de telemetría es por cuenta: al cambiar de
            // usuario se carga su preferencia (sendMetrics/onboarding).
            settings.setAccount(auth.currentUser?.uid);
            // Los ajustes de aprendizaje y accesibilidad son por perfil: el
            // seleccionado define los valores efectivos de la app.
            // Theme/locale intentionally stay parent-wide on this provider.
            settings.applyLearnerSettings(profiles.selectedLearner?.settings);
            return settings;
          },
        ),
        ChangeNotifierProxyProvider2<
          AuthViewModel,
          ProfileViewModel,
          AvatarViewModel
        >(
          create: (_) => AvatarViewModel(estadoInicial),
          update: (context, auth, profiles, previous) {
            final avatarVM = previous ?? AvatarViewModel(estadoInicial);
            // Never let the parent Auth UID address child avatar/coin data.
            avatarVM.setLearnerUid(profiles.learnerUid);
            if (auth.currentUser != null && profiles.learnerUid != null) {
              avatarVM.initialize(userId: profiles.learnerUid);
            }
            return avatarVM;
          },
        ),
        ChangeNotifierProxyProvider<AuthViewModel, LegalViewModel>(
          create: (_) => LegalViewModel(),
          update: (context, auth, previous) {
            final legalVM = previous ?? LegalViewModel();
            if (auth.currentUser == null) {
              legalVM.reset();
            }
            return legalVM;
          },
        ),
        ChangeNotifierProxyProvider<ProfileViewModel, LearningViewModel>(
          create: (_) => LearningViewModel(),
          update: (context, profiles, previous) {
            final viewModel = previous ?? LearningViewModel();
            // Changing profiles invalidates old caches and async loads so one
            // sibling cannot briefly see another sibling's progress.
            viewModel.setLearnerUid(profiles.learnerUid);
            return viewModel;
          },
        ),
        ChangeNotifierProvider(create: (_) => LoadingService()),
        Provider<_CompletionRefresh>(
          create: (context) => _CompletionRefresh(
            context.read<ProfileViewModel>(),
            context.read<AvatarViewModel>(),
            context.read<LearningViewModel>(),
          ),
          lazy: false,
          dispose: (_, refresh) => refresh.dispose(),
        ),
        ProxyProvider2<
          SettingsViewModel,
          AuthViewModel,
          ActivityTelemetryService
        >(
          create: (_) => telemetryService,
          update: (context, settings, auth, previous) {
            final service = previous ?? telemetryService;
            // El servicio no evalúa `sendMetrics` hasta que Settings esté listo.
            service.updateConsent(
              ready: settings.isReady,
              enabled: settings.sendMetrics,
            );
            // Reconciliar marcador pendiente sólo después de Auth y Settings listos.
            if (settings.isReady && auth.currentUser != null) {
              service.reconcilePending(consentEnabled: settings.sendMetrics);
            }
            return service;
          },
        ),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settings, _) {
          return LoadingWrapper(
            child: MaterialApp(
              title: 'Appy',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(
                fontScale: settings.textScaleFactor,
                highContrast: settings.highContrast,
                reduceMotion: settings.reduceAnimations,
              ),
              darkTheme: AppTheme.dark(
                fontScale: settings.textScaleFactor,
                highContrast: settings.highContrast,
                reduceMotion: settings.reduceAnimations,
              ),
              themeMode: settings.themeMode,
              locale: settings.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                final app = MediaQuery(
                  data: mediaQuery.copyWith(
                    disableAnimations:
                        mediaQuery.disableAnimations ||
                        settings.reduceAnimations,
                    textScaler: PreferenceTextScaler(
                      mediaQuery.textScaler,
                      settings.textScaleFactor,
                    ),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
                // La marca evita confundir una build de QA con produccion.
                if (appEnvironment != AppEnvironment.dev) return app;
                return Banner(
                  message: 'DEV',
                  location: BannerLocation.topEnd,
                  child: app,
                );
              },
              home:
                  const AuthGate(), // Gate de autenticación como pantalla inicial
            ),
          );
        },
      ),
    );
  }
}

/// Refresca solo el perfil activo tras confirmar una recompensa pendiente.
class _CompletionRefresh {
  _CompletionRefresh(this.profiles, this.avatar, this.learning) {
    CompletionSyncService.instance?.addListener(refresh);
  }
  final ProfileViewModel profiles;
  final AvatarViewModel avatar;
  final LearningViewModel learning;
  void refresh() {
    final queue = CompletionSyncService.instance;
    if (queue?.lastConfirmedLearner != profiles.learnerUid) return;
    unawaited(
      avatar.loadAvatarConfigFromFirestore().catchError((Object e) {
        debugPrint('No se pudo refrescar recompensa: $e');
      }),
    );
    unawaited(learning.refreshModulesProgress());
  }

  void dispose() => CompletionSyncService.instance?.removeListener(refresh);
}
