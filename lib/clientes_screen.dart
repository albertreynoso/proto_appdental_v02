import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'clientes_detalle.dart';
//import 'empleadosform_screen.dart';
//import 'empleadoseditar_screen.dart';

/// Pantalla principal para la gestión de empleados de clínica dental
///
/// Permite visualizar, crear, editar y eliminar empleados
/// Integra con Firebase Firestore para el almacenamiento de datos
class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

/// Estado de la pantalla de empleados
class _ClientesScreenState extends State<ClientesScreen> {
  // ========== VARIABLES DE ESTADO ==========

  /// Lista de pacientes obtenidos de Firestore
  List<Map<String, dynamic>> _pacientes = [];

  /// Indica si los datos están siendo cargados
  bool _isLoading = true;

  /// Referencia a la colección de pacientes en Firestore
  static const String _collectionName = 'pacientes';

  // ========== CICLO DE VIDA DEL WIDGET ==========

  @override
  void initState() {
    super.initState();
    _cargarPacientes();
  }

  // ========== MÉTODOS DE DATOS ==========

  /// Carga la lista de pacientes desde Firestore
  Future<void> _cargarPacientes() async {
    try {
      setState(() => _isLoading = true);

      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .orderBy('apellido_paterno', descending: true)
          .get();

      final List<Map<String, dynamic>> pacientesList = snapshot.docs
          .map(
            (DocumentSnapshot doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            },
          )
          .toList();

      if (mounted) {
        setState(() {
          _pacientes = pacientesList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarMensajeError('Error al cargar pacientes: $e');
      }
    }
  }

  // ========== MÉTODOS DE UI ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false, // Asegúrate de que esté en false
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _construirAppBar(),
      body: _buildBody(_pacientes),
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
              // ...otros widgets si necesitas
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el cuerpo principal de la pantalla
  Widget _buildBody(List<Map<String, dynamic>> pacientesFiltrados) {
    return Column(
      children: [
        // Lista de pacientes
        Expanded(child: _buildListaPacientes(pacientesFiltrados)),
      ],
    );
  }

  /// Construye la lista de pacientes
  Widget _buildListaPacientes(List<Map<String, dynamic>> pacientesFiltrados) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (pacientesFiltrados.isEmpty) {
      return _buildEmptyStateWidget();
    }

    return RefreshIndicator(
      onRefresh: _cargarPacientes,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: pacientesFiltrados.length,
        itemBuilder: (context, index) {
          final paciente = pacientesFiltrados[index];
          return _construirPacienteCard(paciente);
        },
      ),
    );
  }

  /// Widget de carga
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Cargando pacientes...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Widget para estado vacío
  Widget _buildEmptyStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay pacientes registrados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPacienteCard(Map<String, dynamic> paciente) {
    final bool isActive = paciente['activo'] ?? true;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar/Icono del paciente
            _buildAvatarPaciente(),

            const SizedBox(width: 12),

            // Información del paciente - MODIFICADO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre completo (primer nombre + primer apellido)
                  Text(
                    _obtenerNombreCompletoCorto(paciente),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // DNI paciente
                  Row(
                    children: [
                      Icon(Icons.badge, size: 16, color: Colors.grey[700]),
                      Text(
                        ' DNI: ${paciente['dni'] ?? 'No especificado'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color.fromARGB(255, 58, 37, 37),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Estado activo/inactivo
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.grey[600],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActive ? 'Con tratamiento' : 'Sin tratamiento',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isActive ? Colors.green : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Acciones
            _buildAccionesColumn(paciente),
          ],
        ),
      ),
    );
  }

  /// Construye el avatar/icono del paciente
  Widget _buildAvatarPaciente() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: Icon(Icons.person, color: Colors.white, size: 24),
    );
  }

  /// Construye la columna de acciones (editar y eliminar)
  Widget _buildAccionesColumn(Map<String, dynamic> paciente) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_construirBotonDetalle(paciente)],
    );
  }

  Widget _construirBotonDetalle(Map<String, dynamic> paciente) {
    return IconButton(
      onPressed: () {
        print('🚀 Intentando navegar...');
        
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClientesDetalle(paciente: paciente),
            ),
          );
          print('✅ Navegación exitosa');
        } catch (e) {
          print('❌ ERROR: $e');
          // Fallback seguro
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Error - Usando fallback')),
                body: const Center(
                  child: Text('Hubo un error, pero esto es seguro'),
                ),
              ),
            ),
          );
        } 
      },
      icon: const Icon(Icons.chevron_right, color: Colors.grey, size: 26),
    );
  }

  // ========== MÉTODOS DE UTILIDAD ==========

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Método auxiliar para obtener nombre corto (primer nombre + primer apellido)
  String _obtenerNombreCompletoCorto(Map<String, dynamic> paciente) {
    final String nombreCompleto =
        paciente['nombre_completo'] ??
        '${paciente['nombres']} ${paciente['apellido_paterno']}' ??
        'Nombre no disponible';

    // Dividir el nombre completo en partes
    final partesNombre = nombreCompleto.split(' ');

    // Tomar primer nombre y primer apellido
    if (partesNombre.length >= 2) {
      return '${partesNombre[0]} ${partesNombre[1]}';
    } else {
      return partesNombre[0]; // Si solo tiene un nombre
    }
  }

  // ========== MÉTODOS DE DIÁLOGOS Y MENSAJES ==========

  /// Muestra un mensaje de error
  void _mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: _cargarPacientes,
        ),
      ),
    );
  }

  /// Muestra un mensaje de éxito
  void _mostrarMensajeExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
