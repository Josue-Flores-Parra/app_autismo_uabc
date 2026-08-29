import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:appy/l10n/gen/app_localizations.dart';

// Firebase
import 'firebase_options.dart';

// Auth
import 'features/authentication/viewmodel/auth_viewmodel.dart';
import 'features/authentication/view/auth_gate.dart';
import 'features/settings/viewmodel/settings_viewmodel.dart';

// Avatar
import 'features/avatar/model/avatar_models.dart';
import 'features/avatar/data/avatar_repository.dart';
import 'features/avatar/viewmodel/avatar_viewmodel.dart';

// Learning Module
import 'features/learning_module/viewmodel/learning_viewmodel.dart';

// Shared Services
import 'shared/services/loading_service.dart';
import 'shared/widgets/loading_wrapper.dart';

// Minigames
import 'features/minigames/view/types/simple_selection_minigame.dart';
import 'features/minigames/view/types/video_minigame.dart';
import 'features/minigames/view/types/pictogram_minigame.dart';
import 'features/minigames/view/types/audio_minigame.dart';
import 'features/minigames/view/types/puzzle_minigame.dart';
import 'core/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Registrar minijuegos
  registerSimpleSelectionMinigame();
  registerVideoMinigame();
  registerPictogramMinigame();
  registerAudioMinigame();
  registerPuzzleMinigame();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener skins disponibles del repositorio
    final skinsDisponibles = AvatarRepository.obtenerSkinsDisponibles();

    // Crear el estado inicial del avatar
    final estadoInicial = AvatarEstado( // Definir estado inicial con valores por defecto
      nombre: 'nombre',
      felicidad: 64,
      energia: 92,
      skinActual: skinsDisponibles.first,
      backgroundActual:
          'assets/images/Skins/DefaultSkin/backgrounds/default.jpg',
      monedas: 150, // Monedas iniciales
      accesoriosDesbloqueados: {
        'Antenitas', // Desbloqueado por defecto
        'Gafas', // Desbloqueado por defecto
      },
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
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
        ChangeNotifierProvider(create: (_) => LearningViewModel()),
        ChangeNotifierProvider(create: (_) => LoadingService()),
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
                  data: mediaQuery.copyWith(
                    textScaler: textScaler,
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: const AuthGate(), // Gate de autenticación como pantalla inicial
            ),
          );
        },
      ),
    );
  }
}
