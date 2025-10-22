import 'package:flutter/material.dart';

/// Pantalla de carga con el robot alineado a la derecha
class LoadingScreen extends StatelessWidget {
  final String? message;
  final double avatarScale;

  const LoadingScreen({
    super.key,
    this.message,
    this.avatarScale = 0.65,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Robot pegado al borde derecho
                Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    'assets/images/icon-salute-hidden2x.png',
                    width: 200 * avatarScale,
                    height: 486 * avatarScale,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Indicador de carga con cubitos animados centrados
                _AnimatedDotsLoader(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget de carga overlay que se puede usar sobre otras pantallas
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: LoadingScreen(),
            ),
          ),
      ],
    );
  }
}

/// Widget personalizado para mostrar cubitos animados de carga
class _AnimatedDotsLoader extends StatefulWidget {
  const _AnimatedDotsLoader();

  @override
  State<_AnimatedDotsLoader> createState() => _AnimatedDotsLoaderState();
}

class _AnimatedDotsLoaderState extends State<_AnimatedDotsLoader>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    _startAnimation();
  }

  void _startAnimation() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Transform.translate(
                  offset: Offset(0, _animations[index].value * 20),
                  child: Opacity(
                    opacity: 0.3 + (_animations[index].value * 0.7),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B8DB3),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5B8DB3).withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
