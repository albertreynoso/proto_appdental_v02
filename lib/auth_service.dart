import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:proto_appdental_v02/onboardingflow/login.dart';
import 'package:proto_appdental_v02/main_app.dart';

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
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
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
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {}
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
