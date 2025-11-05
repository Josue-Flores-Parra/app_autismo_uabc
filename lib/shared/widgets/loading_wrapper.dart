import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/loading_service.dart';
import 'loading_screen.dart';

/// Widget wrapper que maneja automáticamente la pantalla de carga
class LoadingWrapper extends StatelessWidget {
  final Widget child;

  const LoadingWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LoadingService>(
      builder: (context, loadingService, _) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              child, // La aplicación principal
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: Tween<double>(
                      begin: 0.0,
                      end: 1.0,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    )),
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.9,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                child: loadingService.isLoading
                    ? Container(
                        key: const ValueKey('loading'),
                        color: Colors.black.withValues(alpha: 0.5),
                        child: Center(
                          child: LoadingScreen(
                            message: loadingService.loadingMessage,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Hook para usar el servicio de carga fácilmente
class LoadingHook {
  static LoadingService of(BuildContext context) {
    return Provider.of<LoadingService>(context, listen: false);
  }

  /// Mostrar carga
  static void show(BuildContext context, [String? message]) {
    of(context).showLoading(message);
  }

  /// Ocultar carga
  static void hide(BuildContext context) {
    of(context).hideLoading();
  }

  /// Mostrar carga con mensaje
  static void showWithMessage(BuildContext context, String message) {
    of(context).showLoadingWithMessage(message);
  }
}
