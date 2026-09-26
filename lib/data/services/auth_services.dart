import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_services.dart';
import '../../features/learning_module/data/video_controller_manager.dart';
import '../../features/telemetry/service/activity_telemetry_service.dart';
import '../../shared/services/pin_service.dart';
import '../../features/profiles/data/profile_repository.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final ProfileRepository _profileRepository = ProfileRepository();

  User? get currentUser => _auth.currentUser;

  // Registro con nombre
  Future<User?> register(
    String email,
    String password,
    String name, [
    int? legalVersionAccepted,
  ]) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Guardar información adicional del usuario en Firestore
    if (result.user != null) {
      await result.user!.updateDisplayName(name);

      final userData = <String, dynamic>{
        'name': name,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
        'role': 'parent',
        'profilesInitialized': true,
      };

      if (legalVersionAccepted != null) {
        userData['legal'] = {
          'version': legalVersionAccepted,
          'acceptedAt': DateTime.now().toIso8601String(),
        };
      }

      await _firestoreService.setUserData(result.user!.uid, userData);
      await result.user!.reload();
    }

    return result.user;
  }

  // Login
  Future<User?> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // Logout
  Future<void> logout() async {
    // Cierre best-effort de una sesión de telemetría iniciada mientras el UID
    // sigue autorizado (antes de signOut).
    await ActivityTelemetryService.instance?.closeActiveSessionForLogout();

    // Liberar todos los controladores de video antes de cerrar sesión
    // para evitar fugas de memoria y decodificadores de hardware huérfanos
    VideoControllerManager().disposeAll();
    await _auth.signOut();
  }

  /// Envía un correo de restablecimiento de contraseña a [email].
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<bool> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.updateDisplayName(name);
    await _firestoreService.setUserData(user.uid, {'name': name});
    await user.reload();
    return true;
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final email = user.email;
    if (email == null) return false;
    final cred = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
    return true;
  }

  /// Elimina la cuenta actual.
  ///
  /// Firebase exige una sesión reciente para borrar, así que primero se
  /// reautentica con la contraseña; sin este paso la operación fallaba aunque
  /// el usuario escribiera bien la palabra de confirmación.
  Future<bool> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final email = user.email;
    if (email == null) return false;

    final cred = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(cred);

    // Cierre best-effort de la sesión de telemetría activa mientras el UID
    // sigue autorizado (después de validar la contraseña).
    await ActivityTelemetryService.instance?.closeActiveSessionForLogout();

    await _firestoreService.setUserData(user.uid, {
      'deletedAt': DateTime.now().toIso8601String(),
    });
    await _profileRepository.deleteFamily(user.uid);
    // El PIN vive en el dispositivo: si no se borra aquí, sobrevive a la
    // cuenta y la siguiente no puede definir uno nuevo.
    await PinService.clearPin(user.uid);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('selectedLearner_${user.uid}');
    await preferences.remove('sendMetrics_${user.uid}');
    await preferences.remove('telemetryOnboardingShown_${user.uid}');
    VideoControllerManager().disposeAll();
    await user.delete();
    return true;
  }
}
