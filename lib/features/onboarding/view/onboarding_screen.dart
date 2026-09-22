import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../shared/services/haptics_service.dart';
import '../../settings/viewmodel/settings_viewmodel.dart';
import '../data/onboarding_service.dart';
import 'widgets/animated_entrance.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  static const int _pageCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingService.markSeen();
    widget.onFinished();
  }

  void _next() {
    HapticsService.selection();
    if (_page >= _pageCount - 1) {
      _finish();
      return;
    }
    final reduceMotion = context.read<SettingsViewModel>().reduceAnimations;
    if (reduceMotion) {
      _controller.jumpToPage(_page + 1);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isLast = _page == _pageCount - 1;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.backgroundGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: _SoftBlobs()),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context),
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      onPageChanged: (index) => setState(() => _page = index),
                      children: const [
                        _WelcomePage(),
                        _LearningPage(),
                        _CompanionPage(),
                        _FamilyPage(),
                      ],
                    ),
                  ),
                  _buildBottomBar(context, isLast),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(_pageCount, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  margin: const EdgeInsets.only(right: 6),
                  width: active ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? colors.accent : colors.surfaceBorder,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                );
              }),
            ),
          ),
          TextButton(
            onPressed: _finish,
            child: const Text(
              'Saltar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isLast) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _next,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            elevation: 4,
          ),
          child: Text(
            isLast ? '¡Empezar!' : 'Siguiente',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _SoftBlobs extends StatelessWidget {
  const _SoftBlobs();
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent.withValues(alpha: 0.15),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent.withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = AppRadius.sheet,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Liquid Glass Effect
    final fill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.45);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.6),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.15 : 0.6),
                Colors.white.withValues(alpha: 0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.ink.withValues(alpha: 0.05),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;

  const _Tag({required this.icon, required this.label, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tint, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: tint,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Art extends StatelessWidget {
  final String asset;
  final Alignment alignment;
  const _Art(this.asset, {this.alignment = Alignment.center});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: alignment,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _Copy extends StatelessWidget {
  final String kicker;
  final String title;
  final String body;
  final List<Widget> tags;

  const _Copy({
    required this.kicker,
    required this.title,
    required this.body,
    this.tags = const [],
  });

  List<TextSpan> _parseBody(
    String text,
    Color baseColor,
    Color highlightColor,
  ) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        spans.add(
          TextSpan(
            text: parts[i],
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: highlightColor,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: parts[i],
            style: TextStyle(color: baseColor),
          ),
        );
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _Glass(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedEntrance(
            delay: const Duration(milliseconds: 100),
            child: Text(
              kicker.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: colors.accent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedEntrance(
            delay: const Duration(milliseconds: 200),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 32,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedEntrance(
            delay: const Duration(milliseconds: 300),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                children: _parseBody(body, colors.inkSoft, colors.ink),
              ),
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 400),
              child: Wrap(children: tags),
            ),
          ],
        ],
      ),
    );
  }
}

class _Scene extends StatelessWidget {
  final Widget art;
  final _Copy copy;

  const _Scene({required this.art, required this.copy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 20),
                  child: FloatingAnimation(
                    magnitude: 12.0,
                    duration: const Duration(seconds: 4),
                    child: art,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Transform.translate(
              offset: const Offset(0, -40), // Overlaps the image
              child: Align(alignment: Alignment.topLeft, child: copy),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();
  @override
  Widget build(BuildContext context) {
    return const _Scene(
      art: _Art('assets/images/presets/appy_happy_preset.png'),
      copy: _Copy(
        kicker: 'Bienvenida',
        title: 'Hola, soy Appy',
        body:
            'Te acompaño a aprender las rutinas de cada día, **paso a paso** y **a tu ritmo**.',
        tags: [
          _Tag(
            icon: Icons.soap_rounded,
            label: 'Higiene',
            tint: Color(0xFF4A90E2),
          ),
          _Tag(
            icon: Icons.restaurant_rounded,
            label: 'Alimentación',
            tint: Color(0xFFE0972A),
          ),
        ],
      ),
    );
  }
}

class _LearningPage extends StatelessWidget {
  const _LearningPage();
  @override
  Widget build(BuildContext context) {
    return const _Scene(
      art: _Art('assets/images/presets/appy_tablet_preset.png'),
      copy: _Copy(
        kicker: 'Aprender',
        title: 'Formas de aprender',
        body:
            'Cada paso se ve en **video**, se repasa con **pictogramas** y se practica con un **minijuego** interactivo.',
        tags: [
          _Tag(
            icon: Icons.play_arrow_rounded,
            label: 'Video',
            tint: Color(0xFF4A90E2),
          ),
          _Tag(
            icon: Icons.extension_rounded,
            label: 'Minijuego',
            tint: Color(0xFFE0972A),
          ),
        ],
      ),
    );
  }
}

class _CompanionPage extends StatelessWidget {
  const _CompanionPage();
  @override
  Widget build(BuildContext context) {
    return const _Scene(
      art: _Art('assets/images/presets/appy_cooking_preset.png'),
      copy: _Copy(
        kicker: 'Tu companero',
        title: 'Cuida a Appy',
        body:
            'Al completar pasos ganas **monedas** y Appy se pone **muy contento**.',
        tags: [
          _Tag(
            icon: Icons.monetization_on_rounded,
            label: 'Monedas',
            tint: Color(0xFFF2B233),
          ),
          _Tag(
            icon: Icons.bolt_rounded,
            label: 'Energia',
            tint: Color(0xFF4A90E2),
          ),
        ],
      ),
    );
  }
}

class _FamilyPage extends StatelessWidget {
  const _FamilyPage();
  @override
  Widget build(BuildContext context) {
    return const _Scene(
      art: _Art(
        'assets/images/presets/appy_peeking_preset.png',
        alignment: Alignment.bottomCenter,
      ),
      copy: _Copy(
        kicker: 'Para la familia',
        title: 'Con calma y control',
        body:
            'Los ajustes quedan protegidos por un **PIN** y el avance se **guarda** automáticamente.',
        tags: [
          _Tag(
            icon: Icons.lock_outline_rounded,
            label: 'PIN parental',
            tint: Color(0xFF4A90E2),
          ),
        ],
      ),
    );
  }
}
