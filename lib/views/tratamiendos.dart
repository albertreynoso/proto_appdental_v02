import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proto_appdental_v02/empleados_detalle_screen.dart';
import 'package:proto_appdental_v02/views/tratamiento_a%C3%B1adir.dart';

class TratamiendosScreen extends StatefulWidget {
  final Map<String, dynamic> paciente;

  const TratamiendosScreen({super.key, required this.paciente});

  @override
  State<TratamiendosScreen> createState() => _TratamiendosScreenState();
}

class _TratamiendosScreenState extends State<TratamiendosScreen> {
  // ========== VARIABLES DE ESTADO ==========

  /// Lista de tratamientos obtenidos de Firestore
  List<Map<String, dynamic>> _tratamientos = [];

  /// Indica si los datos están siendo cargados
  bool _isLoading = true;

  /// Referencia a la colección de tratamientos en Firestore
  static const String _collectionName = 'tratamientos';

  // ========== CICLO DE VIDA DEL WIDGET ==========

  @override
  void initState() {
    super.initState();
    _cargarTratamientos();
  }

  // ========== MÉTODOS DE DATOS ==========

  /// Carga la lista de tratamientos desde Firestore
Future<void> _cargarTratamientos() async {
  try {
    setState(() => _isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection(_collectionName)
        .where('dni_paciente', isEqualTo: widget.paciente['dni_cliente']) // ← Filtro por DNI
        //.orderBy('fecha_creacion', descending: true)
        .get();

    final List<Map<String, dynamic>> tratamientosList = snapshot.docs
        .map(
          (DocumentSnapshot doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          },
        )
        .toList();

    if (mounted) {
      setState(() {
        _tratamientos = tratamientosList;
        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      _mostrarMensajeError('Error al cargar tratamientos: $e');
    }
  }
}

  // ========== MÉTODOS DE UI ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false, // Asegúrate de que esté en false
      backgroundColor: const Color(0xFFF7F7F7),
      body: _buildBody(_tratamientos),
      floatingActionButton: _buildFloatingActionButton(
        context,
        widget.paciente,
      ),
    );
  }

  /// Construye el cuerpo principal de la pantalla
  Widget _buildBody(List<Map<String, dynamic>> tratamientosFiltrados) {
    return Column(
      children: [
        // Lista de tratamientos
        Expanded(child: _buildListaTratamientos(tratamientosFiltrados)),
      ],
    );
  }

  /// Construye la lista de tratamientos
  Widget _buildListaTratamientos(
    List<Map<String, dynamic>> tratamientosFiltrados,
  ) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (tratamientosFiltrados.isEmpty) {
      return _construirWidgetEstadoVacio();
    }

    return RefreshIndicator(
      onRefresh: _cargarTratamientos,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: tratamientosFiltrados.length,
        itemBuilder: (context, index) {
          final tratamiento = tratamientosFiltrados[index];
          return _construirTratamientoCard(tratamiento);
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
            'Cargando tratamientos...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Widget para estado vacío
  Widget _construirWidgetEstadoVacio() {
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
            'No hay tratamientos registrados',
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

  Widget _construirTratamientoCard(Map<String, dynamic> tratamiento) {
    final bool isActive = tratamiento['activo'] ?? true;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar/Icono del tratamiento
            _buildAvatarTratamiento(),

            const SizedBox(width: 12),

            // Información del tratamiento - MODIFICADO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre completo (primer nombre + primer apellido)
                  Text(
                    '${tratamiento['tratamiento'] ?? 'No disponible'}',
                    //_obtenerNombreCompletoCorto(tratamiento),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Estado tratamiento
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      SizedBox(width: 4), // Espacio entre icono y texto
                      Text(
                        ' ${formatearFechaTimestamp(tratamiento['fecha_creacion'])} - ${isActive ? 'Actualidad' : formatearFechaTimestamp(tratamiento['fecha_finalizacion'])}',
                        style: TextStyle(
                          fontSize: 12,
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
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Estado: ${tratamiento['activo'] ? 'Activo' : 'Inactivo'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Acciones
            _buildAccionesColumn(tratamiento),
          ],
        ),
      ),
    );
  }

  /// Construye el avatar/icono del tratamiento
  Widget _buildAvatarTratamiento() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: Icon(Icons.person, color: Colors.white, size: 24),
    );
  }

  /// Construye la columna de acciones (editar y eliminar)
  Widget _buildAccionesColumn(Map<String, dynamic> tratamiento) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_construirBotonDetalle(tratamiento)],
    );
  }

  Widget _construirBotonDetalle(Map<String, dynamic> tratamiento) {
    return IconButton(
      onPressed: () {
        print('🚀 Intentando navegar...');

        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmpleadosDetalle(empleado: tratamiento),
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

  /// Construye el botón flotante para agregar empleado
  Widget _buildFloatingActionButton(
    BuildContext context,
    Map<String, dynamic> paciente,
  ) {
    return FloatingActionButton(
      onPressed: () {
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NuevoTratamiento(paciente: paciente),
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
      }, //_navegarACrearEmpleado,
      tooltip: 'Agregar Tratamiento',
      backgroundColor: Colors.blue,
      child: const Icon(Icons.medical_services, color: Colors.white, size: 25),
    );
  }

  // ========== MÉTODOS DE UTILIDAD ==========

  String formatearFechaTimestamp(Timestamp timestamp) {
  try {
    DateTime fecha = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(fecha);
  } catch (e) {
    return 'Fecha inválida';
  }
}
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
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
          onPressed: _cargarTratamientos,
        ),
      ),
    );
  }
}
