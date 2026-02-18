import 'package:flutter/material.dart';
import 'package:proto_appdental_v02/core/pin_service.dart';
import 'package:proto_appdental_v02/views/auth/ingreso_pin.dart';
import 'package:proto_appdental_v02/views/auth/login.dart';

class LoginConPin extends StatefulWidget {
  const LoginConPin({super.key});

  @override
  State<LoginConPin> createState() => _LoginConPinState();
}

class _LoginConPinState extends State<LoginConPin> {
  String _email = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarEmail();
  }

  Future<void> _cargarEmail() async {
    final email = await PinService().getRememberedEmail();
    if (mounted) {
      setState(() {
        _email = email ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _ingresarConOtraCuenta() async {
    await PinService().clearAll();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 64),
              const Text(
                'DentLink.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const IngresoPin()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ingresar con PIN',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _ingresarConOtraCuenta,
                child: const Text(
                  'Ingresar con otra cuenta',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('o',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                ],
              ),
              const SizedBox(height: 16),
              Tooltip(
                message: 'Próximamente',
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.g_mobiledata, size: 24, color: Colors.grey),
                      SizedBox(width: 10),
                      Text(
                        'Continuar con Google',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
