import 'package:flutter/material.dart';

/// Page transition builder used when animations are disabled.
class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class AppTheme {
  static const Color _seedColor = Color(0xFF4A90E2);
  static const Color _highContrastSeed = Color(0xFF0E1B4D);

  static ThemeData light({
    required double fontScale,
    bool highContrast = false,
    bool reduceMotion = false,
  }) {
    return _buildTheme(
      brightness: Brightness.light,
      fontScale: fontScale,
      highContrast: highContrast,
      reduceMotion: reduceMotion,
    );
  }

  static ThemeData dark({
    required double fontScale,
    bool highContrast = false,
    bool reduceMotion = false,
  }) {
    return _buildTheme(
      brightness: Brightness.dark,
      fontScale: fontScale,
      highContrast: highContrast,
      reduceMotion: reduceMotion,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required double fontScale,
    required bool highContrast,
    required bool reduceMotion,
  }) {
    final base = ThemeData(useMaterial3: true, brightness: brightness);

    // Use explicit Material typography to guarantee font sizes are present
    final defaultTypography = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: highContrast ? _highContrastSeed : _seedColor,
          brightness: brightness,
        ).copyWith(
          surface: highContrast ? Colors.black : null,
          onSurface: highContrast ? Colors.white : null,
          outline: highContrast ? Colors.white70 : null,
        );

    final textTheme = defaultTypography.apply(
      // Dejar el escalado de texto al MediaQuery.textScaler para evitar asserts
      displayColor: highContrast ? Colors.white : colorScheme.onSurface,
      bodyColor: highContrast ? Colors.white : colorScheme.onSurface,
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: highContrast
          ? colorScheme.onSurface
          : const Color(0xFF50C878),
      foregroundColor: highContrast ? colorScheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );

    final pageTransitionsTheme = reduceMotion
        ? const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: NoTransitionsBuilder(),
              TargetPlatform.iOS: NoTransitionsBuilder(),
              TargetPlatform.macOS: NoTransitionsBuilder(),
              TargetPlatform.linux: NoTransitionsBuilder(),
              TargetPlatform.windows: NoTransitionsBuilder(),
            },
          )
        : base.pageTransitionsTheme;

    return base.copyWith(
      colorScheme: colorScheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: highContrast ? 2 : 0,
      ),
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      cardTheme: base.cardTheme.copyWith(
        color: colorScheme.surface,
        elevation: highContrast ? 6 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: highContrast
                ? colorScheme.onSurface
                : colorScheme.outlineVariant,
            width: highContrast ? 2 : 1,
          ),
        ),
      ),
      switchTheme: base.switchTheme.copyWith(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primaryContainer;
          }
          return colorScheme.surfaceVariant;
        }),
      ),
      pageTransitionsTheme: pageTransitionsTheme,
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.1),
      ),
    );
  }
}
