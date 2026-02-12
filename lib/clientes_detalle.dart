import 'package:flutter/material.dart';
import 'views/tratamiendos.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'views/paciente_editar.dart';

/// Pantalla de detalle del paciente
///
/// Muestra información completa del paciente con tabs para:
/// - Historial médico
/// - Tratamientos activos
/// - Pagos realizados
class ClientesDetalle extends StatefulWidget {
  final Map<String, dynamic> paciente;

  const ClientesDetalle({Key? key, required this.paciente}) : super(key: key);

  @override
  State<ClientesDetalle> createState() => _ClientesDetalleState();
}

class _ClientesDetalleState extends State<ClientesDetalle>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _construirAppBar(),
      body: Column(
        children: [
          _construirHeaderPaciente(),
          const Divider(height: 0.5, thickness: 0.5),
          Expanded(
            child: Column(
              children: [
                _construirTabBar(),
                Expanded(child: _construirTabBarView()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== APP BAR ==========

  PreferredSizeWidget _construirAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.black,
                    size: 14,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Detalle del paciente',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onPressed: _mostrarMenuOpciones,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== HEADER DEL PACIENTE ==========

  Widget _construirHeaderPaciente() {
    final bool isActive = widget.paciente['activo'] ?? true;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              _construirAvatar(),
              const SizedBox(width: 16),

              // Información básica
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _obtenerNombreCompleto(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'DNI: ${widget.paciente['dni_cliente'] ?? 'No especificado'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _construirEstadoBadge(isActive),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirAvatar() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _obtenerIniciales(),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _construirEstadoBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF10B981).withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF10B981) : Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Con tratamiento' : 'Sin tratamiento',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? const Color(0xFF10B981) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirInfoCard(IconData icono, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ========== TABS ==========

  Widget _construirTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.green,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.green,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Información'),
          Tab(text: 'Tratamientos'),
          Tab(text: 'Historial'),
        ],
      ),
    );
  }

  Widget _construirTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _construirTabInformacion(),
        _construirTabTratamientos(),
        _construirTabHistorial(),
      ],
    );
  }

  // ========== TAB: INFORMACIÓN ==========

  Widget _construirTabInformacion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _construirSeccionInfo('Datos Personales', [
            _construirItemInfo('Nombres', widget.paciente['nombre']),
            _construirItemInfo(
              'Apellido Paterno',
              widget.paciente['apellido_paterno'],
            ),
            _construirItemInfo(
              'Apellido Materno',
              widget.paciente['apellido_materno'],
            ),
            _construirItemInfo('DNI', widget.paciente['dni_cliente']),
            _construirItemInfo('Sexo', widget.paciente['sexo']),
            _construirItemInfo(
              'Fecha de Nacimiento',
              _formatearFecha(widget.paciente['fecha_nacimiento']),
            ),
            _construirItemInfo(
              'Edad',
              '${widget.paciente['edad'] ?? 'N/A'} años',
            ),
            _construirItemInfo('Estado Civil', widget.paciente['estado_civil']),
            _construirItemInfo('Ocupación', widget.paciente['ocupacion']),
          ]),

          const SizedBox(height: 24),

          _construirSeccionInfo('Información de Contacto', [
            _construirItemInfo('Celular', widget.paciente['celular']),
            _construirItemInfo(
              'Teléfono Fijo',
              widget.paciente['telefono_fijo'],
            ),
            _construirItemInfo('Email', widget.paciente['email']),
          ]),

          const SizedBox(height: 24),

          _construirSeccionInfo('Domicilio', [
            _construirItemInfo('Dirección', widget.paciente['direccion']),
            _construirItemInfo(
              'Distrito',
              widget.paciente['distrito_direccion'],
            ),
            _construirItemInfo(
              'Lugar de Procedencia',
              widget.paciente['lugar_procedencia'],
            ),
          ]),
        ],
      ),
    );
  }

  Widget _construirSeccionInfo(String titulo, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }

  Widget _construirItemInfo(String label, dynamic value) {
    final String valorTexto = value?.toString() ?? 'No disponible';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              valorTexto,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ========== TAB: TRATAMIENTOS ==========

  Widget _construirTabTratamientos() {
    return TratamiendosScreen(paciente: widget.paciente);
  }

  // ========== TAB: PAGOS ==========

  Widget _construirTabHistorial() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Historial de citas',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Próximamente',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ========== MENÚ DE OPCIONES ==========

  void _mostrarMenuOpciones() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar información'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PacienteEditar(paciente: widget.paciente),
                      ),
                    ).then((actualizado) {
                      if (actualizado == true) {
                        setState(() {});
                      }
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Eliminar paciente',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmarEliminar();
                  },
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 0),
              ],
            ),
          ),
        );
      },
    );
  }
  void _confirmarEliminar() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Eliminar Paciente'),
        content: Text(
          '¿Estás seguro de que deseas eliminar al paciente "${widget.paciente['nombre']}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade800,
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _eliminarPaciente();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );
}

Future<void> _eliminarPaciente() async {
  try {
    await FirebaseFirestore.instance
        .collection('pacientes')
        .doc(widget.paciente['id'])
        .delete();

    if (mounted) {
      _mostrarMensaje('Paciente eliminado exitosamente');
      Navigator.pop(context, true);
    }
  } catch (e) {
    if (mounted) {
      _mostrarMensaje('Error al eliminar paciente: $e', esError: true);
    }
  }
}

void _mostrarMensaje(String mensaje, {bool esError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje),
      backgroundColor: esError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

  // ========== UTILIDADES ==========

  String _obtenerNombreCompleto() {
    final nombre = widget.paciente['nombre']?.toString() ?? '';
    final apellidoP = widget.paciente['apellido_paterno']?.toString() ?? '';
    final apellidoM = widget.paciente['apellido_materno']?.toString() ?? '';
    return '$nombre $apellidoP $apellidoM'.trim();
  }

  String _obtenerIniciales() {
    final nombre = widget.paciente['nombre']?.toString() ?? '';
    final apellido = widget.paciente['apellido_paterno']?.toString() ?? '';

    if (nombre.isEmpty && apellido.isEmpty) return '?';

    final inicialN = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final inicialA = apellido.isNotEmpty ? apellido[0].toUpperCase() : '';

    return '$inicialN$inicialA';
  }

  String _formatearFecha(dynamic fechaInput) {
    if (fechaInput == null) return 'No disponible';

    try {
      DateTime fecha;

      if (fechaInput is String) {
        fecha = DateTime.parse(fechaInput);
      } else if (fechaInput is DateTime) {
        fecha = fechaInput;
      } else if (fechaInput is Timestamp) {
        // Agregar este caso
        fecha = (fechaInput as Timestamp).toDate();
      } else {
        return fechaInput.toString();
      }

      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    } catch (e) {
      return fechaInput.toString();
    }
  }
}
