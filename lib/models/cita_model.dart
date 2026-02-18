import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialEstado {
  final String estado;
  final DateTime fecha;
  final String realizadoPor;
  final String tipo;

  HistorialEstado({
    required this.estado,
    required this.fecha,
    required this.realizadoPor,
    required this.tipo,
  });

  factory HistorialEstado.fromMap(Map<String, dynamic> map) {
    return HistorialEstado(
      estado: map['estado'] ?? '',
      fecha: (map['fecha'] as Timestamp).toDate(),
      realizadoPor: map['realizado_por'] ?? '',
      tipo: map['tipo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'estado': estado,
      'fecha': Timestamp.fromDate(fecha),
      'realizado_por': realizadoPor,
      'tipo': tipo,
    };
  }
}

class Cita {
  final String id;
  final DateTime fecha;
  final String hora;
  final String duracion;
  final String estado;
  final String tipoConsulta;
  final String pacienteId;
  final String pacienteNombre;
  final String? tratamientoId;
  final String? tratamientoNombre;
  final bool esTratamiento;
  final double costo;
  final bool pagado;
  final String? atendidoPor;
  final String? duracionReal;
  final String? horaInicioAtencion;
  final String? horaFinAtencion;
  final String? notasObservaciones;
  final DateTime fechaCreacion;
  final List<HistorialEstado> historialEstados;

  Cita({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.duracion,
    required this.estado,
    required this.tipoConsulta,
    required this.pacienteId,
    required this.pacienteNombre,
    this.tratamientoId,
    this.tratamientoNombre,
    required this.esTratamiento,
    required this.costo,
    required this.pagado,
    this.atendidoPor,
    this.duracionReal,
    this.horaInicioAtencion,
    this.horaFinAtencion,
    this.notasObservaciones,
    required this.fechaCreacion,
    required this.historialEstados,
  });

  factory Cita.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Cita(
      id: doc.id,
      fecha: (data['fecha'] as Timestamp).toDate(),
      hora: data['hora'] ?? '',
      duracion: data['duracion'] ?? '60',
      estado: data['estado'] ?? 'pendiente',
      tipoConsulta: data['tipo_consulta'] ?? '',
      pacienteId: data['paciente_id'] ?? '',
      pacienteNombre: data['paciente_nombre'] ?? '',
      tratamientoId: data['tratamiento_id'],
      tratamientoNombre: data['tratamiento_nombre'],
      esTratamiento: data['es_tratamiento'] ?? false,
      costo: (data['costo'] ?? 0).toDouble(),
      pagado: data['pagado'] ?? false,
      atendidoPor: data['atendido_por'],
      duracionReal: data['duracion_real'],
      horaInicioAtencion: data['hora_inicio_atencion'],
      horaFinAtencion: data['hora_fin_atencion'],
      notasObservaciones: data['notas_observaciones'],
      fechaCreacion: (data['fecha_creacion'] as Timestamp).toDate(),
      historialEstados: data['historial_estados'] != null
          ? (data['historial_estados'] as List)
              .map((item) => HistorialEstado.fromMap(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fecha': Timestamp.fromDate(fecha),
      'hora': hora,
      'duracion': duracion,
      'estado': estado,
      'tipo_consulta': tipoConsulta,
      'paciente_id': pacienteId,
      'paciente_nombre': pacienteNombre,
      if (tratamientoId != null) 'tratamiento_id': tratamientoId,
      if (tratamientoNombre != null) 'tratamiento_nombre': tratamientoNombre,
      'es_tratamiento': esTratamiento,
      'costo': costo,
      'pagado': pagado,
      if (atendidoPor != null) 'atendido_por': atendidoPor,
      if (notasObservaciones != null) 'notas_observaciones': notasObservaciones,
      'fecha_creacion': Timestamp.fromDate(fechaCreacion),
      'historial_estados': historialEstados.map((h) => h.toMap()).toList(),
    };
  }
}
