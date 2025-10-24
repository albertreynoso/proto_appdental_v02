import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proto_appdental_v02/modals/citas_modal.dart';

// ======================================================================
// CALENDARIO SCREEN - PANTALLA PRINCIPAL DEL CALENDARIO MÉDICO
// ======================================================================

/// Pantalla principal que muestra un calendario interactivo para gestión de citas médicas.
///
/// CARACTERÍSTICAS PRINCIPALES:
/// - Vista de 3 días con slots horarios de 30 minutos
/// - Línea de tiempo en tiempo real que muestra la hora actual
/// - Gestión visual de citas con duraciones variables
/// - Navegación entre fechas y selección de slots
/// - Integración con Firestore para persistencia de datos
class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

// ======================================================================
// ESTADO DEL CALENDARIO - LÓGICA PRINCIPAL
// ======================================================================

class _CalendarioScreenState extends State<CalendarioScreen> {
  // ================================
  // CONFIGURACIÓN Y CONSTANTES
  // ================================

  bool _scrollInicializado = false;

  /// Horarios disponibles para agendar citas (formato HH:MM)
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
  ];

  /// Nombres de meses para mostrar en la interfaz
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

  /// Configuración de días visibles y nombres de días
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

  // ================================
  // ESTADO DE LA APLICACIÓN
  // ================================

  DateTime _fechaActual = DateTime.now(); // Fecha actualmente visualizada
  DateTime _horaActual = DateTime.now(); // Hora actual para línea de tiempo
  Timer? _timer; // Timer para actualizaciones en tiempo real
  bool _cargandoCitas = false; // Estado de carga de citas

  final Map<String, List<Map<String, dynamic>>> _citasPorFecha =
      {}; // Almacenamiento de citas por fecha
  final ScrollController _controladorScrollVertical =
      ScrollController(); // Control de scroll vertical

  late final double _alturaHora =
      _calcularAltoFilas(); // Altura dinámica de slots horarios
  late final double _anchoColumna =
      _calcularAnchoColumnas(); // Ancho dinámico de columnas de días

  // ================================
  // CICLO DE VIDA DEL WIDGET
  // ================================

  @override
  void initState() {
    super.initState();
    _cargarCitas();
    _iniciarTimerTiempoReal();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centrarEnHoraActual();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Limpieza del timer para evitar fugas de memoria
    super.dispose();
  }

  // ================================
  // MÉTODOS PRINCIPALES DE INTERFAZ
  // ================================

  @override
  Widget build(BuildContext context) {
    final diasVisibles = _obtenerDiasVisibles();
    final posicionLinea = _calcularPosicionLineaTiempo();
    final hoyVisible = _esHoyVisible(diasVisibles);

    return Scaffold(
      appBar: _construirAppBar(),
      body: _cargandoCitas
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _construirHeaderCalendario(),
                _construirCabeceraDias(diasVisibles),
                Expanded(
                  child: Scrollbar(
                    controller: _controladorScrollVertical,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _controladorScrollVertical,
                      child: Stack(
                        children: [
                          // NUEVA ESTRUCTURA
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _construirColumnaHoras(),
                              _construirGrillaDias(
                                diasVisibles,
                              ), // ← ESTE ES EL NUEVO
                            ],
                          ),
                          if (hoyVisible && posicionLinea >= 0)
                            _construirLineaTiempoActual(posicionLinea),
                        ],
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

  // ================================
  // COMPONENTES DE INTERFAZ PRINCIPALES
  // ================================

  /// AppBar personalizado con branding de la aplicación
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

  /// Header del calendario con controles de navegación
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
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Column(
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
              ),
            ),
            _construirControlesNavegacion(),
          ],
        ),
      ),
    );
  }

  /// Controles de navegación para el calendario
  Widget _construirControlesNavegacion() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.today, color: Colors.black),
          onPressed: _mostrarSelectorFechas,
          tooltip: 'Otras fechas',
        ),
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

  /// Cabecera con los días de la semana visibles
  Widget _construirCabeceraDias(List<DateTime> diasVisibles) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 50), // Espacio para columna de horas
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

  /// Columna lateral con las horas del día
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
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              );
            })
            .toList(),
      ),
    );
  }

  /// Grilla principal con los días y slots horarios
  Widget _construirGrillaDias(List<DateTime> diasVisibles) {
    return Expanded(
      child: SizedBox(
        width: 3 * _anchoColumna,
        child: Stack(
          // ← CAMBIAR A STACK
          children: [
            // Fondo de la grilla con slots
            _construirFondoGrilla(diasVisibles),
            // CITAS SOBREPUESTAS que abarcan múltiples slots
            ..._construirCitasExtendidas(diasVisibles),
          ],
        ),
      ),
    );
  }

  /// Construye la grilla base con todos los slots vacíos
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
              // Primera media hora
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
              // Segunda media hora
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

  /// Construye widgets de citas que se extienden sobre múltiples slots
  List<Widget> _construirCitasExtendidas(List<DateTime> diasVisibles) {
    final List<Widget> citasWidgets = [];

    for (final dia in diasVisibles) {
      final fechaStr = _formatearFecha(dia);
      final citasDelDia = _citasPorFecha[fechaStr] ?? [];

      for (final cita in citasDelDia) {
        final widgetCita = _construirCitaExtendida(dia, cita);
        if (widgetCita != null) {
          citasWidgets.add(widgetCita);
        }
      }
    }

    return citasWidgets;
  }

  Widget? _construirCitaExtendida(DateTime dia, Map<String, dynamic> cita) {
    try {
      final horaInicio = cita['hora_inicio'];
      final horaFin = cita['hora_fin'];
      final duracion = cita['duracion_minutos'] ?? 60;

      // 1. ENCONTRAR POSICIÓN VERTICAL (top)
      final posicionTop = _calcularPosicionVertical(horaInicio);
      if (posicionTop == -1) return null;

      // 2. CALCULAR ALTURA TOTAL
      final alturaTotal = _calcularAlturaCita(duracion);

      // 3. ENCONTRAR POSICIÓN HORIZONTAL (left)
      final indexDia = _obtenerDiasVisibles().indexOf(dia);
      if (indexDia == -1) return null;

      final posicionLeft =
          (indexDia * _anchoColumna); // 50 = ancho columna horas

      return Positioned(
        top: posicionTop,
        left: posicionLeft,
        width: _anchoColumna - 2, // Un poco menos para el margen
        height: alturaTotal,
        child: _construirWidgetEventoExtendido(cita),
      );
    } catch (e) {
      print('❌ Error construyendo cita extendida: $e');
      return null;
    }
  }

  /// Calcula la posición vertical (top) basada en la hora de inicio
  double _calcularPosicionVertical(String horaInicio) {
    try {
      final indexHora = _horariosDisponibles.indexOf(horaInicio);
      if (indexHora == -1) return -1;

      // Cada slot ocupa _alturaHora/2 de altura (30 minutos)
      return (indexHora / 2) * _alturaHora;
    } catch (e) {
      return -1;
    }
  }

  /// Calcula la altura total que debe ocupar la cita
  double _calcularAlturaCita(int duracionMinutos) {
    // Cada 30 minutos = _alturaHora/2 de altura
    final slotsOcupados = duracionMinutos / 30.0;
    return slotsOcupados * (_alturaHora / 2);
  }

  Widget _construirWidgetEventoExtendido(Map<String, dynamic> cita) {
    return GestureDetector(
      onTap: () => _mostrarDetallesCita(cita),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: cita['color'] ?? Colors.blue,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Nombre del paciente
            Text(
              cita['nombre_paciente'] ?? 'Paciente',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // Tratamiento
            Text(
              cita['tratamiento'] ?? 'Consulta',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
        child: Container(), // Slot vacío pero clickeable
      ),
    );
  }

  /// Encabezado individual para cada día
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

  /// Línea que indica la hora actual en el calendario
  Widget _construirLineaTiempoActual(double posicionVertical) {
    return Positioned(
      top: posicionVertical,
      left: 50,
      right: 0,
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          color: Colors.blueGrey,
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.5),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(color: Colors.grey),
            Positioned(
              left: -4,
              top: -3,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey,
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
      ),
    );
  }

  // ================================
  // LÓGICA DE GESTIÓN DE CITAS
  // ================================

  /// Carga citas desde Firestore o genera datos de ejemplo
  Future<void> _cargarCitas() async {
    try {
      if (_cargandoCitas) return;

      setState(() => _cargandoCitas = true);
      _citasPorFecha.clear();

      // NOTA: Actualmente usando datos de ejemplo
      // Para usar Firestore, descomentar el código siguiente
      final citasEjemplo = _generarCitasEjemplo();
      _citasPorFecha.addAll(citasEjemplo);

      _debugCitas(); // Log de depuración
      setState(() => _cargandoCitas = false);
    } catch (e) {
      print('❌ Error cargando citas: $e');
      setState(() => _cargandoCitas = false);
    }
  }

  /* CÓDIGO FIRESTORE (DESCOMENTAR PARA USAR)
  Future<void> _cargarCitasFirestore() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('citas')
        .where('fecha_cita', isEqualTo: _formatearFecha(_fechaActual))
        .get();

    _citasPorFecha.clear();

    for (var doc in snapshot.docs) {
      final cita = doc.data();
      final fechaCita = cita['fecha_cita'] ?? '';

      if (fechaCita.isNotEmpty) {
        _citasPorFecha.putIfAbsent(fechaCita, () => []).add({
          'id': doc.id,
          ...cita,
          'hora_inicio': cita['hora_cita'] ?? '09:00',
          'hora_fin': cita['hora_fin'] ?? '10:00',
          'duracion_minutos': cita['duracion_minutos'] ?? 60,
          'color': _obtenerColorTratamiento(cita['tratamiento']),
        });
      }
    }
    setState(() {});
  }
  */

  // ================================
  // MÉTODOS DE UTILIDAD Y LÓGICA
  // ================================

  /// Inicia el timer para actualizar la hora actual
  void _iniciarTimerTiempoReal() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() => _horaActual = DateTime.now());
      }
    });
  }

  /// Calcula la posición vertical de la línea de tiempo
  double _calcularPosicionLineaTiempo() {
    final now = _horaActual;
    final startOfDay = DateTime(now.year, now.month, now.day, 6, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 0);

    if (now.isBefore(startOfDay) || now.isAfter(endOfDay)) return -1;

    final totalMinutes = endOfDay.difference(startOfDay).inMinutes;
    final minutesFromStart = now.difference(startOfDay).inMinutes;
    final progress = minutesFromStart / totalMinutes;
    final alturaTotal = _alturaHora * (_horariosDisponibles.length / 2);

    return progress * alturaTotal;
  }

  // ================================
  // MÉTODOS DE NAVEGACIÓN
  // ================================

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

  void _mostrarSelectorFechas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Fecha'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: CalendarDatePicker(
            initialDate: _fechaActual,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            onDateChanged: (DateTime newDate) {
              setState(() => _fechaActual = newDate);
              Navigator.of(context).pop();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(onPressed: _irAHoy, child: const Text('Hoy')),
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
              if (mounted) setState(() {});
            } catch (e) {
              debugPrint('Error al guardar cita: $e');
            }
          },
        ),
      ),
    );
  }

  // ================================
  // MÉTODOS AUXILIARES
  // ================================

  // Métodos de utilidad compactados para mejor legibilidad
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
  String _obtenerMesAnio(DateTime fecha) =>
      '${_nombresMeses[fecha.month - 1]} ${fecha.year}';
  String _formatearFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  double _calcularAnchoColumnas() => MediaQuery.of(context).size.width / 3.5;
  double _calcularAltoFilas() {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = Scaffold.of(context).appBarMaxHeight ?? kToolbarHeight;
    return (screenHeight - appBarHeight - 32) * 0.7 / 5;
  }

  void _irAHoy() => setState(() => _fechaActual = DateTime.now());
  void _diasAnteriores() => setState(
    () => _fechaActual = _fechaActual.subtract(
      const Duration(days: _diasVisibles),
    ),
  );
  void _diasSiguientes() => setState(
    () => _fechaActual = _fechaActual.add(const Duration(days: _diasVisibles)),
  );

  // ================================
  // MÉTODOS DE DATOS DE EJEMPLO
  // ================================

  /// Genera citas de ejemplo para testing y demostración
  Map<String, List<Map<String, dynamic>>> _generarCitasEjemplo() {
    final citasEjemplo = <String, List<Map<String, dynamic>>>{};
    final hoy = DateTime.now();

    // Citas para hoy
    citasEjemplo[_formatearFecha(hoy)] = [
      _crearCitaEjemplo(
        '1',
        'María González',
        '09:00',
        '10:00',
        60,
        'Limpieza dental',
        Colors.blue,
      ),
      _crearCitaEjemplo(
        '2',
        'Carlos López',
        '11:30',
        '12:30',
        60,
        'Consulta',
        Colors.green,
      ),
      _crearCitaEjemplo(
        '3',
        'Ana Martínez',
        '14:00',
        '15:30',
        90,
        'Ortodoncia',
        Colors.purple,
      ),
      _crearCitaEjemplo(
        '4',
        'Pedro Sánchez',
        '16:00',
        '16:30',
        30,
        'Extracción dental',
        Colors.orange,
      ),
    ];

    // Citas para días siguientes
    citasEjemplo[_formatearFecha(hoy.add(const Duration(days: 1)))] = [
      _crearCitaEjemplo(
        '5',
        'Laura Rodríguez',
        '10:00',
        '11:30',
        90,
        'Blanqueamiento',
        Colors.teal,
      ),
    ];

    citasEjemplo[_formatearFecha(hoy.add(const Duration(days: 2)))] = [
      _crearCitaEjemplo(
        '6',
        'Jorge Fernández',
        '08:30',
        '09:00',
        30,
        'Revisión',
        Colors.blueGrey,
      ),
      _crearCitaEjemplo(
        '7',
        'Sofía Herrera',
        '15:00',
        '16:30',
        90,
        'Implante dental',
        Colors.green,
      ),
    ];

    return citasEjemplo;
  }

  /// Helper para crear citas de ejemplo de forma consistente
  Map<String, dynamic> _crearCitaEjemplo(
    String id,
    String paciente,
    String inicio,
    String fin,
    int duracion,
    String tratamiento,
    Color color,
  ) {
    return {
      'id': id,
      'nombre_paciente': paciente,
      'hora_inicio': inicio,
      'hora_fin': fin,
      'duracion_minutos': duracion,
      'tratamiento': tratamiento,
      'color': color,
      'estado': 'confirmada',
    };
  }

  /// Debug para ver las citas cargadas en consola
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

  // ================================
  // UTILIDADES DE MANEJO DE TIEMPO
  // ================================

  /// Centra el calendario en la hora actual automáticamente
  void _centrarEnHoraActual() {
    if (_scrollInicializado) return;

    try {
      final posicionLinea = _calcularPosicionLineaTiempo();

      // Solo centrar si estamos viendo el día actual y la línea es visible
      final diasVisibles = _obtenerDiasVisibles();
      final hoyVisible = _esHoyVisible(diasVisibles);

      if (hoyVisible && posicionLinea >= 0) {
        // Calcular la posición de scroll para centrar la línea
        final scrollOffset = _calcularOffsetScroll(posicionLinea);

        // Animar el scroll suavemente a la posición
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

  /// Calcula el offset de scroll necesario para centrar la línea de tiempo
  double _calcularOffsetScroll(double posicionLinea) {
    final viewportHeight =
        MediaQuery.of(context).size.height - kToolbarHeight * 2 - 32;
    final contenidoHeight = _alturaHora * (_horariosDisponibles.length / 2);

    // Posición deseada: línea en el centro de la pantalla menos margen superior
    final posicionDeseada = posicionLinea - (viewportHeight / 2) + 100;

    // Asegurar que no nos salgamos de los límites del scroll
    return posicionDeseada.clamp(0.0, contenidoHeight - viewportHeight);
  }

  /// Suma minutos a una hora en formato string
  String _sumarMinutos(String hora, int minutos) {
    final parts = hora.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]) + minutos;

    hour += minute ~/ 60;
    minute = minute % 60;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
