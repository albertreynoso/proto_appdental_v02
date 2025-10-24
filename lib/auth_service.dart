import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:proto_appdental_v02/onboardingflow/login.dart';
import 'package:proto_appdental_v02/main_app.dart';
import 'package:another_flushbar/flushbar.dart';

class AuthService {
  //Servicio para registrar usuario
  Future<void> signup({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const AppPrincipal(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = '';
      switch (e.code) {
        // REGISTRO - Creación de cuenta
        case 'email-already-in-use':
          message = 'Ya existe una cuenta con este email.';
          break;
        case 'weak-password':
          message =
              'La contraseña es demasiado débil. Use al menos 6 caracteres.';
          break;
        case 'invalid-email':
          message = 'El formato del email no es válido.';
          break;
        case 'operation-not-allowed':
          message = 'El registro con email/contraseña no está habilitado.';
          break;
        default:
          message = 'Ha ocurrido un error. Intente nuevamente.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2), // Exacto 2 segundos
          backgroundColor: Colors.black54,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {}
  }

  //Servicio para iniciar sesión
  Future<void> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const AppPrincipal(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = '';
      switch (e.code) {
        case 'user-not-found':
          message = 'No existe una cuenta con este email.';
          break;
        case 'wrong-password':
          message = 'La contraseña es incorrecta.';
          break;
        case 'invalid-credential':
          message = 'El email ingresado o la contraseña es incorrecta.';
          break;
        case 'user-disabled':
          message = 'Esta cuenta ha sido deshabilitada.';
          break;
        case 'too-many-requests':
          message = 'Demasiados intentos. Intente más tarde.';
          break;
        default:
          message = 'Ha ocurrido un error. Intente nuevamente.';
      }
      mostrarSnackBarSuperior(context, message);  
      
    } catch (e) {}
  }
void mostrarSnackBarSuperior(BuildContext context, String mensaje) {
  Flushbar(
    message: mensaje,
    icon: const Icon(Icons.info_outline, color: Colors.white),
    backgroundColor: Colors.redAccent,
    duration: const Duration(seconds: 2),
    flushbarPosition: FlushbarPosition.TOP,
    margin: const EdgeInsets.all(12),
    borderRadius: BorderRadius.circular(12),
  ).show(context);
}
  Future<void> signout({required BuildContext context}) async {
    await FirebaseAuth.instance.signOut();
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (BuildContext context) => Login()),
    );
  }
}
