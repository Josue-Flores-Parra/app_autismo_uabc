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
  bool _registrationSuccess = false;
  String? _lastRegisteredUid;

  AuthViewModel() {
    _currentUser = _authService.currentUser;
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get registrationSuccess => _registrationSuccess;

  /// UID de la última cuenta creada (válido aunque el registro haga logout).
  String? get lastRegisteredUid => _lastRegisteredUid;

  /// Limpia la bandera de registro exitoso tras haber mostrado el cue.
  void clearRegistrationSuccess() {
    _registrationSuccess = false;
    notifyListeners();
  }

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
      _reportUnexpected(
        e,
        'No pudimos completar la operación. Inténtalo de nuevo en un momento.',
      );
      return false;
    }
  }

  /// Registra un nuevo usuario con email, contraseña y nombre
  Future<bool> register(
    String email,
    String password,
    String name, [
    int? legalVersionAccepted,
  ]) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.register(
        email,
        password,
        name,
        legalVersionAccepted,
      );
      _lastRegisteredUid = user?.uid;
      // Registro exitoso: cerrar la sesión que Firebase abre automáticamente
      // para que el usuario inicie sesión
      // manualmente. AuthGate permanece en LoginScreen y muestra el cue.
      await _authService.logout();
      _currentUser = null;
      _registrationSuccess = true;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setLoading(false);
      _reportUnexpected(
        e,
        'No pudimos completar la operación. Inténtalo de nuevo en un momento.',
      );
      return false;
    }
  }

  /// Solicita el envío de un correo de restablecimiento de contraseña.
  /// Devuelve `true` incluso si el correo no existe (mensaje genérico para
  /// evitar enumeración de usuarios). Solo devuelve `false` en errores
  /// inesperados.
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        // No revelar si el correo existe.
        return true;
      }
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setLoading(false);
      _reportUnexpected(
        e,
        'No pudimos completar la operación. Inténtalo de nuevo en un momento.',
      );
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
      _reportUnexpected(e, 'No se pudo cerrar la sesión. Inténtalo de nuevo.');
    }
  }

  /// Maneja los errores de FirebaseAuth y los convierte a mensajes legibles
  void _handleAuthError(FirebaseAuthException e) {
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
      case 'network-request-failed':
        _setError('Sin conexión. Revisa tu internet e inténtalo de nuevo.');
        break;
      case 'too-many-requests':
        _setError(
          'Demasiados intentos seguidos. Espera un momento y vuelve a intentarlo.',
        );
        break;
      case 'requires-recent-login':
        _setError(
          'Por seguridad, vuelve a iniciar sesión antes de hacer este cambio.',
        );
        break;
      default:
        // El código y el mensaje de Firebase describen plomería interna
        // ("channel-error", nombres de canales pigeon) que no significan nada
        // para una madre o un padre. Se quedan en el log de depuración.
        debugPrint('FirebaseAuthException ${e.code}: ${e.message}');
        _setError(
          'No pudimos completar la operación. Inténtalo de nuevo en un momento.',
        );
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

  /// Muestra un mensaje entendible y deja el detalle técnico solo en el log.
  ///
  /// Las excepciones de los plugins traen nombres de canales y clases internas
  /// que no ayudan a quien usa la app y dan mala impresión en pantalla.
  void _reportUnexpected(Object error, String message) {
    debugPrint('AuthViewModel: $error');
    _setError(message);
  }

  /// Limpia el mensaje de error manualmente
  void clearError() {
    _clearError();
  }

  Future<bool> updateDisplayName(String name) async {
    _setLoading(true);
    try {
      final updated = await _authService.updateDisplayName(name);
      await _refreshUser();
      _setLoading(false);
      return updated;
    } catch (e) {
      _setLoading(false);
      _reportUnexpected(e, 'No se pudo actualizar el nombre.');
      return false;
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setLoading(true);
    try {
      final updated = await _authService.changePassword(
        currentPassword,
        newPassword,
      );
      _setLoading(false);
      return updated;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setLoading(false);
      _reportUnexpected(e, 'No se pudo actualizar la contraseña.');
      return false;
    }
  }

  Future<bool> deleteAccount(String password) async {
    _setLoading(true);
    try {
      final deleted = await _authService.deleteAccount(password);
      _currentUser = null;
      _setLoading(false);
      return deleted;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setLoading(false);
      _reportUnexpected(e, 'No se pudo eliminar la cuenta.');
      return false;
    }
  }

  Future<void> _refreshUser() async {
    await _authService.currentUser?.reload();
    _currentUser = _authService.currentUser;
    notifyListeners();
  }
}
