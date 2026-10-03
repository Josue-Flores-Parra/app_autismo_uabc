import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

/// Estado de la red del dispositivo; no afirma que Firestore esté disponible.
enum NetworkConnectionStatus { unknown, connected, disconnected }

/// Observa las interfaces activas sin bloquear los diálogos ni consultar servidores.
class NetworkConnectionService extends ChangeNotifier
    with WidgetsBindingObserver {
  NetworkConnectionService({
    Future<List<ConnectivityResult>> Function()? check,
    Stream<List<ConnectivityResult>>? changes,
  }) : _check = check ?? Connectivity().checkConnectivity,
       _changes = changes ?? Connectivity().onConnectivityChanged;

  final Future<List<ConnectivityResult>> Function() _check;
  final Stream<List<ConnectivityResult>> _changes;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  NetworkConnectionStatus _status = NetworkConnectionStatus.unknown;
  int _revision = 0;
  bool _disposed = false;

  NetworkConnectionStatus get status => _status;

  /// Registra cambios antes de leer el estado inicial para no perder reconexiones.
  Future<void> start() async {
    if (_subscription != null || _disposed) return;
    WidgetsBinding.instance.addObserver(this);
    _subscription = _changes.listen(
      _apply,
      onError: (Object error) {
        _revision++;
        _setStatus(NetworkConnectionStatus.unknown);
      },
    );
    await refresh();
  }

  /// Revisa el estado al volver del segundo plano, con una espera acotada.
  Future<void> refresh() async {
    final revision = _revision;
    try {
      final results = await _check().timeout(const Duration(seconds: 2));
      if (!_disposed && revision == _revision) _apply(results);
    } catch (_) {
      if (!_disposed && revision == _revision) {
        _setStatus(NetworkConnectionStatus.unknown);
      }
    }
  }

  void _apply(List<ConnectivityResult> results) {
    _revision++;
    // Wi-Fi, datos móviles y Ethernet cuentan como red; una lectura vacía es desconocida.
    _setStatus(
      results.isEmpty
          ? NetworkConnectionStatus.unknown
          : results.any((result) => result != ConnectivityResult.none)
          ? NetworkConnectionStatus.connected
          : NetworkConnectionStatus.disconnected,
    );
  }

  void _setStatus(NetworkConnectionStatus status) {
    if (_disposed || _status == status) return;
    _status = status;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Oculta un aviso obsoleto hasta comprobar la conexión actual.
      _revision++;
      _setStatus(NetworkConnectionStatus.unknown);
      unawaited(refresh());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
