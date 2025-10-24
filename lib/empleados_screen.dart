import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'empleados_detalle_screen.dart';
import 'package:proto_appdental_v02/views/empleado_añadir.dart';
//import 'empleadosform_screen.dart';
//import 'empleadoseditar_screen.dart';

/// Pantalla principal para la gestión de empleados de clínica dental
///
/// Permite visualizar, crear, editar y eliminar empleados
/// Integra con Firebase Firestore para el almacenamiento de datos
class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

/// Estado de la pantalla de empleados
class _EmpleadosScreenState extends State<EmpleadosScreen> {
  // ========== VARIABLES DE ESTADO ==========

  /// Lista de empleados obtenidos de Firestore
  List<Map<String, dynamic>> _empleados = [];

  /// Indica si los datos están siendo cargados
  bool _isLoading = true;

  /// Filtro de tipo de empleado actual
  String _filtroTipo = 'todos';

  /// Referencia a la colección de empleados en Firestore
  static const String _collectionName = 'personal';

  /// Mapa de nombres descriptivos para los tipos de empleado
  static const Map<String, String> _tipoEmpleadoLabels = {
    'odontologo': 'Odontólogo',
    'asistente_dental': 'Asistente Dental',
    'recepcionista': 'Recepcionista',
    'higienista': 'Higienista Dental',
    'administrador': 'Administrador',
  };

  /// Opciones de filtro por tipo de empleado
  static const List<Map<String, String>> _filtrosTipo = [
    {'value': 'todos', 'label': 'Todos'},
    {'value': 'odontologo', 'label': 'Odontólogos'},
    {'value': 'asistente_dental', 'label': 'Asistentes'},
    {'value': 'recepcionista', 'label': 'Recepcionistas'},
    {'value': 'higienista', 'label': 'Higienistas'},
    {'value': 'administrador', 'label': 'Administradores'},
  ];

  // ========== CICLO DE VIDA DEL WIDGET ==========

  @override
  void initState() {
    super.initState();
    _cargarEmpleados();
  }

  // ========== MÉTODOS DE DATOS ==========

  /// Carga la lista de empleados desde Firestore
  Future<void> _cargarEmpleados() async {
    try {
      setState(() => _isLoading = true);

      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .orderBy('fecha_contratacion', descending: true)
          .get();

      final List<Map<String, dynamic>> empleadosList = snapshot.docs
          .map(
            (DocumentSnapshot doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            },
          )
          .toList();

      if (mounted) {
        setState(() {
          _empleados = empleadosList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarMensajeError('Error al cargar empleados: $e');
      }
    }
  }

  /// Elimina un empleado de Firestore
  Future<void> _eliminarEmpleado(String empleadoId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(empleadoId)
          .delete();

      _mostrarMensajeExito('Empleado eliminado correctamente');
      _cargarEmpleados();
    } catch (e) {
      _mostrarMensajeError('Error al eliminar empleado: $e');
    }
  }

  /// Filtra la lista de empleados según el tipo seleccionado
  List<Map<String, dynamic>> _filtrarEmpleados() {
    if (_filtroTipo == 'todos') {
      return _empleados;
    }

    return _empleados
        .where((empleado) => empleado['tipo_empleado_id'] == _filtroTipo)
        .toList();
  }

  // ========== MÉTODOS DE UI ==========

  @override
  Widget build(BuildContext context) {
    final empleadosFiltrados = _filtrarEmpleados();

    return Scaffold(
      extendBodyBehindAppBar: false, // Asegúrate de que esté en false
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _construirAppBar(),
      body: _buildBody(empleadosFiltrados),
      floatingActionButton: _buildFloatingActionButton(),
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
  Widget _buildBody(List<Map<String, dynamic>> empleadosFiltrados) {
    return Column(
      children: [
        // Filtros
        _construirFiltros(),

        // Lista de empleados
        Expanded(child: _buildListaEmpleados(empleadosFiltrados)),
      ],
    );
  }

  /// Construye los filtros por tipo de empleado
  Widget _construirFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border(bottom: BorderSide(color: const Color(0xFFF7F7F7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar por tipo de empleado',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _filtroTipo,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _filtrosTipo.map((filtro) {
              return DropdownMenuItem(
                value: filtro['value'],
                child: Text(filtro['label']!),
              );
            }).toList(),
            onChanged: (String? nuevoValor) {
              if (nuevoValor != null) {
                setState(() {
                  _filtroTipo = nuevoValor;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  /// Construye la lista de empleados
  Widget _buildListaEmpleados(List<Map<String, dynamic>> empleadosFiltrados) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (empleadosFiltrados.isEmpty) {
      return _buildEmptyStateWidget();
    }

    return RefreshIndicator(
      onRefresh: _cargarEmpleados,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: empleadosFiltrados.length,
        itemBuilder: (context, index) {
          final empleado = empleadosFiltrados[index];
          return _construirEmpleadoCard(empleado);
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
            'Cargando empleados...',
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
            'No hay empleados registrados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona el botón + para agregar el primer empleado',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  

  Widget _construirEmpleadoCard(Map<String, dynamic> empleado) {
    final String tipoEmpleado = empleado['tipo_empleado_id'] ?? 'Sin tipo';
    final bool isActive = empleado['activo'] ?? true;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar/Icono del empleado
            _buildAvatarEmpleado(empleado, tipoEmpleado),

            const SizedBox(width: 12),

            // Información del empleado - MODIFICADO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre completo (primer nombre + primer apellido)
                  Text(
                    _obtenerNombreCompletoCorto(empleado),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Tipo de empleado
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      Text(
                        _capitalizeFirst(tipoEmpleado),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
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
                          color: isActive ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActive ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Acciones
            _buildAccionesColumn(empleado),
          ],
        ),
      ),
    );
  }

  /// Construye el avatar/icono del empleado
  Widget _buildAvatarEmpleado(
    Map<String, dynamic> empleado,
    String tipoEmpleado,
  ) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getColorPorTipo(tipoEmpleado),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getIconoPorTipo(tipoEmpleado),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  /// Construye la información del empleado
  Widget _buildEmpleadoInfo(
    Map<String, dynamic> empleado,
    String tipoEmpleado,
    String fechaContratacion,
    String fechaNacimiento,
    int edad,
  ) {
    final String nombreCompleto =
        '${empleado['nombre'] ?? ''} ${empleado['apellido_paterno'] ?? ''} ${empleado['apellido_materno'] ?? ''}'
            .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre completo
        Text(
          nombreCompleto.isEmpty ? 'Sin nombre' : nombreCompleto,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 6),

        // DNI y Edad
        Row(
          children: [
            Text(
              'DNI: ${empleado['dni_empleado'] ?? 'No especificado'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Edad: $edad años',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Tipo de empleado
        Row(
          children: [
            Icon(
              _getIconoPorTipo(tipoEmpleado),
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              _tipoEmpleadoLabels[tipoEmpleado] ?? tipoEmpleado,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Género
        Text(
          'Género: ${_formatearGenero(empleado['genero'])}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),

        const SizedBox(height: 4),

        // Información de contacto
        Row(
          children: [
            const Icon(Icons.phone, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                empleado['numero_telefonico'] ?? 'Sin teléfono',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Fecha de contratación
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              'Contratación: $fechaContratacion',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),

        // Salario
        if (empleado['salario'] != null) ...[
          const SizedBox(height: 4),
          Text(
            'Salario: S/. ${empleado['salario'].toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  /// Construye la columna de acciones (editar y eliminar)
  Widget _buildAccionesColumn(Map<String, dynamic> empleado) {
    return Column(
      mainAxisSize: MainAxisSize.min,

      children: [
        _construirBotonDetalle(empleado),
        //_buildBotonEditar(empleado),
        //const SizedBox(height: 8),
        //_buildBotonEliminar(empleado),
      ],
    );
  }

  /// Construye el botón flotante para agregar empleado
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NuevoEmpleado(),
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
      tooltip: 'Agregar empleado',
      backgroundColor: Colors.blue,
      child: const Icon(Icons.person_add, color: Colors.white, size: 25),
    );
  }

  Widget _construirBotonDetalle(Map<String, dynamic> empleado) {
    return IconButton(
      onPressed: () {
        print('🚀 Intentando navegar...');

        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmpleadosDetalle(empleado: empleado),
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

  /// Construye el botón de editar
  Widget _buildBotonEditar(Map<String, dynamic> empleado) {
    return IconButton(
      onPressed: () => {}, //_navegarAEditarEmpleado(empleado),
      icon: Icon(Icons.edit_outlined, color: Colors.blue[600], size: 20),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      tooltip: 'Editar empleado',
      style: IconButton.styleFrom(
        backgroundColor: Colors.blue[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }


  // ========== MÉTODOS DE UTILIDAD ==========

  /// Obtiene el color correspondiente al tipo de empleado
  Color _getColorPorTipo(String tipo) {
    switch (tipo) {
      case 'odontologo':
        return Colors.blue;
      case 'asistente_dental':
        return Colors.green;
      case 'recepcionista':
        return Colors.orange;
      case 'higienista':
        return Colors.purple;
      case 'administrador':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtiene el icono correspondiente al tipo de empleado
  IconData _getIconoPorTipo(String tipo) {
    switch (tipo) {
      case 'odontologo':
        return Icons.medical_services;
      case 'asistente_dental':
        return Icons.assistant;
      case 'recepcionista':
        return Icons.desk;
      case 'higienista':
        return Icons.clean_hands;
      case 'administrador':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Método auxiliar para obtener nombre corto (primer nombre + primer apellido)
  String _obtenerNombreCompletoCorto(Map<String, dynamic> empleado) {
    final String nombreCompleto =
        empleado['nombre_completo'] ??
        '${empleado['nombre']} ${empleado['apellido_paterno']}' ??
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

  /// Formatea una fecha Timestamp para mostrar al usuario
  String _formatearFecha(dynamic fecha) {
    try {
      if (fecha == null) return 'No disponible';

      DateTime fechaDateTime;
      if (fecha is Timestamp) {
        fechaDateTime = fecha.toDate();
      } else if (fecha is String) {
        fechaDateTime = DateTime.parse(fecha);
      } else {
        return 'Formato inválido';
      }

      return '${fechaDateTime.day.toString().padLeft(2, '0')}/${fechaDateTime.month.toString().padLeft(2, '0')}/${fechaDateTime.year}';
    } catch (e) {
      return 'Fecha no disponible';
    }
  }

  /// Formatea el género para mostrar
  String _formatearGenero(String? genero) {
    switch (genero?.toLowerCase()) {
      case 'masculino':
        return 'Masculino';
      case 'femenino':
        return 'Femenino';
      case 'otro':
        return 'Otro';
      default:
        return 'No especificado';
    }
  }

  // ========== MÉTODOS DE NAVEGACIÓN ==========
  /*
  /// Navega a la pantalla de creación de empleado
  Future<void> _navegarACrearEmpleado() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmpleadosFormScreen()),
    );
    
    if (result == true) {
      _cargarEmpleados();
    }
  } 

  /// Navega a la pantalla de edición de empleado
  Future<void> _navegarAEditarEmpleado(Map<String, dynamic> empleado) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmpleadoEditarScreen(empleadoToEdit: empleado),
      ),
    );
    
    if (result == true) {
      _cargarEmpleados();
    }
  } */

  // ========== MÉTODOS DE DIÁLOGOS Y MENSAJES ==========

  /// Confirma la eliminación de un empleado
  Future<void> _confirmarEliminacion(Map<String, dynamic> empleado) async {
    final String nombreCompleto =
        '${empleado['nombre'] ?? ''} ${empleado['apellido_paterno'] ?? ''}'
            .trim();

    final bool? confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[600],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Confirmar Eliminación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: '¿Estás seguro de que deseas eliminar al empleado ',
                  ),
                  TextSpan(
                    text: '"$nombreCompleto"',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const TextSpan(
                    text: '?\n\nEsta acción no se puede deshacer.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Eliminar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      _eliminarEmpleado(empleado['id']);
    }
  }

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
          onPressed: _cargarEmpleados,
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