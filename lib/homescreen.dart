import 'package:flutter/material.dart';
import 'package:proto_appdental_v02/auth_service.dart';
import 'auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false, // Asegúrate de que esté en false
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _construirAppBar(),
      body: Center(child: Text('HomeScreen')),
    );
  }

  /// Construye la barra de aplicación
  PreferredSizeWidget _construirAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white, // Color sólido
          // Puedes agregar un border o boxShadow si quieres una línea o sombra
          boxShadow: [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              // Tu logo o icono
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Image.asset('assets/img/dentlink_logo.png', height: 40),
              ),
              const Text(
                'DentLink',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              // Espacio flexible para empujar el botón a la derecha
              const Spacer(),

              // Botón de cerrar sesión
              IconButton(
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout, color: Colors.black),
                tooltip: 'Cerrar sesión',
              ),
              const SizedBox(width: 8), // Espacio pequeño al final
              // ...otros widgets si necesitas
            ],
          ),
        ),
      ),
    );
  }

  // Función simple para cerrar sesión
  void _cerrarSesion() async {
    // Aquí va tu lógica de cierre de sesión
    await AuthService().signout(context: context);

    // Ejemplo:
    // FirebaseAuth.instance.signOut();
    // Navigator.pushReplacement(...);
  }
}
