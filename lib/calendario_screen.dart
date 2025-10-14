import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proto_appdental_v02/modals/citas_modal.dart';

/// Pantalla principal del calendario de citas
///
/// Muestra una vista de calendario con slots de tiempo para agendar citas
/// Permite navegación por días y creación de nuevas citas
class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  // ========== CONSTANTES DE CONFIGURACIÓN ==========

  /// Horarios disponibles para citas (formato HH:mm)
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

  /// Nombres de los días de la semana (abreviados)
  static const List<String> _nombresDias = [
    'dom',
    'lun',
    'mar',
    'mié',
    'jue',
    'vie',
    'sáb',
  ];

  /// Nombres de los meses del año
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

  /// Dimensiones del calendario
  static const double _alturaSlotTiempo = 30.0;
  static const double _anchuraColumnaHora = 80.0;
  static const double _anchuraDia = 120.0;
  static const int _diasVisibles = 3;
  late final double _alturaHora = _calcularAltoFilas(context);
  late final double _anchoColumna = _calcularAnchoColumnas(context);

  // ========== VARIABLES DE ESTADO ==========

  /// Fecha actual seleccionada en el calendario
  DateTime _fechaActual = DateTime.now();

  /// Controlador para el scroll vertical (horas)
  final ScrollController _controladorScrollVertical = ScrollController();

  /// Controlador para el scroll horizontal (días)
  final ScrollController _controladorScrollHorizontal = ScrollController();

  // ========== MÉTODOS DE CONSTRUCCIÓN DE UI ==========

  @override
  Widget build(BuildContext context) {
    final diasVisibles = _obtenerDiasVisibles();

    return Scaffold(
      appBar: _construirAppBar(),
      body: Column(
        children: [
          _construirCabeceraZonaHoraria(diasVisibles),
          _construirGrillaCalendario(diasVisibles),
        ],
      ),
      floatingActionButton: _construirBotonFlotante(),
    );
  }

  /// Construye la barra de aplicación con navegación y título
  AppBar _construirAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _obtenerMesAnio(_fechaActual),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.today),
          onPressed: _mostrarSelectorFechas,
          tooltip: 'Otras fechas',
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _diasAnteriores,
          tooltip: 'Días anteriores',
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _diasSiguientes,
          tooltip: 'Días siguientes',
        ),
      ],
    );
  }

  /// Construye la cabecera con zona horaria y días visibles
  Widget _construirCabeceraZonaHoraria(List<DateTime> diasVisibles) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          SizedBox(width: 50),
          Expanded(
            child: Row(
              children: diasVisibles.map((dia) {
                return SizedBox(
                  width: _anchoColumna,
                  child: _construirEncabezadoDia(dia));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Calendario principal optimizado
  Widget _construirGrillaCalendario(List<DateTime> nextThreeDays) {
    return Expanded(
      child: Scrollbar(
        controller: _controladorScrollVertical,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _controladorScrollVertical,
          child: _buildCalendarGrid(nextThreeDays),
        ),
      ),
    );
  }

  /// Grid del calendario optimizado
  Widget _buildCalendarGrid(List<DateTime> nextThreeDays) {

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna de horas optimizada
        _buildHourColumn(50),
        // Grid de días optimizado
        _buildDaysGrid(nextThreeDays, _anchoColumna),
      ],
    );
  }

  /// Columna fija de horas
  /// Columna de horas optimizada - EVITA REDIBUJADOS
  Widget _buildHourColumn(double width) {
  return Container(
    width: width,
    decoration: BoxDecoration(
      border: Border(right: BorderSide(color: Colors.grey[300]!)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: _horariosDisponibles.asMap().entries.where((entry) {
        return entry.key.isEven; // Solo índices pares (0, 2, 4...)
      }).map((entry) {
        final index = entry.key;
        final hora = entry.value;
        return Container(
          height: _alturaHora,
          padding: const EdgeInsets.only(right: 8, top: 4),
          alignment: Alignment.topRight,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Text(
            hora,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        );
      }).toList(),
    ),
  );
}

  /// Grid de días con slots de hora subdivididos en dos partes
  /// Grid de días optimizado - MÁS EFICIENTE
  Widget _buildDaysGrid(List<DateTime> nextThreeDays, double anchoColumna) {
    return Expanded(
      child: SizedBox(
        width: 3 * anchoColumna,
        child: ListView.builder(
          physics:
              const NeverScrollableScrollPhysics(), // Deshabilita scroll interno
          shrinkWrap: true,
          itemCount: (_horariosDisponibles.length / 2).ceil(),
          itemBuilder: (context, filteredIndex) {
            // Convertir índice filtrado a índice original (0, 2, 4, 6...)
            final hourIndex = filteredIndex * 2;
            return _buildHourRow(nextThreeDays, hourIndex, anchoColumna);
          },
        ),
      ),
    );
  }

  /// Fila de hora optimizada
  Widget _buildHourRow(
    List<DateTime> nextThreeDays,
    int hourIndex,
    double anchoColumna,
  ) {
    return SizedBox(
      height: _alturaHora, // ALTURA UNIFICADA PARA AMBOS SUBSLOTS
      child: Column(
        children: [
          // Primer subslot
          Expanded(
            child: Row(
              children: List.generate(3, (dayIndex) {
                return _buildTimeSlotContainer(
                  nextThreeDays[dayIndex],
                  hourIndex,
                  false,
                  anchoColumna,
                );
              }),
            ),
          ),
          // Segundo subslot
          Expanded(
            child: Row(
              children: List.generate(3, (dayIndex) {
                return _buildTimeSlotContainer(
                  nextThreeDays[dayIndex],
                  hourIndex,
                  true,
                  anchoColumna,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// Contenedor de slot optimizado
  Widget _buildTimeSlotContainer(
    DateTime date,
    int hourIndex,
    bool isSecondSlot,
    double anchoColumna,
  ) {
    return Container(
      width: anchoColumna,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey[200]!),
          bottom: isSecondSlot
              ? BorderSide(color: Colors.grey[200]!)
              : BorderSide.none,
        ),
      ),
      child: _construirFranjaHoraria(date, hourIndex, isSecondSlot),
    );
  }

   /// Slot de hora para cada día subdividido
  Widget _construirFranjaHoraria(DateTime date, int hourIndex, bool isHalfHour) {
    // Calcula la hora a mostrar
    String hourStr = _horariosDisponibles[hourIndex];
    if (isHalfHour) {
      // Suma 30 minutos
      final parts = hourStr.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      minute += 30;
      if (minute >= 60) {
        hour += 1;
        minute = 0;
      }
      hourStr =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    // Aquí puedes obtener eventos para ese slot si lo deseas
    final events = _getEventsForTime(
      date,
      hourIndex,
    ); // Puedes adaptar esto si tienes eventos por media hora

    return GestureDetector(
      onTap: () => _mostrarDialogoAgregarEvento(date, hourStr),
      child: Container(
        color: events.isNotEmpty ? Colors.blue[50] : Colors.transparent,
        child: events.isNotEmpty ? _construirWidgetEvento(events.first) : null,
      ),
    );
  }

  /// Encabezado de cada día
  Widget _construirEncabezadoDia(DateTime date) {
    final isToday = _isSameDay(date, DateTime.now());

    // Mapeo directo de los días de la semana
    final dayNames = {
      1: 'Lun',
      2: 'Mar',
      3: 'Mié',
      4: 'Jue',
      5: 'Vie',
      6: 'Sáb',
      7: 'Dom',
    };

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
            dayNames[date.weekday]!,
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

 

  /// Construye el widget para mostrar un evento en el slot de tiempo
  Widget _construirWidgetEvento(String evento) {
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            evento,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 43, 117, 228),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Consultorio',
            style: TextStyle(fontSize: 8, color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  // ========== MÉTODOS DE UTILIDAD Y LÓGICA ==========

  //calcula el ancho dinámico
  double _calcularAnchoColumnas(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth / 3.5; // Restar columna de horas
    return availableWidth; // Dividir entre número de días
  }

  //calcula el alto dinámico
  double _calcularAltoFilas(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = Scaffold.of(context).appBarMaxHeight ?? kToolbarHeight;
    final paddingVertical = 32.0; // Padding superior e inferior

    final availableHeight = screenHeight - appBarHeight - paddingVertical;

    // Asignar el 70% del espacio disponible a la grilla del calendario
    final calendarHeight = availableHeight * 0.7;

    // Dividir entre número de horas visibles (8-10 horas típicas)
    final horasVisibles = 5; // Ajusta según necesites
    return calendarHeight / horasVisibles;
  }

  /// Obtiene los días visibles en el calendario (siguiente N días desde la fecha actual)
  List<DateTime> _obtenerDiasVisibles() {
    return List.generate(_diasVisibles, (index) {
      return _fechaActual.add(Duration(days: index));
    });
  }

  /// Devuelve el mes y año en formato legible
  String _obtenerMesAnio(DateTime fecha) {
    final indiceSeguro = (fecha.month - 1) % _nombresMeses.length;
    return '${_nombresMeses[indiceSeguro]} ${fecha.year}';
  }

  /// Devuelve el nombre del día y número
  String _formatDate(DateTime date) {
    final dayNames = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];
    final safeIndex = (date.weekday - 1) % dayNames.length;
    return '${dayNames[safeIndex]} ${date.day}';
  }

  /// Verifica si dos fechas son el mismo día
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Obtiene eventos para una hora específica (simulado)
  List<String> _getEventsForTime(DateTime date, int hourIndex) {
    if (date.day % 2 == 0 && hourIndex == 10) {
      return ['AUDITORÍA DE SISTEMAS AU'];
    }
    if (date.day % 3 == 0 && hourIndex == 14) {
      return ['CONSULTA MÉDICA'];
    }
    return [];
  }

  /// Obtiene eventos para el día (simulado)
  List<String> _getEventsForDay(DateTime date) {
    if (date.day % 2 == 0) {
      return ['AUDITORÍA DE SISTEMAS AU - 10:00'];
    }
    if (date.day % 3 == 0) {
      return ['CONSULTA MÉDICA - 14:00', 'REUNIÓN EQUIPO - 16:00'];
    }
    return [];
  }

  // ========== MÉTODOS DE NAVEGACIÓN ==========

  void _mostrarSelectorFechas() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar Fecha'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: CalendarDatePicker(
              initialDate: _fechaActual,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              onDateChanged: (DateTime newDate) {
                setState(() {
                  _fechaActual = newDate;
                });
                Navigator.of(
                  context,
                ).pop(); // Cerrar el modal después de seleccionar
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: _irAHoy, // Tu función existente para ir a hoy
              child: const Text('Hoy'),
            ),
          ],
        );
      },
    );
  }

  /// Navega al día actual
  void _irAHoy() {
    setState(() {
      _fechaActual = DateTime.now();
    });
  }

  /// Navega a los días anteriores
  void _diasAnteriores() {
    setState(() {
      _fechaActual = _fechaActual.subtract(Duration(days: _diasVisibles));
    });
  }

  /// Navega a los días siguientes
  void _diasSiguientes() {
    setState(() {
      _fechaActual = _fechaActual.add(Duration(days: _diasVisibles));
    });
  }

  /// Construye el botón flotante para agregar nueva cita
  Widget _construirBotonFlotante() {
    return FloatingActionButton(
      onPressed: () => _mostrarDialogoAgregarEvento(_fechaActual, '09:00'),
      tooltip: 'Agregar cita',
      child: const Icon(Icons.add),
    );
  }

  // ========== MÉTODOS DE INTERACCIÓN ==========

  /// Muestra el modal para agregar nueva cita en el slot seleccionado
  void _mostrarDialogoAgregarEvento(DateTime fecha, String hora) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
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
                if (mounted) {
                  setState(() {}); // Actualizar la vista después de guardar
                }
              } catch (e) {
                // TODO: Manejar error de guardado
                debugPrint('Error al guardar cita: $e');
              }
            },
          ),
        );
      },
    );
  }
}
