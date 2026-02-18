import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:proto_appdental_v02/core/pin_service.dart';
import 'package:proto_appdental_v02/main_app.dart';
import 'package:proto_appdental_v02/widgets/teclado_pin.dart';

// ══════════════════════════════════════════════════════════════
// ELIGE UNA DE LAS 3 PROPUESTAS DE LOGO ABAJO Y ÚSALA en el
// build() reemplazando el widget _LogoBambooX que prefieras.
// ══════════════════════════════════════════════════════════════

class IngresoPin extends StatefulWidget {
  const IngresoPin({super.key});

  @override
  State<IngresoPin> createState() => _IngresoPinState();
}

class _IngresoPinState extends State<IngresoPin> {
  final _tecladoKey = GlobalKey<TecladoPinState>();

  Future<void> _verificarPin(String pin) async {
    final pinService = PinService();
    final correcto = await pinService.verifyPin(pin);
    if (!mounted) return;
    if (!correcto) {
      _tecladoKey.currentState?.shake();
      return;
    }
    final email = await pinService.getRememberedEmail();
    final password = await pinService.getRememberedPassword();
    if (email != null && password != null) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AppPrincipal()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.black87,
          tooltip: 'Volver',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // ▼ CAMBIA AQUÍ por _LogoBamboo1(), _LogoBamboo2() o _LogoBamboo3()
                const SizedBox(height: 24),
                const _LogoBamboo2(),
                const SizedBox(height: 48),
                const Text(
                  'Ingresa tu PIN de 4 dígitos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),
                TecladoPin(
                  key: _tecladoKey,
                  onCompleted: _verificarPin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PROPUESTA 1 — "Elegante & Contrastante"
//
//   DentLink.          ← negro, pesado, 28px
//   B a m b o o       ← verde sage, itálica delgada, espaciado
//
// Sensación: clínica premium, confianza, sofisticación.
// ══════════════════════════════════════════════════════════════
class _LogoBamboo1 extends StatelessWidget {
  const _LogoBamboo1();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'DentLink.',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Bamboo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            color: Color(0xFF5A8A6A), // verde sage apagado
            letterSpacing: 6,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PROPUESTA 2 — "Moderna & Bold"
//
//   DentLink.          ← gris claro, pequeño, ligero
//   BAMBOO             ← verde bosque, enorme, black weight
//
// Sensación: marca joven, tecnológica, con carácter.
// ══════════════════════════════════════════════════════════════
class _LogoBamboo2 extends StatelessWidget {
  const _LogoBamboo2();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DentLink.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.black45,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'BAMBOO',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2E7D32), // verde bosque
            letterSpacing: -1.5,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PROPUESTA 3 — "Integrada con acento"
//
//   DentLink · Bamboo  ← todo en una línea, separados por un
//                         punto verde menta como acento de color
//
// Sensación: marca consolidada, discreta, profesional.
// ══════════════════════════════════════════════════════════════
class _LogoBamboo3 extends StatelessWidget {
  const _LogoBamboo3();

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'DentLink',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          TextSpan(
            text: ' · ',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: Color(0xFF66BB6A), // verde menta como separador
            ),
          ),
          TextSpan(
            text: 'Bamboo',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: Color(0xFF388E3C), // verde medio
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}