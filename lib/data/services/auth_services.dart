import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Registro con nombre
  Future<User?> register(String email, String password, String name) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Guardar información adicional del usuario en Firestore
    if (result.user != null) {
      await _firestoreService.setUserData(result.user!.uid, {
        'name': name,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
      });
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
}
