import 'package:flutter/material.dart';

class PreferenciasNotificaciones extends StatefulWidget {
  const PreferenciasNotificaciones({super.key});

  @override
  State<PreferenciasNotificaciones> createState() =>
      _PreferenciasNotificacionesState();
}

class _PreferenciasNotificacionesState
    extends State<PreferenciasNotificaciones> {
  bool _recordatorioCitas = true;
  bool _nuevaCitaAgendada = true;
  bool _nuevoPaciente = false;

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
          'Notificaciones',
          style: TextStyle(
              color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCard(
              title: 'CITAS',
              children: [
                _buildSwitchTile(
                  icon: Icons.calendar_today_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Recordatorio de citas del día',
                  subtitle: 'Aviso matutino con las citas programadas para hoy',
                  value: _recordatorioCitas,
                  onChanged: (v) => setState(() => _recordatorioCitas = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'ACTIVIDAD',
              children: [
                _buildSwitchTile(
                  icon: Icons.event_available_outlined,
                  iconColor: const Color(0xFF71CE06),
                  title: 'Nueva cita agendada',
                  subtitle: 'Cuando se programa una nueva cita en el sistema',
                  value: _nuevaCitaAgendada,
                  onChanged: (v) => setState(() => _nuevaCitaAgendada = v),
                ),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                _buildSwitchTile(
                  icon: Icons.person_add_outlined,
                  iconColor: const Color(0xFF71CE06),
                  title: 'Nuevo paciente registrado',
                  subtitle: 'Cuando se registra un nuevo paciente',
                  value: _nuevoPaciente,
                  onChanged: (v) => setState(() => _nuevoPaciente = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'MÁS OPCIONES',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            color: Color(0xFFBDBDBD), size: 20),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Próximamente',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFBDBDBD)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Más tipos de notificaciones en camino',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFFBDBDBD)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: Color(0xFFBDBDBD)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Las notificaciones se activarán cuando el sistema de mensajería esté conectado.',
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFFBDBDBD)),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF71CE06),
          ),
        ],
      ),
    );
  }
}
