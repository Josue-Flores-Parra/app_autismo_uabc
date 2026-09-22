import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appy/l10n/gen/app_localizations.dart';

// Firebase
import 'package:appy/firebase_options.dart';

// Auth
import 'package:appy/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:appy/features/authentication/view/auth_gate.dart';
import 'package:appy/features/settings/viewmodel/settings_viewmodel.dart';

// Avatar
import 'package:appy/features/avatar/model/avatar_models.dart';
import 'package:appy/features/avatar/data/avatar_repository.dart';
import 'package:appy/features/avatar/viewmodel/avatar_viewmodel.dart';

// Learning Module
import 'package:appy/features/learning_module/viewmodel/learning_viewmodel.dart';

// Legal
import 'package:appy/features/legal/viewmodel/legal_viewmodel.dart';

// Shared Services
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Registrar minijuegos
  registerSimpleSelectionMinigame();
  registerPictogramMinigame();
  registerAudioMinigame();
  registerPuzzleMinigame();

  final prefs = await SharedPreferences.getInstance();
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
        ChangeNotifierProxyProvider<AuthViewModel, SettingsViewModel>(
          create: (_) => SettingsViewModel(),
          update: (context, auth, previous) {
            // El consentimiento de telemetría es por cuenta: al cambiar de
            // usuario se carga su preferencia (sendMetrics/onboarding).
            previous!.setAccount(auth.currentUser?.uid);
            return previous;
          },
        ),
        ChangeNotifierProxyProvider<AuthViewModel, AvatarViewModel>(
          create: (_) => AvatarViewModel(estadoInicial),
          update: (context, auth, previous) {
            final avatarVM = previous ?? AvatarViewModel(estadoInicial);
            if (auth.currentUser != null) {
              avatarVM.initialize();
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
        ChangeNotifierProvider(create: (_) => LearningViewModel()),
        ChangeNotifierProvider(create: (_) => LoadingService()),
        ProxyProvider2<SettingsViewModel, AuthViewModel, ActivityTelemetryService>(
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
          final textScaler = TextScaler.linear(settings.textScaleFactor);
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
                return MediaQuery(
                  data: mediaQuery.copyWith(textScaler: textScaler),
                  child: child ?? const SizedBox.shrink(),
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
