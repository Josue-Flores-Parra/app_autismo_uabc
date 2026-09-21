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

/// Radios de esquina de toda la interfaz.
///
/// Una sola escala evita la mezcla de bordes rectos y redondeados que se
/// colaba entre pantallas: cada componente toma su radio de aqui.
class AppRadius {
  static const double input = 14;
  static const double card = 18;
  static const double button = 16;
  static const double pill = 28;
  static const double sheet = 24;
}

/// Familias tipograficas.
///
/// Coiny para titulos de marca y mensajes grandes; Commissioner para todo el
/// texto explicativo y de interfaz.
class AppFonts {
  static const String display = 'Coiny';
  static const String body = 'Commissioner';
}

/// Colores semanticos de la app, resueltos segun el tema activo.
///
/// Las pantallas leen de aqui (`Theme.of(context).extension<AppColors>()`)
/// en lugar de fijar un azul oscuro a mano. Asi el modo claro es claro de
/// verdad y el alto contraste se respeta en todas partes.
class AppColors extends ThemeExtension<AppColors> {
  /// Fondo de pantalla, de arriba hacia abajo.
  final Color backgroundTop;
  final Color backgroundBottom;

  /// Tarjetas y paneles.
  final Color surface;
  final Color surfaceBorder;

  /// Encabezados destacados (saludo, titulo de nivel).
  final Color headerTop;
  final Color headerBottom;

  /// Texto.
  final Color ink;
  final Color inkSoft;

  /// Acento interactivo y su version suave para fondos.
  final Color accent;
  final Color accentSoft;

  /// Confirmacion y aviso.
  final Color success;
  final Color warning;

  /// Superficies translucidas tipo vidrio.
  final Color glassFill;
  final Color glassBorder;

  const AppColors({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.surface,
    required this.surfaceBorder,
    required this.headerTop,
    required this.headerBottom,
    required this.ink,
    required this.inkSoft,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.warning,
    required this.glassFill,
    required this.glassBorder,
  });

  /// Modo claro: pasteles celestes, los mismos tonos de fondo de las
  /// ilustraciones del personaje, para que no resulte estridente.
  static const AppColors light = AppColors(
    backgroundTop: Color(0xFFEAF4FA),
    backgroundBottom: Color(0xFFD6E9F4),
    surface: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFFCFE1ED),
    headerTop: Color(0xFFDDECF7),
    headerBottom: Color(0xFFC7DEEF),
    ink: Color(0xFF1A3D52),
    inkSoft: Color(0xFF52697A),
    accent: Color(0xFF4A90E2),
    accentSoft: Color(0xFFD8E9F9),
    success: Color(0xFF3FAF74),
    warning: Color(0xFFE0972A),
    glassFill: Color(0xB3FFFFFF),
    glassBorder: Color(0x99FFFFFF),
  );

  /// Modo oscuro: la identidad azul profundo que ya tenia la app.
  static const AppColors dark = AppColors(
    backgroundTop: Color(0xFF0D3B52),
    backgroundBottom: Color(0xFF091F2C),
    surface: Color(0xFF1A3D52),
    surfaceBorder: Color(0xFF2C5F7A),
    headerTop: Color(0xFF2C5F7A),
    headerBottom: Color(0xFF1A3D52),
    ink: Color(0xFFFFFFFF),
    inkSoft: Color(0xFFB8CAD6),
    accent: Color(0xFF6FB1F0),
    accentSoft: Color(0xFF274B62),
    success: Color(0xFF50C878),
    warning: Color(0xFFFFB74D),
    glassFill: Color(0x33FFFFFF),
    glassBorder: Color(0x4DFFFFFF),
  );

  /// Alto contraste: negro y blanco puros con un solo acento.
  static const AppColors highContrastLight = AppColors(
    backgroundTop: Color(0xFFFFFFFF),
    backgroundBottom: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFF000000),
    headerTop: Color(0xFFFFFFFF),
    headerBottom: Color(0xFFFFFFFF),
    ink: Color(0xFF000000),
    inkSoft: Color(0xFF000000),
    accent: Color(0xFF0E1B4D),
    accentSoft: Color(0xFFFFFFFF),
    success: Color(0xFF0E1B4D),
    warning: Color(0xFF0E1B4D),
    glassFill: Color(0xFFFFFFFF),
    glassBorder: Color(0xFF000000),
  );

  static const AppColors highContrastDark = AppColors(
    backgroundTop: Color(0xFF000000),
    backgroundBottom: Color(0xFF000000),
    surface: Color(0xFF000000),
    surfaceBorder: Color(0xFFFFFFFF),
    headerTop: Color(0xFF000000),
    headerBottom: Color(0xFF000000),
    ink: Color(0xFFFFFFFF),
    inkSoft: Color(0xFFFFFFFF),
    accent: Color(0xFF9CC4FF),
    accentSoft: Color(0xFF000000),
    success: Color(0xFF9CC4FF),
    warning: Color(0xFF9CC4FF),
    glassFill: Color(0xFF000000),
    glassBorder: Color(0xFFFFFFFF),
  );

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundTop, backgroundBottom],
  );

  LinearGradient get headerGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerTop, headerBottom],
  );

  @override
  AppColors copyWith({
    Color? backgroundTop,
    Color? backgroundBottom,
    Color? surface,
    Color? surfaceBorder,
    Color? headerTop,
    Color? headerBottom,
    Color? ink,
    Color? inkSoft,
    Color? accent,
    Color? accentSoft,
    Color? success,
    Color? warning,
    Color? glassFill,
    Color? glassBorder,
  }) {
    return AppColors(
      backgroundTop: backgroundTop ?? this.backgroundTop,
      backgroundBottom: backgroundBottom ?? this.backgroundBottom,
      surface: surface ?? this.surface,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      headerTop: headerTop ?? this.headerTop,
      headerBottom: headerBottom ?? this.headerBottom,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      backgroundTop: Color.lerp(backgroundTop, other.backgroundTop, t)!,
      backgroundBottom: Color.lerp(
        backgroundBottom,
        other.backgroundBottom,
        t,
      )!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      headerTop: Color.lerp(headerTop, other.headerTop, t)!,
      headerBottom: Color.lerp(headerBottom, other.headerBottom, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}

/// Acceso corto a los colores semanticos desde cualquier widget.
extension AppColorsContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
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
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(useMaterial3: true, brightness: brightness);

    final appColors = highContrast
        ? (isDark ? AppColors.highContrastDark : AppColors.highContrastLight)
        : (isDark ? AppColors.dark : AppColors.light);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: highContrast ? _highContrastSeed : _seedColor,
          brightness: brightness,
        ).copyWith(
          surface: highContrast
              ? (isDark ? Colors.black : Colors.white)
              : appColors.surface,
          onSurface: appColors.ink,
          outline: highContrast ? appColors.ink : appColors.surfaceBorder,
          primary: appColors.accent,
        );

    // Use explicit Material typography to guarantee font sizes are present
    final defaultTypography = isDark
        ? Typography.material2021().white
        : Typography.material2021().black;

    // Dejar el escalado de texto al MediaQuery.textScaler para evitar asserts
    final bodyTheme = defaultTypography.apply(
      fontFamily: AppFonts.body,
      displayColor: appColors.ink,
      bodyColor: appColors.ink,
    );

    final textTheme = bodyTheme.copyWith(
      displayLarge: bodyTheme.displayLarge?.copyWith(
        fontFamily: AppFonts.display,
      ),
      displayMedium: bodyTheme.displayMedium?.copyWith(
        fontFamily: AppFonts.display,
      ),
      displaySmall: bodyTheme.displaySmall?.copyWith(
        fontFamily: AppFonts.display,
      ),
      headlineLarge: bodyTheme.headlineLarge?.copyWith(
        fontFamily: AppFonts.display,
      ),
      headlineMedium: bodyTheme.headlineMedium?.copyWith(
        fontFamily: AppFonts.display,
      ),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );

    final elevatedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: highContrast ? appColors.ink : appColors.success,
      foregroundColor: highContrast ? appColors.surface : Colors.white,
      shape: buttonShape,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      textStyle: const TextStyle(
        fontFamily: AppFonts.body,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    );

    final filledButtonStyle = FilledButton.styleFrom(
      backgroundColor: highContrast ? appColors.ink : appColors.accent,
      foregroundColor: highContrast ? appColors.surface : Colors.white,
      shape: buttonShape,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      textStyle: const TextStyle(
        fontFamily: AppFonts.body,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    );

    final outlinedButtonStyle = OutlinedButton.styleFrom(
      foregroundColor: appColors.ink,
      side: BorderSide(color: appColors.surfaceBorder, width: 1.5),
      shape: buttonShape,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      textStyle: const TextStyle(
        fontFamily: AppFonts.body,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );

    final textButtonStyle = TextButton.styleFrom(
      foregroundColor: appColors.accent,
      shape: buttonShape,
      textStyle: const TextStyle(
        fontFamily: AppFonts.body,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: appColors.surfaceBorder, width: 1.5),
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
      scaffoldBackgroundColor: appColors.backgroundBottom,
      extensions: [appColors],
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: appColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: appColors.ink,
        ),
        iconTheme: IconThemeData(color: appColors.ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
      filledButtonTheme: FilledButtonThemeData(style: filledButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
      textButtonTheme: TextButtonThemeData(style: textButtonStyle),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: appColors.surface,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: appColors.accent, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(
          fontFamily: AppFonts.body,
          color: appColors.inkSoft,
        ),
        hintStyle: TextStyle(
          fontFamily: AppFonts.body,
          color: appColors.inkSoft,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: appColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: highContrast ? 0 : 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: appColors.surfaceBorder,
            width: highContrast ? 2 : 1,
          ),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: appColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: appColors.ink,
        ),
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 15,
          height: 1.5,
          color: appColors.inkSoft,
        ),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: appColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        contentTextStyle: const TextStyle(fontFamily: AppFonts.body),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelStyle: TextStyle(fontFamily: AppFonts.body, color: appColors.ink),
      ),
      switchTheme: base.switchTheme.copyWith(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return appColors.inkSoft;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return appColors.accent;
          }
          return appColors.accentSoft;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return appColors.surfaceBorder;
        }),
      ),
      pageTransitionsTheme: pageTransitionsTheme,
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: appColors.accent,
        inactiveTrackColor: appColors.accentSoft,
        thumbColor: appColors.accent,
        overlayColor: appColors.accent.withValues(alpha: 0.12),
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: appColors.surfaceBorder,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: appColors.ink,
        textColor: appColors.ink,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: appColors.ink,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 13,
          color: appColors.inkSoft,
        ),
      ),
    );
  }
}
