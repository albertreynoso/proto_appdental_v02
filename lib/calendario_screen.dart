import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proto_appdental_v02/modals/citas_modal.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}
class _CalendarioScreenState extends State<CalendarioScreen> {
  bool _scrollInicializado = false;

  static const List<String> _horariosDisponibles = [
    '06:00',
    '06:30',
    '07:00',
    '07:30',
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
    '20:30',
    '21:00',
    '21:30',
    '22:00',
    '22:30',
    '23:00',
    '23:30',
  ];

  static const List<String> _nombresMeses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const int _diasVisibles = 3;
  static const Map<int, String> _nombresDias = {
    1: 'Lun',
    2: 'Mar',
    3: 'Mié',
    4: 'Jue',
    5: 'Vie',
    6: 'Sáb',
    7: 'Dom',
  };


  DateTime _fechaActual = DateTime.now(); 
  DateTime _horaActual = DateTime.now(); 
  Timer? _timer;
  bool _primeraCarga = true; 
  bool _mostrarCalendarioMensual = false;
  final Set<String> _fechasCargadas =
      {}; 
  double _dragOffset = 0.0;
  DateTime? _fechaPreview;

  final Map<String, List<Map<String, dynamic>>> _citasPorFecha =
      {}; 
  final ScrollController _controladorScrollVertical =
      ScrollController();

  double _alturaHora = 0; 
  double _anchoColumna = 0; 

  @override
  void initState() {
    super.initState();
    _iniciarTimerTiempoReal();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centrarEnHoraActual();
      _cargarCitas().then((_) {
        _precargarCitasAdyacentes();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    _anchoColumna = _calcularAnchoColumnas();
    _alturaHora = _calcularAltoFilas();


    if (_primeraCarga) {
      _primeraCarga = false;
      Future.microtask(() => _cargarCitas());
    }

    final diasVisibles = _obtenerDiasVisibles();
    final posicionLinea = _calcularPosicionLineaTiempo();
    final hoyVisible = _esHoyVisible(diasVisibles);

    return Scaffold(
      appBar: _construirAppBar(),
      body: Column(
        children: [
          _construirHeaderCalendario(),
          _construirCalendarioMensual(),
          _construirCabeceraDias(diasVisibles),
          Expanded(
            child: GestureDetector(
              onHorizontalDragStart: (DragStartDetails details) {
                setState(() {
                  _dragOffset = 0.0;
                });
              },
              onHorizontalDragUpdate: (DragUpdateDetails details) {
                setState(() {
                  _dragOffset += details.delta.dx;


                  final screenWidth = MediaQuery.of(context).size.width;
                  final diasDesplazados = (_dragOffset / screenWidth * 3)
                      .round();

                  if (diasDesplazados != 0) {
                    _fechaPreview = _fechaActual.subtract(
                      Duration(days: diasDesplazados * _diasVisibles),
                    );
                  } else {
                    _fechaPreview = null;
                  }
                });
              },
              onHorizontalDragEnd: (DragEndDetails details) {
                final screenWidth = MediaQuery.of(context).size.width;
                final threshold = screenWidth * 0.3;

                if (_dragOffset.abs() > threshold) {
                  if (_dragOffset > 0) {
                    
                    _diasAnteriores();
                  } else {
                    
                    _diasSiguientes();
                  }
                }

                setState(() {
                  _dragOffset = 0.0;
                  _fechaPreview = null;
                });
              },
              child: AnimatedContainer(
                duration: _dragOffset != 0
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(_dragOffset, 0, 0),
                child: Scrollbar(
                  controller: _controladorScrollVertical,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _controladorScrollVertical,
                    physics: const ClampingScrollPhysics(),
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _construirColumnaHoras(),
                            _construirGrillaDias(
                              _fechaPreview != null
                                  ? _obtenerDiasVisiblesDesde(_fechaPreview!)
                                  : diasVisibles,
                            ),
                          ],
                        ),
                        if (hoyVisible &&
                            posicionLinea >= 0 &&
                            _fechaPreview == null)
                          _construirLineaTiempoActual(posicionLinea),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoAgregarEvento(_fechaActual, '09:00'),
        tooltip: 'Agregar cita',
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _construirAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirCalendarioMensual() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _mostrarCalendarioMensual ? 340 : 0,
      curve: Curves.easeInOut,
      child: _mostrarCalendarioMensual
          ? Material(
              color: Colors.white,
              elevation: 2,
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.blue,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: _fechaActual,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  onDateChanged: (DateTime newDate) {
                    setState(() {
                      _fechaActual = newDate;
                      _mostrarCalendarioMensual = false;
                    });
                    _cargarCitas();
                  },
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
  
Widget _construirHeaderCalendario() {
  return SafeArea(
    bottom: false,
    child: Container(
      height: kToolbarHeight,
      decoration: BoxDecoration(
        color: Colors.white70,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 1,
            offset: Offset(0, 0.5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mostrarCalendarioMensual = !_mostrarCalendarioMensual;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _obtenerMesAnio(_fechaActual),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _mostrarCalendarioMensual 
                          ? Icons.expand_less 
                          : Icons.expand_more,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _construirControlesNavegacion(),
        ],
      ),
    ),
  );
}

Widget _construirControlesNavegacion() {
  return Row(
    children: [
      IconButton(
        icon: const Icon(Icons.chevron_left, color: Colors.black),
        onPressed: _diasAnteriores,
        tooltip: 'Días anteriores',
      ),
      IconButton(
        icon: const Icon(Icons.chevron_right, color: Colors.black),
        onPressed: _diasSiguientes,
        tooltip: 'Días siguientes',
      ),
    ],
  );
}

  Widget _construirCabeceraDias(List<DateTime> diasVisibles) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 50), 
          Expanded(
            child: Row(
              children: diasVisibles
                  .map(
                    (dia) => SizedBox(
                      width: _anchoColumna,
                      child: _construirEncabezadoDia(dia),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirColumnaHoras() {
    return Container(
      width: 50,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _horariosDisponibles
            .asMap()
            .entries
            .where((entry) => entry.key.isEven)
            .map((entry) {
              return Container(
                height: _alturaHora,
                padding: const EdgeInsets.only(right: 8, top: 4),
                alignment: Alignment.topRight,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              );
            })
            .toList(),
      ),
    );
  }

  Widget _construirGrillaDias(List<DateTime> diasVisibles) {
    return Expanded(
      child: SizedBox(
        width: 3 * _anchoColumna,
        child: Stack(
          children: [
            _construirFondoGrilla(diasVisibles),
            ..._construirCitasExtendidas(diasVisibles),
          ],
        ),
      ),
    );
  }

  Widget _construirFondoGrilla(List<DateTime> diasVisibles) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: (_horariosDisponibles.length / 2).ceil(),
      itemBuilder: (context, filteredIndex) {
        final hourIndex = filteredIndex * 2;
        return SizedBox(
          height: _alturaHora,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(
                    3,
                    (dayIndex) => _construirSlotVacio(
                      diasVisibles[dayIndex],
                      hourIndex,
                      false,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: List.generate(
                    3,
                    (dayIndex) => _construirSlotVacio(
                      diasVisibles[dayIndex],
                      hourIndex,
                      true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _construirCitasExtendidas(List<DateTime> diasVisibles) {
    final List<Widget> citasWidgets = [];

    for (final dia in diasVisibles) {
      final fechaStr = _formatearFecha(dia);
      final citasDelDia =
          List<Map<String, dynamic>>.from(_citasPorFecha[fechaStr] ?? [])
            ..removeWhere(
              (cita) =>
                  (cita['estado'] as String?)?.toLowerCase() == 'cancelada',
            );

      citasDelDia.sort((a, b) => a['hora_inicio'].compareTo(b['hora_inicio']));

      final List<DateTimeRange?> ocupaciones = [null, null, null, null];

      for (final cita in citasDelDia) {
        final inicio = _parsearHora(cita['hora_inicio']);
        final fin = _parsearHora(cita['hora_fin']);
        final rangoCita = DateTimeRange(start: inicio, end: fin);

        for (int i = 0; i < ocupaciones.length; i++) {
          final rango = ocupaciones[i];
          if (rango != null && rango.end.isBefore(inicio)) {
            ocupaciones[i] = null;
          }
        }

        int indiceAsignado = -1;
        for (int i = 0; i < ocupaciones.length; i++) {
          final rango = ocupaciones[i];
          if (rango == null ||
              rango.end.isAtSameMomentAs(inicio) ||
              rango.end.isBefore(inicio)) {
            indiceAsignado = i;
            break;
          }
        }

        if (indiceAsignado == -1) {
          indiceAsignado = _buscarSlotConMenorSolapamiento(
            ocupaciones,
            rangoCita,
          );
        }
        ocupaciones[indiceAsignado] = rangoCita;
        final widgetCita = _construirCitaExtendida(
          dia,
          cita,
          indiceEnSlot: indiceAsignado,
          totalSlots: 4,
        );

        if (widgetCita != null) citasWidgets.add(widgetCita);
      }
    }

    return citasWidgets;
  }

  int _buscarSlotConMenorSolapamiento(
    List<DateTimeRange?> ocupaciones,
    DateTimeRange nuevaCita,
  ) {
    double menorSolapamiento = double.infinity;
    int indiceMenor = 0;

    for (int i = 0; i < ocupaciones.length; i++) {
      final rango = ocupaciones[i];
      if (rango == null) return i; 
      final solapamiento = _calcularSolapamiento(rango, nuevaCita);
      if (solapamiento < menorSolapamiento) {
        menorSolapamiento = solapamiento;
        indiceMenor = i;
      }
    }

    return indiceMenor;
  }

  double _calcularSolapamiento(DateTimeRange a, DateTimeRange b) {
    final inicio = a.start.isAfter(b.start) ? a.start : b.start;
    final fin = a.end.isBefore(b.end) ? a.end : b.end;
    return fin.isBefore(inicio)
        ? 0
        : fin.difference(inicio).inMinutes.toDouble();
  }

  DateTime _parsearHora(String hora) {
    final partes = hora.split(':');
    return DateTime(0, 1, 1, int.parse(partes[0]), int.parse(partes[1]));
  }

  Widget? _construirCitaExtendida(
    DateTime dia,
    Map<String, dynamic> cita, {
    int indiceEnSlot = 0,
    int totalSlots = 1,
  }) {
    try {
      final duracion = cita['duracion_minutos'] ?? 60;
      final posicionTop = _calcularPosicionVertical(cita['hora_inicio']);
      if (posicionTop == -1) return null;

      final alturaTotal = _calcularAlturaCita(duracion);

      final indexDia = _obtenerDiasVisibles().indexOf(dia);

      if (indexDia == -1) return null;

      final anchoPorCita = (_anchoColumna - 2) / 4;

      final posicionLeft =
          (indexDia * _anchoColumna) + (anchoPorCita * indiceEnSlot);

      return Positioned(
        top: posicionTop,
        left: posicionLeft,
        width: anchoPorCita - 2,
        height: alturaTotal,
        child: _construirWidgetEventoExtendido(cita),
      );
    } catch (e) {
      print('❌ Error construyendo cita extendida: $e');
      return null;
    }
  }

  double _calcularPosicionVertical(String horaInicio) {
    try {
      final indexHora = _horariosDisponibles.indexOf(horaInicio);
      if (indexHora == -1) return -1;
      return (indexHora / 2) * _alturaHora;
    } catch (e) {
      return -1;
    }
  }

  double _calcularAlturaCita(int duracionMinutos) {
    final slotsOcupados = duracionMinutos / 30.0;
    return slotsOcupados * (_alturaHora / 2);
  }

  Color _obtenerColorPorEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'pendiente':
        return const Color(0xFFF59E0B);
      case 'confirmada':
        return const Color(0xFF10B981);
      case 'completada':
        return const Color(0xFF6B7280);
      case 'reprogramada':
        return const Color(0xFFF97316);
      case 'cancelada':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF10B981);
    }
  }

  Widget _construirWidgetEventoExtendido(Map<String, dynamic> cita) {
    final color = _obtenerColorPorEstado(cita['estado']);
    final duracion = cita['duracion_minutos'] ?? 60;
    final bool mostrarDetalles = duracion >= 30;

    return GestureDetector(
      onTap: () => _mostrarDetallesCita(cita),
      child: Container(
        margin: const EdgeInsets.only(right: 1, bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: mostrarDetalles
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cita['nombre_paciente'] ?? 'Paciente',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (duracion >= 60)
                    Text(
                      cita['tratamiento'] ?? '',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _construirSlotVacio(DateTime date, int hourIndex, bool isSecondSlot) {
    final hora = _horariosDisponibles[hourIndex];
    final horaCompleta = isSecondSlot ? _sumarMinutos(hora, 30) : hora;

    return Container(
      width: _anchoColumna,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey[200]!),
          bottom: isSecondSlot
              ? BorderSide(color: Colors.grey[200]!)
              : BorderSide.none,
        ),
      ),
      child: GestureDetector(
        onTap: () => _mostrarDialogoAgregarEvento(date, horaCompleta),
        child: Container(), 
      ),
    );
  }

  Widget _construirEncabezadoDia(DateTime date) {
    final isToday = _esMismoDia(date, DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? Colors.blue[100] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _nombresDias[date.weekday]!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isToday ? Colors.blue[700] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.blue[700] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirLineaTiempoActual(double posicionVertical) {
    return Positioned(
      top: posicionVertical,
      left: 50,
      right: 0,
      child: Stack(
        clipBehavior: Clip.none, 
        children: [
          Container(height: 1, color: Colors.red),
          Positioned(
            left: -6, 
            top: -4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarCitas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ Usuario no autenticado, omitiendo carga de citas');
      return;
    }

    try {
      for (int i = 0; i < _diasVisibles; i++) {
        final dia = DateTime(
          _fechaActual.year,
          _fechaActual.month,
          _fechaActual.day,
        ).add(Duration(days: i));

        final fechaStr = _formatearFecha(dia);

        if (_fechasCargadas.contains(fechaStr)) {
          continue;
        }

        final diaSiguiente = dia.add(const Duration(days: 1));

        print('🔍 Consultando citas para: $fechaStr');

        final snapshot = await FirebaseFirestore.instance
            .collection('citas')
            .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(dia))
            .where('fecha', isLessThan: Timestamp.fromDate(diaSiguiente))
            .get()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('⏰ Timeout consultando citas para $fechaStr');
                throw TimeoutException('Firestore timeout');
              },
            );

        print('✅ ${snapshot.docs.length} citas encontradas para $fechaStr');

        final citasDelDia = <Map<String, dynamic>>[];

        for (var doc in snapshot.docs) {
          final cita = doc.data();
          final Timestamp? fechaTimestamp = cita['fecha'] as Timestamp?;
          if (fechaTimestamp == null) continue;

          final horaInicio = (cita['hora'] as String?) ?? '09:00';
          final duracionMin =
              int.tryParse(cita['duracion']?.toString() ?? '30') ?? 30;
          final horaFin = _sumarMinutos(horaInicio, duracionMin);

          citasDelDia.add({
            'id': doc.id,
            'nombre_paciente': cita['paciente_nombre'] ?? 'Sin nombre',
            'hora_inicio': horaInicio,
            'hora_fin': horaFin,
            'duracion_minutos': duracionMin,
            'estado': cita['estado'] ?? 'pendiente',
            'tratamiento': cita['tipo_consulta'] ?? '',
            'paciente_id': cita['paciente_id'] ?? '',
            'es_tratamiento': cita['es_tratamiento'] ?? false,
            'notas': cita['notas_observaciones'] ?? '',
          });
        }

        if (mounted) {
          setState(() {
            _citasPorFecha[fechaStr] = citasDelDia;
            _fechasCargadas.add(fechaStr);
          });
        }
      }

      _debugCitas();
    } catch (e) {
      print('❌ Error cargando citas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar citas: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _precargarCitasAdyacentes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final diasAnteriores = DateTime(
      _fechaActual.year,
      _fechaActual.month,
      _fechaActual.day,
    ).subtract(const Duration(days: _diasVisibles));

    final diasSiguientes = DateTime(
      _fechaActual.year,
      _fechaActual.month,
      _fechaActual.day,
    ).add(Duration(days: _diasVisibles * 2));

    try {
      for (int i = 0; i < _diasVisibles; i++) {
        final dia = diasAnteriores.add(Duration(days: i));
        final fechaStr = _formatearFecha(dia);

        if (_fechasCargadas.contains(fechaStr)) continue;

        final diaSiguiente = dia.add(const Duration(days: 1));

        final snapshot = await FirebaseFirestore.instance
            .collection('citas')
            .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(dia))
            .where('fecha', isLessThan: Timestamp.fromDate(diaSiguiente))
            .get();

        final citasDelDia = <Map<String, dynamic>>[];

        for (var doc in snapshot.docs) {
          final cita = doc.data();
          final Timestamp? fechaTimestamp = cita['fecha'] as Timestamp?;
          if (fechaTimestamp == null) continue;

          final horaInicio = (cita['hora'] as String?) ?? '09:00';
          final duracionMin =
              int.tryParse(cita['duracion']?.toString() ?? '30') ?? 30;
          final horaFin = _sumarMinutos(horaInicio, duracionMin);

          citasDelDia.add({
            'id': doc.id,
            'nombre_paciente': cita['paciente_nombre'] ?? 'Sin nombre',
            'hora_inicio': horaInicio,
            'hora_fin': horaFin,
            'duracion_minutos': duracionMin,
            'estado': cita['estado'] ?? 'pendiente',
            'tratamiento': cita['tipo_consulta'] ?? '',
            'paciente_id': cita['paciente_id'] ?? '',
            'es_tratamiento': cita['es_tratamiento'] ?? false,
            'notas': cita['notas_observaciones'] ?? '',
          });
        }

        if (mounted) {
          setState(() {
            _citasPorFecha[fechaStr] = citasDelDia;
            _fechasCargadas.add(fechaStr);
          });
        }
      }

      for (int i = 0; i < _diasVisibles; i++) {
        final dia = diasSiguientes.add(Duration(days: i));
        final fechaStr = _formatearFecha(dia);

        if (_fechasCargadas.contains(fechaStr)) continue;

        final diaSiguiente = dia.add(const Duration(days: 1));

        final snapshot = await FirebaseFirestore.instance
            .collection('citas')
            .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(dia))
            .where('fecha', isLessThan: Timestamp.fromDate(diaSiguiente))
            .get();

        final citasDelDia = <Map<String, dynamic>>[];

        for (var doc in snapshot.docs) {
          final cita = doc.data();
          final Timestamp? fechaTimestamp = cita['fecha'] as Timestamp?;
          if (fechaTimestamp == null) continue;

          final horaInicio = (cita['hora'] as String?) ?? '09:00';
          final duracionMin =
              int.tryParse(cita['duracion']?.toString() ?? '30') ?? 30;
          final horaFin = _sumarMinutos(horaInicio, duracionMin);

          citasDelDia.add({
            'id': doc.id,
            'nombre_paciente': cita['paciente_nombre'] ?? 'Sin nombre',
            'hora_inicio': horaInicio,
            'hora_fin': horaFin,
            'duracion_minutos': duracionMin,
            'estado': cita['estado'] ?? 'pendiente',
            'tratamiento': cita['tipo_consulta'] ?? '',
            'paciente_id': cita['paciente_id'] ?? '',
            'es_tratamiento': cita['es_tratamiento'] ?? false,
            'notas': cita['notas_observaciones'] ?? '',
          });
        }

        if (mounted) {
          setState(() {
            _citasPorFecha[fechaStr] = citasDelDia;
            _fechasCargadas.add(fechaStr);
          });
        }
      }
    } catch (e) {
      print('❌ Error pre-cargando citas adyacentes: $e');
    }
  }

  void _iniciarTimerTiempoReal() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() => _horaActual = DateTime.now());
      }
    });
  }

  double _calcularPosicionLineaTiempo() {
    final now = _horaActual;
    final startOfDay = DateTime(now.year, now.month, now.day, 6, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 30);

    if (now.isBefore(startOfDay) || now.isAfter(endOfDay)) return -1;

    final totalMinutes = endOfDay.difference(startOfDay).inMinutes;
    final minutesFromStart = now.difference(startOfDay).inMinutes;
    final progress = minutesFromStart / totalMinutes;
    final alturaTotal = _alturaHora * (_horariosDisponibles.length / 2);

    return progress * alturaTotal;
  }

  void _mostrarDetallesCita(Map<String, dynamic> cita) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Cita'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paciente: ${cita['nombre_paciente']}'),
            Text('Horario: ${cita['hora_inicio']} - ${cita['hora_fin']}'),
            Text('Duración: ${cita['duracion_minutos']} minutos'),
            Text('Tratamiento: ${cita['tratamiento']}'),
            Text('Estado: ${cita['estado']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAgregarEvento(DateTime fecha, String hora) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.95,
        child: CitaModal(
          date: fecha,
          hour: hora,
          onSave: (datosAtencion) async {
            try {
              await FirebaseFirestore.instance.collection('atenciones').add({
                ...datosAtencion,
                'fecha': Timestamp.fromDate(datosAtencion['fecha']),
                'fechaCreacion': Timestamp.now(),
              });
              if (mounted) _cargarCitas();
            } catch (e) {
              debugPrint('Error al guardar cita: $e');
            }
          },
        ),
      ),
    );
  }

  bool _esHoyVisible(List<DateTime> diasVisibles) =>
      diasVisibles.any((dia) => _esMismoDia(dia, DateTime.now()));
  bool _esMismoDia(DateTime date1, DateTime date2) =>
      date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
  List<DateTime> _obtenerDiasVisibles() => List.generate(
    _diasVisibles,
    (index) => _fechaActual.add(Duration(days: index)),
  );
  List<DateTime> _obtenerDiasVisiblesDesde(DateTime fecha) => List.generate(
  _diasVisibles,
  (index) => fecha.add(Duration(days: index)),
);
  String _obtenerMesAnio(DateTime fecha) =>
      '${_nombresMeses[fecha.month - 1]} ${fecha.year}';
  String _formatearFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  double _calcularAnchoColumnas() => MediaQuery.of(context).size.width / 3.5;
  double _calcularAltoFilas() {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight - kToolbarHeight - 32) * 0.7 / 5;
  }

  void _diasAnteriores() {
  setState(() => _fechaActual = _fechaActual.subtract(
    const Duration(days: _diasVisibles),
  ));
  _cargarCitas().then((_) => _precargarCitasAdyacentes());
}

void _diasSiguientes() {
  setState(() => _fechaActual = _fechaActual.add(
    const Duration(days: _diasVisibles),
  ));
  _cargarCitas().then((_) => _precargarCitasAdyacentes());
}

  void _debugCitas() {
    print('=== 🗓️ DEBUG CITAS CARGADAS ===');
    print('📊 Total de fechas: ${_citasPorFecha.length}');

    _citasPorFecha.forEach((fecha, citas) {
      print('\n📅 $fecha: ${citas.length} citas');
      for (var cita in citas) {
        print(
          '   👤 ${cita['nombre_paciente']} | ⏰ ${cita['hora_inicio']}-${cita['hora_fin']}',
        );
      }
    });
    print('================================\n');
  }

  void _centrarEnHoraActual() {
    if (_scrollInicializado) return;

    try {
      final posicionLinea = _calcularPosicionLineaTiempo();

      final diasVisibles = _obtenerDiasVisibles();
      final hoyVisible = _esHoyVisible(diasVisibles);

      if (hoyVisible && posicionLinea >= 0) {
        final scrollOffset = _calcularOffsetScroll(posicionLinea);

        _controladorScrollVertical.animateTo(
          scrollOffset,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );

        _scrollInicializado = true;
        print(
          '🎯 Calendario centrado en hora actual: ${DateFormat('HH:mm').format(_horaActual)}',
        );
      }
    } catch (e) {
      print('❌ Error al centrar calendario: $e');
    }
  }

  double _calcularOffsetScroll(double posicionLinea) {
    final viewportHeight =
        MediaQuery.of(context).size.height - kToolbarHeight * 2 - 32;
    final contenidoHeight = _alturaHora * (_horariosDisponibles.length / 2);

    final posicionDeseada = posicionLinea - (viewportHeight / 2) + 100;

    return posicionDeseada.clamp(0.0, contenidoHeight - viewportHeight);
  }
  String _sumarMinutos(String hora, int minutos) {
    final parts = hora.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]) + minutos;

    hour += minute ~/ 60;
    minute = minute % 60;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
