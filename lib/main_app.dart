import 'package:flutter/material.dart';
import 'package:proto_appdental_v02/views/calendario/calendario_screen.dart';
import 'package:proto_appdental_v02/views/pacientes/clientes_screen.dart';
import 'package:proto_appdental_v02/views/home/home_screen.dart';

class AppPrincipal extends StatefulWidget {
  const AppPrincipal({super.key});

  @override
  State<AppPrincipal> createState() => _AppPrincipalState();
}

class _AppPrincipalState extends State<AppPrincipal> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ClientesScreen(),
    CalendarioScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene los tres estados vivos en memoria.
      // Solo cambia cuál es visible — ninguno se destruye al cambiar de tab.
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(icon: Icons.home, label: 'Principal', index: 0),
            _buildCenterButton(),
            _buildNavItem(icon: Icons.people, label: 'Clientes', index: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? const Color.fromARGB(255, 113, 206, 6) : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color.fromARGB(255, 113, 206, 6) : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: Container(
        transform: Matrix4.translationValues(0, -18, 0),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 113, 206, 6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 118, 119, 119).withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.calendar_today_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
