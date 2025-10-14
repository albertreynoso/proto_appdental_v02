import 'package:flutter/material.dart';

/// Modal para crear y editar citas odontológicas
/// 
/// Permite seleccionar paciente, odontólogo, horarios y otros detalles
/// de la cita de forma intuitiva y validada
class CitaModal extends StatefulWidget {
  final DateTime date;
  final String hour;
  final Function(Map<String, dynamic> atencionData) onSave;

  const CitaModal({
    super.key,
    required this.date,
    required this.hour,
    required this.onSave,
  });

  @override
  State<CitaModal> createState() => _CitaModalState();
}

class _CitaModalState extends State<CitaModal> {
  // ========== CONSTANTES ==========
  
  /// Tipos de atención disponibles
  static const List<String> _tiposAtencion = ['Cita', 'Consulta', 'Urgencia', 'Control'];
  
  /// Consultorios disponibles
  static const List<String> _consultorios = ['1', '2', '3', '4'];
  
  /// Nombres de días (abreviados)
  static const List<String> _nombresDias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  
  /// Duración por defecto de cita (minutos)
  static const int _duracionDefectoCita = 30;
  
  // ========== CONTROLADORES ==========
  
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _pacienteController = TextEditingController();
  final TextEditingController _odontologoController = TextEditingController();
  final TextEditingController _asistenteController = TextEditingController();

  // ========== VARIABLES DE ESTADO ==========
  
  String _tipoAtencionSeleccionado = _tiposAtencion.first;
  String _consultorioSeleccionado = _consultorios.first;
  late TimeOfDay _horaInicio;
  late TimeOfDay _horaFin;

  // TODO: Obtener de base de datos
  final List<String> _pacientes = ['Juan Pérez', 'Ana Torres', 'Carlos Ruiz', 'María López'];
  final List<String> _odontologos = ['Dra. Ana López', 'Dr. Luis Gómez', 'Dra. Marta Díaz'];
  final List<String> _asistentes = ['Asistente 1', 'Asistente 2', 'Dra. Ana López', 'Dr. Luis Gómez'];

  // ========== CICLO DE VIDA ==========
  
  @override
  void initState() {
    super.initState();
    _inicializarHorarios();
  }

  @override
  void dispose() {
    _liberarControladores();
    super.dispose();
  }

  // ========== MÉTODOS DE INICIALIZACIÓN ==========
  
  /// Inicializa los horarios de inicio y fin basado en la hora proporcionada
  void _inicializarHorarios() {
    final partesHora = widget.hour.split(':');
    final hora = int.parse(partesHora[0]);
    final minuto = int.parse(partesHora[1]);
    
    _horaInicio = TimeOfDay(hour: hora, minute: minuto);
    _horaFin = _calcularHoraFin(_horaInicio, _duracionDefectoCita);
  }
  
  /// Calcula la hora de fin basada en la hora de inicio y duración
  TimeOfDay _calcularHoraFin(TimeOfDay horaInicio, int duracionMinutos) {
    final totalMinutos = horaInicio.hour * 60 + horaInicio.minute + duracionMinutos;
    return TimeOfDay(hour: totalMinutos ~/ 60, minute: totalMinutos % 60);
  }
  
  /// Libera los controladores de texto
  void _liberarControladores() {
    _descripcionController.dispose();
    _pacienteController.dispose();
    _odontologoController.dispose();
    _asistenteController.dispose();
  }

  // ========== CONSTRUCCIÓN DE UI ==========
  
  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.97,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _construirCabecera(),
                const SizedBox(height: 16),
                _construirSelectorTipoAtencion(),
                const SizedBox(height: 16),
                _construirAutocomplete(_pacienteController, 'Paciente', _pacientes, Icons.person),
                const SizedBox(height: 16),
                _construirCampoTexto(_descripcionController, 'Descripción', maxLineas: 2),
                const SizedBox(height: 16),
                _construirSelectorHorario(),
                const SizedBox(height: 8),
                _construirTextoFecha(),
                const SizedBox(height: 16),
                _construirAutocomplete(_odontologoController, 'Odontólogo', _odontologos, Icons.medical_services),
                const SizedBox(height: 16),
                _construirSelectorConsultorio(),
                const SizedBox(height: 16),
                _construirAutocomplete(_asistenteController, 'Asistente', _asistentes, Icons.support_agent),
                const SizedBox(height: 24),
                _construirBotones(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== WIDGETS MODULARES ==========
  
  /// Construye la cabecera del modal con título y botón cerrar
  Widget _construirCabecera() {
    return Row(
      children: [
        const Text('Nueva Cita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Cerrar',
        ),
      ],
    );
  }
  
  /// Construye el selector de tipo de atención
  Widget _construirSelectorTipoAtencion() {
    return DropdownButtonFormField<String>(
      value: _tipoAtencionSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Tipo de atención',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.medical_services),
      ),
      items: _tiposAtencion.map((tipo) => 
        DropdownMenuItem(value: tipo, child: Text(tipo))
      ).toList(),
      onChanged: (valor) => setState(() => _tipoAtencionSeleccionado = valor ?? _tiposAtencion.first),
    );
  }
  
  /// Construye un campo de texto reutilizable
  Widget _construirCampoTexto(TextEditingController controlador, String etiqueta, {
    int maxLineas = 1,
    IconData? icono,
  }) {
    return TextField(
      controller: controlador,
      maxLines: maxLineas,
      decoration: InputDecoration(
        labelText: etiqueta,
        border: const OutlineInputBorder(),
        prefixIcon: icono != null ? Icon(icono) : null,
      ),
    );
  }
  
  /// Construye el selector de horario
  Widget _construirSelectorHorario() {
    return Row(
      children: [
        Icon(Icons.access_time, color: Colors.grey[700]),
        const SizedBox(width: 8),
        _construirBotonHora(_horaInicio, 'Hora inicio', (hora) => _horaInicio = hora),
        const Text(' → ', style: TextStyle(fontSize: 16)),
        _construirBotonHora(_horaFin, 'Hora fin', (hora) => _horaFin = hora),
      ],
    );
  }
  
  /// Construye un botón para seleccionar hora
  Widget _construirBotonHora(TimeOfDay hora, String tooltip, Function(TimeOfDay) onChanged) {
    return GestureDetector(
      onTap: () async {
        final horaSeleccionada = await showTimePicker(context: context, initialTime: hora);
        if (horaSeleccionada != null) setState(() => onChanged(horaSeleccionada));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('${hora.format(context)}', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
  
  /// Construye el texto de fecha
  Widget _construirTextoFecha() {
    return Text(
      'Fecha: ${_formatearFecha(widget.date)}',
      style: const TextStyle(fontSize: 14, color: Colors.grey),
    );
  }
  
  /// Construye un campo de autocompletado reutilizable
  Widget _construirAutocomplete(
    TextEditingController controlador,
    String etiqueta,
    List<String> opciones,
    IconData icono,
  ) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue valorTexto) {
        if (valorTexto.text.isEmpty) return const Iterable<String>.empty();
        return opciones.where((opcion) => 
          opcion.toLowerCase().contains(valorTexto.text.toLowerCase())
        );
      },
      onSelected: (seleccion) => controlador.text = seleccion,
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        controlador.text = controller.text;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: etiqueta,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icono),
          ),
        );
      },
    );
  }
  
  /// Construye el selector de consultorio
  Widget _construirSelectorConsultorio() {
    return DropdownButtonFormField<String>(
      value: _consultorioSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Consultorio',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.room),
      ),
      items: _consultorios.map((consultorio) => 
        DropdownMenuItem(
          value: consultorio, 
          child: Text('Consultorio $consultorio')
        )
      ).toList(),
      onChanged: (valor) => setState(() => 
        _consultorioSeleccionado = valor ?? _consultorios.first
      ),
    );
  }
  
  /// Construye los botones de acción (Cancelar/Guardar)
  Widget _construirBotones() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _validarYGuardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
  
  // ========== MÉTODOS DE LÓGICA DE NEGOCIO ==========
  
  /// Valida y guarda la cita
  void _validarYGuardar() {
    // Validaciones básicas
    
    if (_pacienteController.text.trim().isEmpty) {
      _mostrarError('Debe seleccionar un paciente');
      return;
    }
    
    if (_odontologoController.text.trim().isEmpty) {
      _mostrarError('Debe seleccionar un odontólogo');
      return;
    }
    
    // Construir datos de la cita
    final datosCita = _construirDatosCita();
    
    // Guardar y cerrar
    widget.onSave(datosCita);
    Navigator.pop(context);
  }
  
  /// Construye el mapa con todos los datos de la cita
  Map<String, dynamic> _construirDatosCita() {
    return {
      'tipo': _tipoAtencionSeleccionado,
      'descripcion': _descripcionController.text.trim(),
      'fecha': DateTime(widget.date.year, widget.date.month, widget.date.day),
      'hora_inicio': _horaInicio.format(context),
      'hora_fin': _horaFin.format(context),
      'paciente_nombre': _pacienteController.text.trim(),
      'odontologo_nombre': _odontologoController.text.trim(),
      'consultorio': _consultorioSeleccionado,
      'asistente_nombre': _asistenteController.text.trim(),
      'creado_por': 'Usuario Demo', // TODO: Obtener usuario actual
      'estado': 'pendiente',
      'fecha_creacion': DateTime.now(),
    };
  }
  
  /// Muestra un mensaje de error
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // ========== MÉTODOS DE UTILIDAD ==========
  
  /// Formatea una fecha en formato legible
  String _formatearFecha(DateTime fecha) {
    final indiceSeguro = (fecha.weekday - 1) % _nombresDias.length;
    return '${_nombresDias[indiceSeguro]} ${fecha.day}/${fecha.month}/${fecha.year}';
  }
}