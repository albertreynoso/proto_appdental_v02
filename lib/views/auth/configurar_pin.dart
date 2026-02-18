import 'package:flutter/material.dart';
import 'package:proto_appdental_v02/core/pin_service.dart';
import 'package:proto_appdental_v02/widgets/teclado_pin.dart';

class ConfigurarPin extends StatefulWidget {
  const ConfigurarPin({super.key});

  @override
  State<ConfigurarPin> createState() => _ConfigurarPinState();
}

class _ConfigurarPinState extends State<ConfigurarPin> {
  final _tecladoKey = GlobalKey<TecladoPinState>();
  String? _primerPin;
  int _paso = 1; // 1 = crear, 2 = confirmar

  Future<void> _manejarPin(String pin) async {
    if (_paso == 1) {
      setState(() {
        _primerPin = pin;
        _paso = 2;
      });
      _tecladoKey.currentState?.reset();
    } else {
      if (pin == _primerPin) {
        await PinService().savePin(pin);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PIN configurado correctamente'),
            backgroundColor: const Color(0xFF71CE06),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      } else {
        _tecladoKey.currentState?.shake();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _paso = 1;
              _primerPin = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Los PINs no coinciden. Intenta de nuevo.'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Column(
                  key: ValueKey(_paso),
                  children: [
                    Text(
                      _paso == 1 ? 'Crea tu PIN' : 'Confirma tu PIN',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _paso == 1
                          ? 'Elige un PIN de 4 dígitos para acceder rápidamente.'
                          : 'Ingresa el mismo PIN para confirmar.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6A6A6A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildPasoIndicador(),
              const SizedBox(height: 40),
              TecladoPin(
                key: _tecladoKey,
                onCompleted: _manejarPin,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasoIndicador() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final activo = i + 1 == _paso;
        final completado = i + 1 < _paso;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: activo ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: completado || activo
                ? const Color(0xFF71CE06)
                : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
