import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kReleaseMode;

import 'package:appy/firebase_options.dart' as prod;
import 'package:appy/firebase_options_dev.dart' as dev;

/// Proyecto de Firebase al que se conecta una build.
enum AppEnvironment {
  /// Proyecto `appy-dev-uabc`, para desarrollo y QA.
  dev,

  /// Proyecto `app-autismo-25f44`, con las cuentas reales.
  prod,
}

/// Entorno de esta build.
///
/// `--dart-define=APP_ENV=dev` o `--dart-define=APP_ENV=prod` lo fija. Sin esa
/// bandera, `flutter run` usa desarrollo y las builds release usan produccion,
/// para que las pruebas locales no escriban sobre datos reales y las builds de
/// tienda no dependan de recordar la bandera.
final AppEnvironment appEnvironment = resolveAppEnvironment(
  const String.fromEnvironment('APP_ENV'),
  isRelease: kReleaseMode,
);

/// Devuelve el entorno que corresponde a [value] y al modo de compilacion.
///
/// Lanza [ArgumentError] si [value] no es vacio, `dev` ni `prod`, para que un
/// error de escritura no termine conectando la build al proyecto equivocado.
AppEnvironment resolveAppEnvironment(String value, {required bool isRelease}) {
  switch (value) {
    case 'dev':
      return AppEnvironment.dev;
    case 'prod':
      return AppEnvironment.prod;
    case '':
      return isRelease ? AppEnvironment.prod : AppEnvironment.dev;
    default:
      throw ArgumentError.value(value, 'APP_ENV', 'Usa "dev" o "prod"');
  }
}

/// Opciones de Firebase de [appEnvironment] para la plataforma actual.
FirebaseOptions get currentFirebaseOptions => switch (appEnvironment) {
  AppEnvironment.dev => dev.DefaultFirebaseOptions.currentPlatform,
  AppEnvironment.prod => prod.DefaultFirebaseOptions.currentPlatform,
};
