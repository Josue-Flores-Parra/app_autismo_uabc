import 'package:appy/core/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAppEnvironment', () {
    test('sin APP_ENV, depuracion usa desarrollo', () {
      expect(resolveAppEnvironment('', isRelease: false), AppEnvironment.dev);
    });

    test('sin APP_ENV, release usa produccion', () {
      expect(resolveAppEnvironment('', isRelease: true), AppEnvironment.prod);
    });

    test('APP_ENV explicito gana sobre el modo de compilacion', () {
      expect(resolveAppEnvironment('dev', isRelease: true), AppEnvironment.dev);
      expect(
        resolveAppEnvironment('prod', isRelease: false),
        AppEnvironment.prod,
      );
    });

    test('un valor desconocido falla en lugar de elegir un proyecto', () {
      expect(
        () => resolveAppEnvironment('production', isRelease: true),
        throwsArgumentError,
      );
    });
  });
}
