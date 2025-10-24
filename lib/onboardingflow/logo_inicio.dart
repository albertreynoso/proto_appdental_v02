import 'package:flutter/material.dart';
import 'package:proto_appdental_v02/onboardingflow/login.dart';

class LogoInicio extends StatefulWidget {
  const LogoInicio({super.key});

  @override
  State<LogoInicio> createState() => _LogoInicioState();
}

class _LogoInicioState extends State<LogoInicio> {
  @override
  void initState() {
    super.initState();
    _navigateToSignIn();
  }

  void _navigateToSignIn() {
    // Esperar 2 segundos y navegar a SignIn
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // o el color de tu marca
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tu logo
            Image.asset(
              'assets/img/dentlink_logo.png',
              height: 120,
            ),
            const SizedBox(height: 20),
            // Texto opcional
            const Text(
              'DentLink',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            // Loading indicator opcional
            /* const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ), */
          ],
        ),
      ),
    );
  }
}