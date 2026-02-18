import 'package:flutter/material.dart';
import 'package:proto_appdental_v02/core/pin_service.dart';
import 'package:proto_appdental_v02/views/auth/login.dart';
import 'package:proto_appdental_v02/views/auth/login_con_pin.dart';

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

  Future<void> _navigateToSignIn() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final hasPin = await PinService().hasPinConfigured();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => hasPin ? const LoginConPin() : const Login(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/img/dentlink_logo.png', height: 120),
            const SizedBox(height: 20),
            const Text(
              'DentLink',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
