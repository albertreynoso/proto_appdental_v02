import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:proto_appdental_v02/models/cita_model.dart';

class NuevaCitaScreen extends StatefulWidget {
  final DateTime? fechaSeleccionada;
  final String? horaSeleccionada;

  const NuevaCitaScreen({
    super.key,
    this.fechaSeleccionada,
    this.horaSeleccionada,
  });

  @override
  State<NuevaCitaScreen> createState() => _NuevaCitaScreenState();
}

class _NuevaCitaScreenState extends State<NuevaCitaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isGuardando = false;
  bool _cargandoPacientes = false;
  bool _cargandoTratamientos = false;

  // Controladores
  late TextEditingController _busquedaPacienteController;
  late TextEditingController _dniController;
  late TextEditingController _telefonoController;
  late TextEditingController _notasController;

  // Estados
  DateTime? _fechaSeleccionada;
  String? _horaSeleccionada;
  String? _duracionSeleccionada = '30';
  String? _tipoConsultaSeleccionada;
  bool _esNuevoPaciente = false;
  String? _pacienteId;
  String? _pacienteNombre;
  String? _tratamientoSeleccionadoId;
  String? _tratamientoSeleccionadoNombre;

  // Datos
  List<Map<String, dynamic>> _pacientes = [];
  List<Map<String, dynamic>> _pacientesFiltrados = [];
  List<Map<String, dynamic>> _tratamientosActivos = [];

  // Tipos de consulta con costos
  final List<Map<String, dynamic>> _tiposConsulta = [
    {'tipo': 'Evaluación general', 'costo': 30.0},
    {'tipo': 'Evaluación ortodoncia', 'costo': 50.0},
    {'tipo': 'Implantes', 'costo': 70.0},
    {'tipo': 'Odontopediatría', 'costo': 50.0},
    {'tipo': 'Rehabilitación', 'costo': 70.0},
    {'tipo': 'Evaluación estética', 'costo': 70.0},
  ];

  // Duraciones
  final List<Map<String, String>> _duraciones = [
    {'valor': '30', 'label': '30 minutos'},
    {'valor': '45', 'label': '45 minutos'},
    {'valor': '60', 'label': '1 hora'},
    {'valor': '90', 'label': '1.5 horas'},
    {'valor': '120', 'label': '2 horas'},
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES');
    _busquedaPacienteController = TextEditingController();
    _dniController = TextEditingController();
    _telefonoController = TextEditingController();
    _notasController = TextEditingController();
    _busquedaPacienteController.addListener(_filtrarPacientes);
    _fechaSeleccionada = widget.fechaSeleccionada ?? DateTime.now();
    _horaSeleccionada = widget.horaSeleccionada;
    _cargarPacientes();
  }

  @override
  void dispose() {
    _busquedaPacienteController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  // ========== CARGA DE DATOS ==========

  Future<void> _cargarPacientes() async {
    setState(() => _cargandoPacientes = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pacientes')
          .orderBy('nombre')
          .get();

      _pacientes = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nombre': data['nombre'] ?? '',
          'apellido_paterno': data['apellido_paterno'] ?? '',
          'apellido_materno': data['apellido_materno'] ?? '',
          'dni_cliente': data['dni_cliente'] ?? '',
        };
      }).toList();

      setState(() => _pacientesFiltrados = _pacientes);
    } catch (e) {
      _mostrarMensaje('Error al cargar pacientes', esError: true);
    } finally {
      setState(() => _cargandoPacientes = false);
    }
  }

  void _filtrarPacientes() {
    final busqueda = _busquedaPacienteController.text.toLowerCase();
    setState(() {
      _pacientesFiltrados = _pacientes.where((p) {
        final nombreCompleto =
            '${p['nombre']} ${p['apellido_paterno']} ${p['apellido_materno']}'
                .toLowerCase();
        final dni = p['dni_cliente'].toString();
        return nombreCompleto.contains(busqueda) || dni.contains(busqueda);
      }).toList();
    });
  }

  Future<void> _cargarTratamientosActivos(String pacienteId) async {
    setState(() => _cargandoTratamientos = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tratamientos')
          .where('paciente_id', isEqualTo: pacienteId)
          .where('estado', isEqualTo: 'activo')
          .get();

      _tratamientosActivos = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'tratamiento': data['tratamiento'] ?? '',
          'pago_pendiente': (data['pago_pendiente'] ?? 0).toDouble(),
          'total_presupuesto': (data['total_presupuesto'] ?? 0).toDouble(),
        };
      }).toList();

      setState(() {});
    } catch (e) {
      _mostrarMensaje('Error al cargar tratamientos', esError: true);
    } finally {
      setState(() => _cargandoTratamientos = false);
    }
  }

  // ========== GUARDAR EN FIRESTORE ==========

  Future<void> _guardarCita() async {
    if (_fechaSeleccionada == null || _horaSeleccionada == null) {
      _mostrarMensaje('Selecciona fecha y hora', esError: true);
      return;
    }

    if (_pacienteId == null && !_esNuevoPaciente) {
      _mostrarMensaje('Selecciona un paciente', esError: true);
      return;
    }

    if (_esNuevoPaciente && !_formKey.currentState!.validate()) {
      return;
    }

    if (_tratamientoSeleccionadoId == null &&
        _tipoConsultaSeleccionada == null) {
      _mostrarMensaje(
        'Selecciona un tratamiento o tipo de consulta',
        esError: true,
      );
      return;
    }

    setState(() => _isGuardando = true);

    try {
      String pacienteIdFinal = _pacienteId ?? '';
      String pacienteNombreFinal = _pacienteNombre ?? '';

      // Si es nuevo paciente, crearlo primero
      if (_esNuevoPaciente) {
        final nombrePartes = pacienteNombreFinal.trim().split(' ');
        final docRef =
            await FirebaseFirestore.instance.collection('pacientes').add({
          'nombre': nombrePartes.isNotEmpty ? nombrePartes.first : '',
          'apellido_paterno': nombrePartes.length > 1 ? nombrePartes[1] : '',
          'apellido_materno': nombrePartes.length > 2 ? nombrePartes[2] : '',
          'dni_cliente': _dniController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'fecha_registro': Timestamp.now(),
        });
        pacienteIdFinal = docRef.id;
      }

      // Determinar costo según tipo de consulta
      double costo = 0;
      if (_tipoConsultaSeleccionada != null) {
        final tipoData = _tiposConsulta.firstWhere(
          (t) => t['tipo'] == _tipoConsultaSeleccionada,
          orElse: () => {'costo': 0.0},
        );
        costo = (tipoData['costo'] as num).toDouble();
      }

      final cita = Cita(
        id: '',
        fecha: _fechaSeleccionada!,
        hora: _horaSeleccionada!,
        duracion: _duracionSeleccionada ?? '30',
        estado: 'pendiente',
        tipoConsulta: _tipoConsultaSeleccionada ?? '',
        pacienteId: pacienteIdFinal,
        pacienteNombre: pacienteNombreFinal,
        tratamientoId: _tratamientoSeleccionadoId,
        tratamientoNombre: _tratamientoSeleccionadoNombre,
        esTratamiento: _tratamientoSeleccionadoId != null,
        costo: costo,
        pagado: false,
        notasObservaciones: _notasController.text.trim().isNotEmpty
            ? _notasController.text.trim()
            : null,
        fechaCreacion: DateTime.now(),
        historialEstados: [],
      );

      await FirebaseFirestore.instance
          .collection('citas')
          .add(cita.toMap());

      if (mounted) {
        _mostrarMensaje('Cita creada exitosamente');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGuardando = false);
        _mostrarMensaje('Error al crear cita: $e', esError: true);
      }
    }
  }

  // ========== BUILD ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSeccionFechaHora(),
              const SizedBox(height: 16),
              _buildSeccionPaciente(),
              if (_esNuevoPaciente) ...[
                const SizedBox(height: 16),
                _buildSeccionNuevoPaciente(),
              ],
              if (_pacienteId != null && !_esNuevoPaciente) ...[
                const SizedBox(height: 16),
                _buildSeccionTratamientos(),
              ],
              if (_tratamientoSeleccionadoId == null) ...[
                const SizedBox(height: 16),
                _buildSeccionTipoConsulta(),
              ],
              const SizedBox(height: 16),
              _buildSeccionDuracion(),
              const SizedBox(height: 16),
              _buildSeccionNotas(),
              const SizedBox(height: 32),
              _buildBotonesAccion(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
                  'Nueva Cita',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> children,
      {bool requerido = true}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (requerido)
                  const Text(
                    ' *',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // ========== SECCIÓN FECHA Y HORA ==========

  Widget _buildSeccionFechaHora() {
    return _buildSeccion('Fecha y Hora', [
      Row(
        children: [
          Expanded(child: _buildCampoFecha()),
          const SizedBox(width: 12),
          Expanded(child: _buildCampoHora()),
        ],
      ),
    ]);
  }

  Widget _buildCampoFecha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final fecha = await showDatePicker(
              context: context,
              initialDate: _fechaSeleccionada ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              locale: const Locale('es', 'ES'),
            );
            if (fecha != null) setState(() => _fechaSeleccionada = fecha);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Text(
                  _fechaSeleccionada != null
                      ? DateFormat('dd/MM/yyyy', 'es_ES')
                          .format(_fechaSeleccionada!)
                      : 'Seleccionar fecha',
                  style: TextStyle(
                    fontSize: 14,
                    color: _fechaSeleccionada != null
                        ? Colors.black
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoHora() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hora',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _mostrarSelectorHora,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Text(
                  _horaSeleccionada ?? 'Seleccionar hora',
                  style: TextStyle(
                    fontSize: 14,
                    color: _horaSeleccionada != null
                        ? Colors.black
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarSelectorHora() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final horarios = _generarHorarios();
        return SizedBox(
          height: 400,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Text(
                  'Seleccionar Hora',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: horarios.length,
                  itemBuilder: (context, index) {
                    final horario = horarios[index];
                    return ListTile(
                      title: Text(horario['label']!),
                      onTap: () {
                        setState(() => _horaSeleccionada = horario['valor']);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, String>> _generarHorarios() {
    final horarios = <Map<String, String>>[];
    for (int h = 7; h <= 23; h++) {
      for (int m = 0; m < 60; m += 30) {
        final valor =
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        final displayH = h > 12 ? h - 12 : h;
        final periodo = h >= 12 ? 'PM' : 'AM';
        final label = '$displayH:${m.toString().padLeft(2, '0')} $periodo';
        horarios.add({'valor': valor, 'label': label});
      }
    }
    return horarios;
  }

  // ========== SECCIÓN PACIENTE ==========

  Widget _buildSeccionPaciente() {
    return _buildSeccion('Paciente', [
      if (_pacienteId == null && !_esNuevoPaciente) ...[
        TextField(
          controller: _busquedaPacienteController,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintText: 'Buscar por nombre o DNI...',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
            suffixIcon: _cargandoPacientes
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (_busquedaPacienteController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _pacientesFiltrados.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'No se encontró paciente',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _esNuevoPaciente = true;
                              _pacienteNombre =
                                  _busquedaPacienteController.text;
                            });
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Crear nuevo paciente'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _pacientesFiltrados.length,
                    separatorBuilder: (ctx, i) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final paciente = _pacientesFiltrados[index];
                      return ListTile(
                        title: Text(
                          '${paciente['nombre']} ${paciente['apellido_paterno']} ${paciente['apellido_materno']}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'DNI: ${paciente['dni_cliente']}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        onTap: () {
                          setState(() {
                            _pacienteId = paciente['id'];
                            _pacienteNombre =
                                '${paciente['nombre']} ${paciente['apellido_paterno']} ${paciente['apellido_materno']}';
                            _busquedaPacienteController.text = _pacienteNombre!;
                          });
                          _cargarTratamientosActivos(_pacienteId!);
                        },
                      );
                    },
                  ),
          ),
        ],
      ] else ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _pacienteNombre ?? '',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _pacienteId = null;
                    _pacienteNombre = null;
                    _esNuevoPaciente = false;
                    _busquedaPacienteController.clear();
                    _tratamientosActivos.clear();
                    _tratamientoSeleccionadoId = null;
                    _tratamientoSeleccionadoNombre = null;
                  });
                },
                child: const Text('Cambiar'),
              ),
            ],
          ),
        ),
      ],
    ]);
  }

  // ========== SECCIÓN NUEVO PACIENTE ==========

  Widget _buildSeccionNuevoPaciente() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos del nuevo paciente',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildTextField('DNI', _dniController, maxLength: 8)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildTextField('Teléfono', _telefonoController)),
            ],
          ),
        ],
      ),
    );
  }

  // ========== SECCIÓN TRATAMIENTOS ==========

  Widget _buildSeccionTratamientos() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tratamientos Activos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (_cargandoTratamientos)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_tratamientosActivos.isEmpty && !_cargandoTratamientos)
              Text(
                'No hay tratamientos activos',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ..._tratamientosActivos.map((tratamiento) {
                final isSelected =
                    _tratamientoSeleccionadoId == tratamiento['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _tratamientoSeleccionadoId = null;
                          _tratamientoSeleccionadoNombre = null;
                        } else {
                          _tratamientoSeleccionadoId = tratamiento['id'];
                          _tratamientoSeleccionadoNombre =
                              tratamiento['tratamiento'];
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green.shade50
                            : const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected ? Colors.green : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  tratamiento['tratamiento'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Seleccionado',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pendiente: S/ ${tratamiento['pago_pendiente'].toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                              Text(
                                'Total: S/ ${tratamiento['total_presupuesto'].toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ========== SECCIÓN TIPO DE CONSULTA ==========

  Widget _buildSeccionTipoConsulta() {
    return _buildSeccion('Tipo de Consulta', [
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DropdownButtonFormField<String>(
          value: _tipoConsultaSeleccionada,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          hint: Text(
            'Seleccionar tipo de consulta',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          icon:
              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade700),
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Colors.black),
          dropdownColor: Colors.white,
          items: _tiposConsulta.map<DropdownMenuItem<String>>((consulta) {
            return DropdownMenuItem<String>(
              value: consulta['tipo'] as String,
              child: Text(
                '${consulta['tipo']} - S/ ${consulta['costo']}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: (valor) =>
              setState(() => _tipoConsultaSeleccionada = valor),
        ),
      ),
    ]);
  }

  // ========== SECCIÓN DURACIÓN ==========

  Widget _buildSeccionDuracion() {
    return _buildSeccion('Duración', [
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DropdownButtonFormField<String>(
          value: _duracionSeleccionada,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          icon:
              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade700),
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Colors.black),
          dropdownColor: Colors.white,
          items: _duraciones.map((duracion) {
            return DropdownMenuItem(
              value: duracion['valor'],
              child: Text(
                duracion['label']!,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: (valor) => setState(() => _duracionSeleccionada = valor),
        ),
      ),
    ]);
  }

  // ========== SECCIÓN NOTAS ==========

  Widget _buildSeccionNotas() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notas y Observaciones',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notasController,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF3B82F6), width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintText: 'Escribe cualquier información adicional...',
                hintStyle:
                    TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ========== HELPER WIDGETS ==========

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700),
            ),
            const Text(' *', style: TextStyle(color: Colors.red, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            counterText: '',
          ),
          style: const TextStyle(fontSize: 14),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Campo requerido';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBotonesAccion() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isGuardando ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isGuardando ? null : _guardarCita,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 113, 206, 6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _isGuardando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Guardar Cita',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
          ),
        ),
      ],
    );
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
}
