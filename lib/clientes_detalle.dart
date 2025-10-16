import 'package:flutter/material.dart';

/// Widget de detalle de paciente
///
/// Muestra la información completa de un paciente en formato de perfil,
/// con tabs para información, historial y documentos (expansible).
class ClientesDetalle extends StatelessWidget {
  /// Mapa con los datos del paciente a mostrar
  final Map<String, dynamic> paciente;

  /// Constructor
  const ClientesDetalle({Key? key, required this.paciente}) : super(key: key);

  // Eliminado: late final double _anchoPantalla = _calcularAnchoPantalla(context);

  @override
  Widget build(BuildContext context) {
    late final double _anchoPantalla = _calcularAnchoPantalla(context);
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.grey[50],
      appBar: _construirAppBar(context),
      body: Container(
        child: Column(
          children: [_buildProfileHeader(), _buildTabsSection(context)],
        ),
      ),
    );
  }

  // ================== APP BAR ==================
  PreferredSizeWidget _construirAppBar(context) {
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
              // Botón de retroceso
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'Detalle de Paciente',
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

  // ========== HEADER DE PERFIL COMPRIMIDO =============
  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNombre(),
                const SizedBox(height: 12),
                _buildEstadoBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Avatar circular con iniciales del empleado
  Widget _buildAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
      child: Center(
        child: Text(
          _obtenerIniciales(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
      ),
    );
  }

  /// Nombre completo del empleado - Más compacto
  Widget _buildNombre() {
    return Text(
      _obtenerNombreCompleto(),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        height: 1.2,
      ),
    );
  }

  /// Badge de estado más compacto
  Widget _buildEstadoBadge() {
    final String estado = paciente['estado'] ? 'Con tratamiento' : 'Sin tratamiento';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _getColorEstado(estado).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          color: _getColorEstado(estado),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ========== SECCIÓN DE TABS =============
  Widget _buildTabsSection(BuildContext context) {
    return _buildTabsHeader(context);
  }

  Widget _buildTabsHeader(BuildContext context) {
    final double anchoTab = 80.0;
    final double _anchoPantalla = _calcularAnchoPantalla(context);
    return DefaultTabController(
      length: 3, // Número de tabs
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            // Códigos para eliminar todo el espaciado
            padding: EdgeInsets.zero, // Sin padding externo
            labelPadding: EdgeInsets.zero, // Sin padding interno
            indicatorPadding: EdgeInsets.zero, // Sin padding del indicador
            tabs: [
              SizedBox(
                width: _anchoPantalla / 4,
                child: Tab(text: 'Atenciones'),
              ),
              SizedBox(
                width: _anchoPantalla / 4,
                child: Tab(text: 'Pagos'),
              ),
              SizedBox(
                width: _anchoPantalla / 4,
                child: Tab(text: 'Información'),
              ),
            ],
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: TabBarView(
                  children: [
                    // Aquí van los contenidos de cada tab
                    Column(
                      children: [
                        Center(child: Text('Contenido Atenciones')),
                        Center(child: Text('Lista de Tratamientos')),
                        Center(child: Text('Citas Programadas')),
                        Center(child: Text('Historial de Atenciones')),
                        Center(child: Text('Próxima Cita')),
                        Center(child: Text('Estado del Tratamiento')),
                        Center(child: Text('Observaciones del Paciente')),
                        Center(child: Text('Plan de Tratamiento')),
                        Center(child: Text('Medico Asignado')),
                        Center(child: Text('Costos y Pagos')),
                      ],
                    ),
                    Center(child: Text('Contenido Pagos')),
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildTabContent(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Contenido de la tab seleccionada (información personal)
  Widget _buildTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información Personal
        const Text(
          'Datos Personales',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem('Nombres', paciente['nombres']?.toString() ?? ''),
        _buildInfoItem(
          'Apellido Paterno',
          paciente['apellido_paterno']?.toString() ?? '',
        ),
        _buildInfoItem(
          'Apellido Materno',
          paciente['apellido_materno']?.toString() ?? '',
        ),
        _buildInfoItem('DNI', paciente['dni']?.toString() ?? ''),
        _buildInfoItem('Edad', paciente['edad']?.toString() ?? ''),
        _buildInfoItem('Género', paciente['genero']?.toString() ?? ''),
        _buildInfoItem(
          'Fecha de Nacimiento',
          _formatearFecha(paciente['fecha_nacimiento']),
        ),

        const SizedBox(height: 16),

        // Información de Contacto
        const Text(
          'Información de Contacto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem('Dirección', paciente['direccion']?.toString() ?? ''),
        _buildInfoItem(
          'Teléfono',
          paciente['numero_telefonico']?.toString() ?? '',
        ),
      ],
    );
  }

  /// Ítem de información con etiqueta y valor
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : 'No disponible',
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  // ========== MÉTODOS DE UTILIDAD Y FORMATEO ==========

  double _calcularAnchoPantalla(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth; // Dividir entre número de días
  }

  /// Obtiene las iniciales del nombre completo
  String _obtenerIniciales() {
    final nombres = paciente['nombres']?.toString() ?? '';
    final apellidoPaterno = paciente['apellido_paterno']?.toString() ?? '';

    if (nombres.isEmpty && apellidoPaterno.isEmpty) return '?';

    String inicialNombre = nombres.isNotEmpty ? nombres[0].toUpperCase() : '';
    String inicialApellido = apellidoPaterno.isNotEmpty
        ? apellidoPaterno[0].toUpperCase()
        : '';

    return '$inicialNombre$inicialApellido';
  }

  /// Construye el nombre completo a partir de los campos individuales
  String _obtenerNombreCompleto() {
    final nombres = paciente['nombres']?.toString() ?? '';
    final apellidoPaterno = paciente['apellido_paterno']?.toString() ?? '';
    final apellidoMaterno = paciente['apellido_materno']?.toString() ?? '';

    return '$nombres $apellidoPaterno $apellidoMaterno'.trim();
  }

  /// Devuelve el color correspondiente al estado
  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'con tratamiento':
        return Colors.green;
      case 'sin tratamiento':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  /// Formatea una fecha ISO string a formato legible
  String _formatearFecha(dynamic fechaInput) {
    if (fechaInput == null) return 'No disponible';

    try {
      String fechaString;

      if (fechaInput is String) {
        fechaString = fechaInput;
      } else if (fechaInput is DateTime) {
        fechaString = fechaInput.toIso8601String();
      } else {
        return fechaInput.toString();
      }

      final fecha = DateTime.parse(fechaString);
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    } catch (e) {
      return fechaInput.toString();
    }
  }
}
