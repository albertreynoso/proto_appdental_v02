import 'package:flutter/material.dart';

class AcercaDe extends StatelessWidget {
  const AcercaDe({super.key});

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
          'Acerca de',
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
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCard(
              title: 'ACERCA DE DENTLINK',
              children: [
                _buildInfoRow(
                  icon: Icons.info_outline,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Sistema de gestión dental',
                  subtitle:
                      'Desarrollado a medida para centralizar citas, pacientes y tratamientos en una sola plataforma.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'DESARROLLADO POR',
              children: [
                _buildInfoRow(
                  icon: Icons.code,
                  iconColor: const Color(0xFF71CE06),
                  title: 'Bamboo Dev',
                  subtitle: 'Desarrollo de software a medida',
                ),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                _buildInfoRow(
                  icon: Icons.mail_outline,
                  iconColor: const Color(0xFF71CE06),
                  title: 'Soporte técnico',
                  subtitle: 'soporte@bamboodev.pe',
                  isButton: true,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'LEGAL',
              children: [
                _buildInfoRow(
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFF9E9E9E),
                  title: 'Términos de uso',
                  subtitle: 'Condiciones del servicio',
                  isButton: true,
                  onTap: () {},
                ),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                _buildInfoRow(
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF9E9E9E),
                  title: 'Política de privacidad',
                  subtitle: 'Tratamiento de datos personales',
                  isButton: true,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Hecho con ♥ para tu clínica dental',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
            ),
            const SizedBox(height: 4),
            const Text(
              'v1.0.0 beta',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFFD0D0D0)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
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
        children: [
          const Text(
            'DentLink.',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'v1.0.0 beta',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
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

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isButton = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isButton ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            if (isButton)
              const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD), size: 20),
          ],
        ),
      ),
    );
  }
}
