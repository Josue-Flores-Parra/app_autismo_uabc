import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/auth_services.dart';

/// ViewModel para manejar la autenticación de usuarios
/// Gestiona los estados de carga, errores y llamadas al servicio de autenticación
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  /// Inicia sesión con email y contraseña
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.login(email, password);
      _currentUser = user;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Error inesperado: ${e.toString()}');
      return false;
    }
  }

  /// Registra un nuevo usuario con email, contraseña y nombre
  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.register(email, password, name);
      _currentUser = user;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Error inesperado: ${e.toString()}');
      return false;
    }
  }

  /// Cierra la sesión del usuario actual
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _currentUser = null;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Error al cerrar sesión: ${e.toString()}');
    }
  }

  /// Maneja los errores de FirebaseAuth y los convierte a mensajes legibles
  void _handleAuthError(FirebaseAuthException e) {
    // Debug: imprimir el código de error para diagnóstico
    debugPrint('Firebase Auth Error Code: ${e.code}');
    debugPrint('Firebase Auth Error Message: ${e.message}');

    switch (e.code) {
      case 'user-not-found':
        _setError('No existe una cuenta con este correo electrónico');
        break;
      case 'wrong-password':
        _setError('Contraseña incorrecta');
        break;
      case 'email-already-in-use':
        _setError('Este correo electrónico ya está en uso');
        break;
      case 'weak-password':
        _setError('La contraseña es demasiado débil');
        break;
      case 'invalid-email':
        _setError('El correo electrónico no es válido');
        break;
      case 'invalid-credential':
        _setError('Credenciales inválidas. Verifica tu correo y contraseña');
        break;
      case 'operation-not-allowed':
        _setError(
          'La autenticación por email/contraseña no está habilitada. Por favor contacta al administrador.',
        );
        break;
      default:
        _setError('Error de autenticación (${e.code}): ${e.message}');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpia el mensaje de error manualmente
  void clearError() {
    _clearError();
  }
}
