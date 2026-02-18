import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proto_appdental_v02/views/citas/cita_nueva.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() =>
      _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  bool _scrollInicializado = false;

  static const List<String> _horariosDisponibles = [
    '01:00',
    '01:30',
    '02:00',
    '02:30',
    '03:00',
    '03:30',
    '04:00',
    '04:30',
    '05:00',
    '05:30',
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

  int get _diasVisibles => _vistaSeleccionada;
  static const Map<int, String> _nombresDias = {
    1: 'Lu',
    2: 'Ma',
    3: 'Mi',
    4: 'Ju',
    5: 'Vi',
    6: 'Sa',
    7: 'Do',
  };

  static const Map<int, String> _nombresDiasCompletos = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    7: 'Domingo',
  };

  DateTime _fechaActual = DateTime.now();
  DateTime _horaActual = DateTime.now();
  Timer? _timer;
  bool _primeraCarga = true;
  final Set<String> _fechasCargadas = {};
  double _dragOffset = 0.0;
  DateTime? _fechaPreview;
  bool _calendarioExpandido = false;
  int _vistaSeleccionada = 3;
  double _dragOffsetMes = 0.0;
  DateTime _mesCalendario = DateTime(DateTime.now().year, DateTime.now().month);

  final Map<String, List<Map<String, dynamic>>> _citasPorFecha = {};
  final ScrollController _controladorScrollVertical = ScrollController();

  double _alturaHora = 0;
  double _anchoColumna = 0;

  @override
  void initState() {
    super.initState();
    _iniciarTimerTiempoReal();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centrarEnHoraActual();
      _cargarCitas().then((_) => _precargarCitasAdyacentes());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controladorScrollVertical.dispose();
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _construirHeaderCalendario(),
          _construirCalendarioMensual(diasVisibles),
          _construirCabeceraDias(diasVisibles),
          Expanded(
            child: GestureDetector(
              onHorizontalDragStart: (details) =>
                  setState(() => _dragOffset = 0.0),
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragOffset += details.delta.dx;
                  final screenWidth = MediaQuery.of(context).size.width;
                  final diasDesplazados = (_dragOffset / screenWidth * _diasVisibles)
                      .round();

                  _fechaPreview = diasDesplazados != 0
                      ? _fechaActual.subtract(
                          Duration(days: diasDesplazados * _diasVisibles),
                        )
                      : null;
                });
              },
              onHorizontalDragEnd: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                final threshold = screenWidth * 0.25;

                if (_dragOffset.abs() > threshold) {
                  _dragOffset > 0 ? _diasAnteriores() : _diasSiguientes();
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
                child: Container(
                  color: Colors.white,
                  child: Scrollbar(
                    controller: _controladorScrollVertical,
                    thumbVisibility: false,
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarANuevaCita(_fechaActual, '09:00'),
        backgroundColor: const Color.fromARGB(255, 113, 206, 6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _construirHeaderCalendario() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: Colors.white,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _calendarioExpandido = !_calendarioExpandido),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _nombresMeses[_mesCalendario.month - 1],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _calendarioExpandido ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.black54,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _construirSelectorDias(),
          ],
        ),
      ),
    );
  }

  Widget _construirSelectorDias() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _construirBotonVista(1, '1'),
          _construirBotonVista(3, '3'),
        ],
      ),
    );
  }

  Widget _construirBotonVista(int valor, String label) {
    final seleccionado = _vistaSeleccionada == valor;
    return GestureDetector(
      onTap: () => setState(() => _vistaSeleccionada = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado
              ? Colors.grey.shade500
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: seleccionado ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _construirCalendarioMensual(List<DateTime> diasVisibles) {
    final hoy = DateTime.now();

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: _calendarioExpandido
          ? GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() => _dragOffsetMes += details.delta.dx);
              },
              onHorizontalDragEnd: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                if (_dragOffsetMes.abs() > screenWidth * 0.2) {
                  setState(() {
                    if (_dragOffsetMes > 0) {
                      // Swipe derecha → mes anterior
                      _mesCalendario = DateTime(
                        _mesCalendario.year,
                        _mesCalendario.month - 1,
                      );
                    } else {
                      // Swipe izquierda → mes siguiente
                      _mesCalendario = DateTime(
                        _mesCalendario.year,
                        _mesCalendario.month + 1,
                      );
                    }
                  });
                }
                setState(() => _dragOffsetMes = 0.0);
              },
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Encabezado días de la semana
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: ['Do', 'Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa']
                            .map((d) => Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF9E9E9E),
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    // Grilla de días
                    ..._construirSemanasMes(_mesCalendario, hoy, diasVisibles),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  List<Widget> _construirSemanasMes(
    DateTime mes,
    DateTime hoy,
    List<DateTime> diasVisibles,
  ) {
    final primerDiaMes = DateTime(mes.year, mes.month, 1);
    final diasEnMes = DateTime(mes.year, mes.month + 1, 0).day;
    final offsetInicio = primerDiaMes.weekday % 7; // Domingo = 0

    final List<Widget> semanas = [];
    List<Widget> semanaActual = [];

    // Días del mes anterior (relleno)
    if (offsetInicio > 0) {
      final diasMesAnterior = DateTime(mes.year, mes.month, 0).day;
      for (int i = offsetInicio - 1; i >= 0; i--) {
        final dia = DateTime(mes.year, mes.month - 1, diasMesAnterior - i);
        semanaActual.add(_construirCeldaDia(dia, false, hoy, diasVisibles));
      }
    }

    // Días del mes actual
    for (int d = 1; d <= diasEnMes; d++) {
      final dia = DateTime(mes.year, mes.month, d);
      semanaActual.add(_construirCeldaDia(dia, true, hoy, diasVisibles));
      if (semanaActual.length == 7) {
        semanas.add(Row(children: semanaActual));
        semanaActual = [];
      }
    }

    // Días del mes siguiente (relleno para completar la última semana)
    if (semanaActual.isNotEmpty) {
      int dSig = 1;
      while (semanaActual.length < 7) {
        final dia = DateTime(mes.year, mes.month + 1, dSig++);
        semanaActual.add(_construirCeldaDia(dia, false, hoy, diasVisibles));
      }
      semanas.add(Row(children: semanaActual));
    }

    // Fila extra: primera semana del mes siguiente si el mes termina en sábado
    final ultimoDiaMostrado = DateTime(mes.year, mes.month, diasEnMes);
    final ultimoOffset = ultimoDiaMostrado.weekday % 7;
    if (ultimoOffset == 6) {
      // El mes termina en sábado, la siguiente semana es toda del mes siguiente
      List<Widget> semanaExtra = [];
      for (int d = 1; d <= 7; d++) {
        final dia = DateTime(mes.year, mes.month + 1, d);
        semanaExtra.add(_construirCeldaDia(dia, false, hoy, diasVisibles));
      }
      semanas.add(Row(children: semanaExtra));
    }

    return semanas;
  }

  Widget _construirCeldaDia(
    DateTime dia,
    bool esMesActual,
    DateTime hoy,
    List<DateTime> diasVisibles,
  ) {
    final esHoy = _esMismoDia(dia, hoy);
    final esSeleccionado = diasVisibles.any((d) => _esMismoDia(d, dia));

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _fechaActual = dia;
            _mesCalendario = DateTime(dia.year, dia.month);
            _calendarioExpandido = false;
          });
          _cargarCitas();
        },
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: esSeleccionado && !esHoy
                ? const Color(0xFFEEEEEE)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: esHoy
                  ? BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Center(
                child: Text(
                  dia.day.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: esHoy || esSeleccionado
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: esHoy
                        ? Colors.white
                        : esMesActual
                            ? Colors.black87
                            : const Color(0xFFBDBDBD),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirCabeceraDias(List<DateTime> diasVisibles) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 56),
          Expanded(
            child: Row(
              children: diasVisibles.map((dia) {
                final isToday = _esMismoDia(dia, DateTime.now());
                return Expanded(child: _construirEncabezadoDia(dia, isToday));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirEncabezadoDia(DateTime date, bool isToday) {
    return Column(
      children: [
        Text(
          _nombresDias[date.weekday]!,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isToday
                ? const Color.fromARGB(255, 113, 206, 6)
                : Colors.black45,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isToday
                ? const Color.fromARGB(255, 113, 206, 6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isToday ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirColumnaHoras() {
    return Container(
      width: 56,
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(right: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
      ),
      child: Column(
        children: List.generate((_horariosDisponibles.length / 2).ceil(), (
          index,
        ) {
          final hourIndex = index * 2;
          final hora = _horariosDisponibles[hourIndex];

          return Container(
            height: _alturaHora,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 2),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
              ),
            ),
            child: Text(
              hora,
              style: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _construirGrillaDias(List<DateTime> diasVisibles) {
    return Expanded(
      child: Stack(
        children: [
          _construirFondoGrilla(diasVisibles),
          ..._construirCitasExtendidas(diasVisibles),
        ],
      ),
    );
  }

  Widget _construirFondoGrilla(List<DateTime> diasVisibles) {
    return Column(
      // ✅ COLUMN, no ListView.builder
      children: List.generate((_horariosDisponibles.length / 2).ceil(), (
        index,
      ) {
        final hourIndex = index * 2;
        return Container(
          height: _alturaHora,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(
                    _diasVisibles,
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
                    _diasVisibles,
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
      }),
    );
  }

  Widget _construirSlotVacio(DateTime date, int hourIndex, bool isSecondSlot) {
    final hora = _horariosDisponibles[hourIndex];
    final horaCompleta = isSecondSlot ? _sumarMinutos(hora, 30) : hora;

    return Expanded(
      child: GestureDetector(
        onTap: () => _navegarANuevaCita(date, horaCompleta),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
            ),
          ),
        ),
      ),
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
          if (ocupaciones[i] != null && ocupaciones[i]!.end.isBefore(inicio)) {
            ocupaciones[i] = null;
          }
        }

        int indiceAsignado = -1;
        for (int i = 0; i < ocupaciones.length; i++) {
          if (ocupaciones[i] == null ||
              ocupaciones[i]!.end.isAtSameMomentAs(inicio) ||
              ocupaciones[i]!.end.isBefore(inicio)) {
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
          diasVisibles: diasVisibles,
          indiceEnSlot: indiceAsignado,
          totalSlots: 4,
        );

        if (widgetCita != null) citasWidgets.add(widgetCita);
      }
    }

    return citasWidgets;
  }

  Widget? _construirCitaExtendida(
    DateTime dia,
    Map<String, dynamic> cita, {
    required List<DateTime> diasVisibles,
    int indiceEnSlot = 0,
    int totalSlots = 1,
  }) {
    try {
      final duracion = cita['duracion_minutos'] ?? 60;
      final posicionTop = _calcularPosicionVertical(cita['hora_inicio']);
      if (posicionTop == -1) return null;

      final alturaTotal = _calcularAlturaCita(duracion);
      final indexDia = diasVisibles.indexWhere((d) => _esMismoDia(d, dia));
      if (indexDia == -1) return null;

      final anchoPorCita = _anchoColumna / 4;
      final posicionLeft =
          (indexDia * _anchoColumna) + (anchoPorCita * indiceEnSlot);

      return Positioned(
        top: posicionTop,
        left: posicionLeft,
        width: anchoPorCita - 1, // ✅ Reducido de -4 a -1 para más ancho
        height: alturaTotal,
        child: _construirWidgetEventoExtendido(cita),
      );
    } catch (e) {
      return null;
    }
  }

  Widget _construirWidgetEventoExtendido(Map<String, dynamic> cita) {
    final color = _obtenerColorPorEstado(cita['estado']);

    return GestureDetector(
      onTap: () => _mostrarDetallesCita(cita),
      child: Container(
        margin: const EdgeInsets.only(
          right: 0.5,
          bottom: 1,
          left: 0.5,
        ), // ✅ Márgenes mínimos
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4), // ✅ Bordes más pequeños
          color: color.withOpacity(0.12), // ✅ Fondo tenue
          border: Border(
            left: BorderSide(
              color: color,
              width: 3,
            ), // ✅ Línea izquierda intensa
          ),
        ),
      ),
    );
  }

  Widget _construirLineaTiempoActual(double posicionVertical) {
    final now = _horaActual;
    final horaFormateada = DateFormat('HH:mm').format(now);

    return Positioned(
      top: posicionVertical,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 56,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              horaFormateada,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 113, 206, 6),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 113, 206, 6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          113,
                          206,
                          6,
                        ).withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: -1,
                  top: -3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 113, 206, 6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            113,
                            206,
                            6,
                          ).withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares y funcionalidad de Firebase (mantener los existentes)
  Future<void> _cargarCitas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      for (int i = 0; i < _diasVisibles; i++) {
        final dia = DateTime(
          _fechaActual.year,
          _fechaActual.month,
          _fechaActual.day,
        ).add(Duration(days: i));
        final fechaStr = _formatearFecha(dia);

        if (_fechasCargadas.contains(fechaStr)) continue;

        final diaSiguiente = dia.add(const Duration(days: 1));
        final snapshot = await FirebaseFirestore.instance
            .collection('citas')
            .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(dia))
            .where('fecha', isLessThan: Timestamp.fromDate(diaSiguiente))
            .get()
            .timeout(const Duration(seconds: 10));

        final citasDelDia = <Map<String, dynamic>>[];
        for (var doc in snapshot.docs) {
          final cita = doc.data();
          final fechaTimestamp = cita['fecha'] as Timestamp?;
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
      debugPrint('Error cargando citas: $e');
    }
  }

  Future<void> _precargarCitasAdyacentes() async {
    // Implementación igual que en el código original
  }

  void _mostrarDetallesCita(Map<String, dynamic> cita) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _obtenerColorPorEstado(cita['estado']),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cita['nombre_paciente'] ?? 'Paciente',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${cita['hora_inicio']} - ${cita['hora_fin']}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _construirDetalleFila(
              Icons.medical_services,
              'Tratamiento',
              cita['tratamiento'] ?? 'No especificado',
            ),
            _construirDetalleFila(
              Icons.access_time,
              'Duración',
              '${cita['duracion_minutos']} minutos',
            ),
            _construirDetalleFila(
              Icons.info_outline,
              'Estado',
              cita['estado'] ?? 'Pendiente',
            ),
            if ((cita['notas'] ?? '').isNotEmpty)
              _construirDetalleFila(Icons.note, 'Notas', cita['notas']),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirDetalleFila(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAgregarEvento(DateTime fecha, String hora) {
    _navegarANuevaCita(fecha, hora);
  }

  void _iniciarTimerTiempoReal() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() => _horaActual = DateTime.now());
    });
  }

  double _calcularPosicionLineaTiempo() {
    final now = _horaActual;
    final startOfDay = DateTime(now.year, now.month, now.day, 1, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 30);

    if (now.isBefore(startOfDay) || now.isAfter(endOfDay)) return -1;

    final totalMinutes = endOfDay.difference(startOfDay).inMinutes;
    final minutesFromStart = now.difference(startOfDay).inMinutes;
    final progress = minutesFromStart / totalMinutes;
    final alturaTotal = _alturaHora * (_horariosDisponibles.length / 2);

    return progress * alturaTotal;
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
      }
    } catch (e) {
      debugPrint('Error al centrar calendario: $e');
    }
  }

  double _calcularOffsetScroll(double posicionLinea) {
    final viewportHeight =
        MediaQuery.of(context).size.height - kToolbarHeight * 2 - 32;
    final contenidoHeight = _alturaHora * (_horariosDisponibles.length / 2);
    final posicionDeseada = posicionLinea - (viewportHeight / 2) + 100;
    return posicionDeseada.clamp(0.0, contenidoHeight - viewportHeight);
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

  List<DateTime> _obtenerDiasVisiblesDesde(DateTime fecha) =>
      List.generate(_diasVisibles, (index) => fecha.add(Duration(days: index)));



  String _formatearFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  double _calcularAnchoColumnas() =>
      (MediaQuery.of(context).size.width - 56) / _diasVisibles;

  double _calcularAltoFilas() {
    final screenHeight = MediaQuery.of(context).size.height;
    final alturaBase = (screenHeight - kToolbarHeight - 120) * 0.85 / 12;
    return _vistaSeleccionada == 1 ? alturaBase * 2 : alturaBase;
  }

  void _diasAnteriores() {
    setState(
      () => _fechaActual = _fechaActual.subtract(
        Duration(days: _diasVisibles),
      ),
    );
    _cargarCitas().then((_) => _precargarCitasAdyacentes());
  }

  void _diasSiguientes() {
    setState(
      () =>
          _fechaActual = _fechaActual.add(Duration(days: _diasVisibles)),
    );
    _cargarCitas().then((_) => _precargarCitasAdyacentes());
  }

  String _sumarMinutos(String hora, int minutos) {
    final parts = hora.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]) + minutos;

    hour += minute ~/ 60;
    minute = minute % 60;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<void> _navegarANuevaCita(DateTime fecha, String hora) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NuevaCitaScreen(fechaSeleccionada: fecha, horaSeleccionada: hora),
      ),
    );

    if (resultado == true) {
      await _cargarCitas();
    }
  }
}
