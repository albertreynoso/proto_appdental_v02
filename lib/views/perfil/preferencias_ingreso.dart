import 'package:flutter/material.dart';
import 'package:proto_appdental_v02/core/pin_service.dart';
import 'package:proto_appdental_v02/views/auth/configurar_pin.dart';

class PreferenciasIngreso extends StatefulWidget {
  const PreferenciasIngreso({super.key});

  @override
  State<PreferenciasIngreso> createState() => _PreferenciasIngresoState();
}

class _PreferenciasIngresoState extends State<PreferenciasIngreso> {
  bool _pinActivo = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  Future<void> _cargarEstado() async {
    final activo = await PinService().hasPinConfigured();
    if (mounted) {
      setState(() {
        _pinActivo = activo;
        _loading = false;
      });
    }
  }

  Future<void> _onSwitchChanged(bool value) async {
    if (value) {
      final resultado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const ConfigurarPin()),
      );
      if (mounted) {
        setState(() => _pinActivo = resultado == true);
      }
    } else {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Desactivar PIN'),
          content: const Text(
              '¿Estás seguro de que quieres desactivar el acceso con PIN?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Desactivar',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
      if (confirmar == true) {
        await PinService().clearPin();
        if (mounted) setState(() => _pinActivo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Preferencias de ingreso',
          style: TextStyle(
              color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCard(
                    title: 'SEGURIDAD',
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _pinActivo
                                    ? const Color(0xFF71CE06)
                                        .withValues(alpha: 0.1)
                                    : const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.pin_outlined,
                                color: _pinActivo
                                    ? const Color(0xFF71CE06)
                                    : const Color(0xFF9E9E9E),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Acceso con PIN',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Ingresa con un PIN de 4 dígitos sin escribir tu contraseña.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9E9E9E)),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _pinActivo,
                              onChanged: _onSwitchChanged,
                              activeTrackColor: const Color(0xFF71CE06),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: Color(0xFFBDBDBD)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _pinActivo
                              ? 'El PIN está activo. Se pedirá al abrir la app.'
                              : 'Activa el PIN para un acceso más rápido y seguro.',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFFBDBDBD)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9E9E9E),
                letterSpacing: 0.8,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ...children,
        ],
      ),
    );
  }
}
