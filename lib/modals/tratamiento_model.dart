import 'package:cloud_firestore/cloud_firestore.dart';

class PresupuestoItem {
  final int cantidad;
  final String descripcion;
  final double precioUnitario;
  final List<SubItem>? subitems;

  PresupuestoItem({
    required this.cantidad,
    required this.descripcion,
    required this.precioUnitario,
    this.subitems,
  });

  factory PresupuestoItem.fromMap(Map<String, dynamic> map) {
    return PresupuestoItem(
      cantidad: map['cantidad'] ?? 0,
      descripcion: map['descripcion'] ?? '',
      precioUnitario: (map['precio_unitario'] ?? 0).toDouble(),
      subitems: map['subitems'] != null
          ? (map['subitems'] as List)
              .map((item) => SubItem.fromMap(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cantidad': cantidad,
      'descripcion': descripcion,
      'precio_unitario': precioUnitario,
      'subitems': subitems?.map((item) => item.toMap()).toList(),
    };
  }

  double get total {
    if (subitems != null && subitems!.isNotEmpty) {
      return subitems!.fold(0, (sum, item) => sum + item.total);
    }
    return cantidad * precioUnitario;
  }
}

class SubItem {
  final int cantidad;
  final String descripcion;
  final double precioUnitario;

  SubItem({
    required this.cantidad,
    required this.descripcion,
    required this.precioUnitario,
  });

  factory SubItem.fromMap(Map<String, dynamic> map) {
    return SubItem(
      cantidad: map['cantidad'] ?? 0,
      descripcion: map['descripcion'] ?? '',
      precioUnitario: (map['precio_unitario'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cantidad': cantidad,
      'descripcion': descripcion,
      'precio_unitario': precioUnitario,
    };
  }

  double get total => cantidad * precioUnitario;
}

class Tratamiento {
  final String id;
  final String tratamiento;
  final String diagnostico;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime? fechaUltimaActualizacion;
  final double totalPresupuesto;
  final double montoAbonado;
  final double pagoPendiente;
  final bool pagado;
  final String pacienteId;
  final String pacienteNombre;
  final String creadorId;
  final String creadorNombre;
  final int cantidadCitasPlanificadas;
  final List<String> citas;
  final List<PresupuestoItem> presupuesto;

  Tratamiento({
    required this.id,
    required this.tratamiento,
    required this.diagnostico,
    required this.estado,
    required this.fechaCreacion,
    this.fechaUltimaActualizacion,
    required this.totalPresupuesto,
    required this.montoAbonado,
    required this.pagoPendiente,
    required this.pagado,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.creadorId,
    required this.creadorNombre,
    required this.cantidadCitasPlanificadas,
    required this.citas,
    required this.presupuesto,
  });

  factory Tratamiento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Tratamiento(
      id: doc.id,
      tratamiento: data['tratamiento'] ?? '',
      diagnostico: data['diagnostico'] ?? '',
      estado: data['estado'] ?? 'activo',
      fechaCreacion: (data['fecha_creacion'] as Timestamp).toDate(),
      fechaUltimaActualizacion: data['fecha_ultima_actualizacion'] != null
          ? (data['fecha_ultima_actualizacion'] as Timestamp).toDate()
          : null,
      totalPresupuesto: (data['total_presupuesto'] ?? 0).toDouble(),
      montoAbonado: (data['monto_abonado'] ?? 0).toDouble(),
      pagoPendiente: (data['pago_pendiente'] ?? 0).toDouble(),
      pagado: data['pagado'] ?? false,
      pacienteId: data['paciente_id'] ?? '',
      pacienteNombre: data['paciente_nombre'] ?? '',
      creadorId: data['creador_id'] ?? '',
      creadorNombre: data['creador_nombre'] ?? '',
      cantidadCitasPlanificadas: data['cantidad_citas_planificadas'] ?? 0,
      citas: data['citas'] != null 
          ? List<String>.from(data['citas'])
          : [],
      presupuesto: data['presupuesto'] != null
          ? (data['presupuesto'] as List)
              .map((item) => PresupuestoItem.fromMap(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tratamiento': tratamiento,
      'diagnostico': diagnostico,
      'estado': estado,
      'fecha_creacion': Timestamp.fromDate(fechaCreacion),
      'fecha_ultima_actualizacion': fechaUltimaActualizacion != null
          ? Timestamp.fromDate(fechaUltimaActualizacion!)
          : null,
      'total_presupuesto': totalPresupuesto,
      'monto_abonado': montoAbonado,
      'pago_pendiente': pagoPendiente,
      'pagado': pagado,
      'paciente_id': pacienteId,
      'paciente_nombre': pacienteNombre,
      'creador_id': creadorId,
      'creador_nombre': creadorNombre,
      'cantidad_citas_planificadas': cantidadCitasPlanificadas,
      'citas': citas,
      'presupuesto': presupuesto.map((item) => item.toMap()).toList(),
    };
  }
}