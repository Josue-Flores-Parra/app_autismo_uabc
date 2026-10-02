import 'package:flutter/material.dart';
import 'dart:math';
import 'package:appy/l10n/gen/app_localizations.dart';
import 'package:provider/provider.dart';
import '../model/modulo_info.dart';
import '../viewmodel/learning_viewmodel.dart';
import 'level_timeline_screen.dart';
import '../../../core/app_theme.dart';
import '../../../shared/services/settings_access_guard.dart';
import '../../profiles/viewmodel/profile_viewmodel.dart';

/// Pantalla principal que muestra la lista de módulos de aprendizaje.
/// Esta es la VISTA en el patrón MVVM - solo se encarga de mostrar los datos.
class ModuleListScreen extends StatelessWidget {
  const ModuleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.navModules ?? 'Mis Módulos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n?.settingsTitle ?? 'Ajustes',
            // Mismo PIN que la pestaña de Ajustes: este atajo no puede ser
            // una puerta trasera al control parental.
            onPressed: () async {
              final unlocked = await SettingsAccessGuard.ensureAccess(context);
              if (!unlocked || !context.mounted) return;
              context.read<ProfileViewModel>().unlockParent();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: context.appColors.backgroundGradient,
        ),
        child: Consumer<LearningViewModel>(
          builder: (context, viewModel, child) {
            // Mostrar skeleton mientras carga
            if (viewModel.isLoadingModules) {
              return const _ModuleListSkeleton();
            }

            // Mostrar error
            if (viewModel.errorMessageModules != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      viewModel.errorMessageModules!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => viewModel.reloadModules(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            // Obtener nombre de usuario desde Firebase Auth
            final learner = context.watch<ProfileViewModel>().selectedLearner;
            final nombreUsuario = learner?.name ?? 'Usuario';
            final nivelUsuario = viewModel.completedLevelsCount;

            final allowedModules = learner?.allowedModules ?? 0;
            return ModulosGridView(
              modulos: viewModel.modulos,
              nombreUsuario: nombreUsuario,
              nivelUsuario: nivelUsuario,
              allowedModules: allowedModules,
            );
          },
        ),
      ),
    );
  }
}

/// Widget que muestra el grid de módulos.
/// Separado para mantener el código organizado.
class ModulosGridView extends StatelessWidget {
  final List<ModuloInfo> modulos;
  final String nombreUsuario;
  final int nivelUsuario;

  /// Cuántos módulos deja abrir el control parental. `0` es sin límite.
  final int allowedModules;

  const ModulosGridView({
    super.key,
    required this.modulos,
    required this.nombreUsuario,
    required this.nivelUsuario,
    required this.allowedModules,
  });

  @override
  Widget build(BuildContext context) {
    final filteredModules = modulos.asMap().entries.map((entry) {
      final modulo = entry.value;
      final fueraDelLimiteParental =
          allowedModules > 0 && entry.key >= allowedModules;

      return ModuloInfo(
        id: modulo.id,
        titulo: modulo.titulo,
        estrellas: modulo.estrellas,
        nivel: modulo.nivel,
        imagenPath: modulo.imagenPath,
        lvlBackgroundImageUrl: modulo.lvlBackgroundImageUrl,
        color: modulo.color,
        bloqueado: modulo.bloqueado || fueraDelLimiteParental,
        descripcion: modulo.descripcion,
        nivelesCompletados: modulo.nivelesCompletados,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          /// Header con información del usuario
          _buildUserHeader(context),

          /// Grid de módulos
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 5 / 8,
                crossAxisSpacing: 7,
                mainAxisSpacing: 7,
              ),
              itemCount: filteredModules.length,
              itemBuilder: (context, index) {
                return ModuloPlantilla(modulo: filteredModules[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el header con información del usuario
  Widget _buildUserHeader(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: colors.headerGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: colors.surfaceBorder),
            ),
            child: Image.asset(
              'assets/images/presets/appy_head_happy_preset.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡HOLA!',
                  style: TextStyle(
                    color: colors.inkSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nombreUsuario,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 22,
                    color: colors.ink,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: colors.accent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'NIVEL ${max(1, nivelUsuario)}',
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget que representa una tarjeta individual de módulo.
/// Muestra toda la información del módulo y cambia su apariencia según el estado.
class ModuloPlantilla extends StatelessWidget {
  final ModuloInfo modulo;

  const ModuloPlantilla({super.key, required this.modulo});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      // Iniciar prefetch de niveles cuando el dedo toca la tarjeta (antes de soltar)
      // así los datos ya están cargándose mientras dura el gesto de toque
      onTapDown: (_) {
        if (!modulo.bloqueado) {
          final learningViewModel = context.read<LearningViewModel>();
          learningViewModel.prefetchModuleLevels(modulo.id);
        }
      },
      onTap: () {
        if (!modulo.bloqueado) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LevelTimelineScreen(
                moduleId: modulo.id,
                backgroundImagePath: modulo.lvlBackgroundImageUrl,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.surfaceBorder),
        ),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
          child: Column(
            children: [
              /// Imagen del módulo con overlays
              Expanded(
                child: Stack(
                  children: [
                    _buildModuleImage(colors),
                    if (modulo.bloqueado) _buildLockedOverlay(),
                    _buildLevelBadge(colors),
                    _buildStarsIndicator(colors),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              /// Botón del título
              _buildTitleButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la imagen del módulo
  Widget _buildModuleImage(AppColors colors) {
    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: modulo.color,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: colors.surfaceBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: Image.asset(modulo.imagenPath, fit: BoxFit.contain),
        ),
      ),
    );
  }

  /// Construye el overlay cuando está bloqueado
  Widget _buildLockedOverlay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.input),
        color: const Color(0x99000000),
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: const Icon(
            Icons.lock_rounded,
            size: 34,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  /// Construye el badge del nivel
  Widget _buildLevelBadge(AppColors colors) {
    return Positioned(
      top: 6,
      left: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          'NV ${modulo.nivelesCompletados}',
          style: TextStyle(
            color: colors.ink,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Construye el indicador de estrellas
  Widget _buildStarsIndicator(AppColors colors) {
    return Positioned(
      top: 6,
      right: 6,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final isRellena = index < modulo.estrellas;
          return Icon(
            Icons.star_rounded,
            size: 18,
            color: isRellena ? const Color(0xFFF2B233) : colors.surfaceBorder,
          );
        }),
      ),
    );
  }

  /// Construye el botón del título.
  /// IgnorePointer deja pasar el toque al GestureDetector de la tarjeta; el
  /// botón solo aporta el estilo del tema (y el estado deshabilitado si está
  /// bloqueado).
  Widget _buildTitleButton() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: modulo.bloqueado
                    ? const [Color(0xFF5A6B7A), Color(0xFF3E4B5A)]
                    : const [Color(0xFF92C5BC), Color(0xFF5A97B8)],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: modulo.bloqueado
                    ? const Color(0xFF6B7B8C)
                    : const Color(0xFFB0D9D1),
                width: 2,
              ),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x4DFFFFFF),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                  spreadRadius: 0,
                ),
                if (!modulo.bloqueado)
                  const BoxShadow(
                    color: Color(0x665A97B8),
                    blurRadius: 15,
                    offset: Offset(0, 0),
                    spreadRadius: 1,
                  ),
                const BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                modulo.titulo,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: modulo.bloqueado
                      ? const Color(0x80FFFFFF)
                      : Colors.white,
                  letterSpacing: 1.5,
                  shadows: const [
                    Shadow(
                      color: Color(0x66000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton / shimmer widgets shown while modules are loading
// ---------------------------------------------------------------------------
// Widgets de esqueleto / shimmer mostrados mientras los módulos cargan
// ---------------------------------------------------------------------------

/// Animación shimmer base — effecto de pulso barrido sobre el widget [child] dado.
/// Usa un [ShaderMask] con gradiente animado que se desplaza de izquierda a derecha.
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Ciclo de 1.4 segundos que se repite indefinidamente
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    // El gradiente viaja desde el lado izquierdo (-2) hasta el derecho (+2)
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [colors.accentSoft, colors.surface, colors.accentSoft],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Bloque rectangular redondeado que sirve como placeholder genérico.
class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const _SkeletonBox({
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppRadius.input),
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.appColors.accentSoft,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Tarjeta esqueleto que imita la apariencia de [ModuloPlantilla].
class _SkeletonModuleCard extends StatelessWidget {
  const _SkeletonModuleCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        // Semitransparente para que el shimmer distinga la tarjeta de los
        // bloques opacos de su interior.
        color: colors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
        child: Column(
          children: [
            // Placeholder del área de imagen del módulo
            const Expanded(
              child: _SkeletonBox(
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            const SizedBox(height: 8),
            // Placeholder del botón con el título del módulo
            _SkeletonBox(
              width: double.infinity,
              height: 45,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado esqueleto que imita [_buildUserHeader].
class _SkeletonUserHeader extends StatelessWidget {
  const _SkeletonUserHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Row(
        children: [
          // Placeholder del avatar
          const _SkeletonBox(width: 50, height: 50),
          const SizedBox(width: 12),
          // Placeholders del saludo y nombre de usuario
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: 48, height: 12),
                SizedBox(height: 6),
                _SkeletonBox(width: 120, height: 22),
              ],
            ),
          ),
          // Placeholder de la insignia de nivel
          _SkeletonBox(
            width: 90,
            height: 32,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ],
      ),
    );
  }
}

/// Diseño completo del esqueleto que replica la estructura de [ModulosGridView].
/// Envuelve todo en [_Shimmer] para la animación y muestra 6 tarjetas placeholder.
class _ModuleListSkeleton extends StatelessWidget {
  const _ModuleListSkeleton();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Encabezado con datos del usuario
            const _SkeletonUserHeader(),
            // Cuadrícula de tarjetas de módulos
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 5 / 8,
                  crossAxisSpacing: 7,
                  mainAxisSpacing: 7,
                ),
                // La app tiene como máximo 4 módulos, así que el skeleton fija
                // 4 placeholders. La cantidad real no se carga aquí porque el
                // skeleton solo busca llenar la pantalla durante la carga.
                itemCount: 4,
                itemBuilder: (_, __) => const _SkeletonModuleCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
