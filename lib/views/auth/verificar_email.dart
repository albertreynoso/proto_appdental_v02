import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:proto_appdental_v02/views/auth/perfil_nuevo_usuario.dart';
import 'package:proto_appdental_v02/core/auth_service.dart';

class VerificarEmail extends StatefulWidget {
  final String email;
  const VerificarEmail({super.key, required this.email});

  @override
  State<VerificarEmail> createState() => _VerificarEmailState();
}

class _VerificarEmailState extends State<VerificarEmail> {
  bool _checking = false;
  bool _resending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await FirebaseAuth.instance.currentUser?.reload();
      if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
        _timer?.cancel();
        if (mounted) _navigateToProfile();
      }
    });
  }

  Future<void> _checkVerification() async {
    setState(() => _checking = true);
    await FirebaseAuth.instance.currentUser?.reload();
    if (!mounted) return;
    setState(() => _checking = false);
    if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
      _navigateToProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tu correo aún no ha sido verificado.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _resending = true);
    await AuthService().sendVerificationEmail();
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Correo de verificación reenviado.'),
        backgroundColor: const Color(0xFF71CE06),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PerfilNuevoUsuario()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: Color(0xFF71CE06),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verifica tu correo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enviamos un enlace de verificación a\n${widget.email}\n\nRevisá tu bandeja de entrada y haz clic en el enlace.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6A6A6A),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _checking ? null : _checkVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF71CE06),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Ya verifiqué',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resending ? null : _resendEmail,
                child: Text(
                  _resending ? 'Reenviando...' : 'Reenviar correo',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
