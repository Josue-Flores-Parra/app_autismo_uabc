import 'package:flutter/material.dart';

/// Servicio global para manejar el estado de carga
class LoadingService extends ChangeNotifier {
  bool _isLoading = false;
  String? _loadingMessage;

  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;

  /// Mostrar pantalla de carga
  void showLoading([String? message]) {
    _isLoading = true;
    _loadingMessage = message;
    notifyListeners();
  }

  /// Ocultar pantalla de carga
  void hideLoading() {
    _isLoading = false;
    _loadingMessage = null;
    notifyListeners();
  }

  /// Mostrar carga con mensaje específico
  void showLoadingWithMessage(String message) {
    showLoading(message);
  }
}
