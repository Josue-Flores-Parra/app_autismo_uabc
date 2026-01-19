import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;

  // Registro con nombre
  Future<User?> register(String email, String password, String name) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Guardar información adicional del usuario en Firestore
    if (result.user != null) {
      await result.user!.updateDisplayName(name);
      await _firestoreService.setUserData(result.user!.uid, {
        'name': name,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
      });
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
    await _auth.signOut();
  }

  Future<bool> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.updateDisplayName(name);
    await _firestoreService.setUserData(user.uid, {'name': name});
    await user.reload();
    return true;
  }

  Future<bool> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.updatePassword(newPassword);
    return true;
  }

  Future<bool> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await _firestoreService.setUserData(user.uid, {
      'deletedAt': DateTime.now().toIso8601String(),
    });
    await user.delete();
    return true;
  }
}
