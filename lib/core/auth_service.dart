import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  bool get isEmailVerified =>
      FirebaseAuth.instance.currentUser?.emailVerified ?? false;

  Future<void> sendVerificationEmail() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();
  }

  Future<void> saveUserProfile({required Map<String, dynamic> data}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .set({...data, 'estado': 'pending', 'creadoEn': FieldValue.serverTimestamp()});
  }


  Future<String?> signup({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'email-already-in-use' => 'Ya existe una cuenta con este email.',
        'weak-password' => 'La contraseña es demasiado débil. Use al menos 6 caracteres.',
        'invalid-email' => 'El formato del email no es válido.',
        'operation-not-allowed' => 'El registro con email/contraseña no está habilitado.',
        _ => 'Ha ocurrido un error. Intente nuevamente.',
      };
    }
  }

  Future<String?> signin({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user?.emailVerified == false) {
        return 'email-not-verified';
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'user-not-found' => 'No existe una cuenta con este email.',
        'wrong-password' => 'La contraseña es incorrecta.',
        'invalid-credential' => 'El email ingresado o la contraseña es incorrecta.',
        'user-disabled' => 'Esta cuenta ha sido deshabilitada.',
        'too-many-requests' => 'Demasiados intentos. Intente más tarde.',
        _ => 'Ha ocurrido un error. Intente nuevamente.',
      };
    }
  }

  Future<void> signout() async {
    await FirebaseAuth.instance.signOut();
  }
}
