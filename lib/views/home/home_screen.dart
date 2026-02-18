import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:proto_appdental_v02/core/auth_service.dart';
import 'package:proto_appdental_v02/core/pin_service.dart';
import 'package:proto_appdental_v02/models/cita_model.dart';
import 'package:proto_appdental_v02/views/auth/login.dart';
import 'package:proto_appdental_v02/views/auth/login_con_pin.dart';
import 'package:proto_appdental_v02/views/perfil/editar_perfil.dart';
import 'package:proto_appdental_v02/views/perfil/preferencias_ingreso.dart';
import 'package:proto_appdental_v02/views/perfil/preferencias_notificaciones.dart';
import 'package:proto_appdental_v02/views/perfil/acerca_de.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _usuarioData;
  List<Cita> _citasProximas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _cargarCitasProximas();
  }

  Future<void> _cargarCitasProximas() async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('citas')
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(hoy))
          .orderBy('fecha')
          .limit(20)
          .get();
      if (!mounted) return;
      final todas = snapshot.docs
          .map((doc) => Cita.fromFirestore(doc))
          .toList();
      setState(() {
        _citasProximas = todas
            .where((c) => c.estado == 'pendiente' || c.estado == 'confirmada')
            .take(10)
            .toList();
      });
    } catch (e) {
      debugPrint('Error cargando citas: $e');
    }
  }

  String _formatearFechaCita(Cita cita) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fechaCita = DateTime(
      cita.fecha.year,
      cita.fecha.month,
      cita.fecha.day,
    );
    final diff = fechaCita.difference(hoy).inDays;

    final horaFormateada = cita.hora;

    if (diff == 0) return 'Hoy, $horaFormateada';
    if (diff == 1) return 'Mañana, $horaFormateada';

    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final nombreDia = dias[cita.fecha.weekday - 1];
    return '$nombreDia, $horaFormateada';
  }

  Color _colorPorEstado(String estado) {
    return switch (estado) {
      'pendiente' => const Color(0xFFF59E0B),
      'confirmada' => const Color(0xFF10B981),
      _ => const Color(0xFF3B82F6),
    };
  }

  Future<void> _cargarDatosUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    if (mounted) setState(() => _usuarioData = doc.data());
  }

  String get _nombreMostrar {
    final nombre = _usuarioData?['nombre'] ?? '';
    final ap = _usuarioData?['apellidoPaterno'] ?? '';
    final full = '$nombre $ap'.trim();
    return full.isEmpty ? '...' : full;
  }

  String get _iniciales {
    final nombre = (_usuarioData?['nombre'] ?? '').toString();
    final ap = (_usuarioData?['apellidoPaterno'] ?? '').toString();
    final n = nombre.isNotEmpty ? nombre[0] : '';
    final a = ap.isNotEmpty ? ap[0] : '';
    final result = '$n$a'.toUpperCase();
    return result.isEmpty ? '?' : result;
  }

  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _construirAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo
            _construirSaludo(),

            const SizedBox(height: 24),

            // Sección: Citas próximas
            _construirSeccionCitasProximas(),

            const SizedBox(height: 32),

            // Sección: Últimas atenciones
            _construirSeccionUltimasAtenciones(),

            const SizedBox(height: 32),

            // Sección: Sobre ti
            _construirSeccionSobreTi(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Construye la barra de aplicación
  PreferredSizeWidget _construirAppBar() {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: false,
    shadowColor: const Color(0x0A000000),
    title: const Text(
      'BAMBOO',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Color(0xFF2E7D32),
        letterSpacing: -1,
      ),
    ),
    titleSpacing: 20,
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F6),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: _mostrarMenuUsuario,
            icon: const Icon(
              Icons.person_outline,
              color: Colors.black,
              size: 20,
            ),
            tooltip: 'Perfil',
          ),
        ),
      ),
    ],
  );
}

  void _mostrarMenuUsuario() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // ← IMPORTANTE: Permite controlar el scroll
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Avatar y nombre
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF3B82F6),
                    child: Text(
                      _iniciales,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nombreMostrar,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Opciones del menú
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Mis detalles personales'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditarPerfil()),
                      ).then((_) => _cargarDatosUsuario());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.fingerprint),
                    title: const Text('Preferencias de ingreso'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PreferenciasIngreso(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Preferencias de notificaciones'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PreferenciasNotificaciones(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Acerca de'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AcercaDe()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _cerrarSesion();
                    },
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Saludo personalizado
  Widget _construirSaludo() {
    final hora = DateTime.now().hour;
    String saludo = 'Buenos días';

    if (hora >= 12 && hora < 18) {
      saludo = 'Buenas tardes';
    } else if (hora >= 18) {
      saludo = 'Buenas noches';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            saludo,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _nombreMostrar,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Sección: Citas próximas
  Widget _construirSeccionCitasProximas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Citas próximas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navegar a ver todas las citas
                },
                child: const Text('Ver todas'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_citasProximas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 40,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tienes citas próximas',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _citasProximas.length,
              itemBuilder: (context, index) {
                return _construirTarjetaCita(_citasProximas[index]);
              },
            ),
          ),
      ],
    );
  }

  /// Tarjeta de cita individual
  Widget _construirTarjetaCita(Cita cita) {
    final color = _colorPorEstado(cita.estado);
    final fechaTexto = _formatearFechaCita(cita);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12, left: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cita.pacienteNombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  fechaTexto,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              cita.tipoConsulta,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sección: Últimas atenciones
  Widget _construirSeccionUltimasAtenciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Últimas atenciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navegar a ver todas las atenciones
                },
                child: const Text('Ver todas'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 4, // 4 atenciones
          itemBuilder: (context, index) {
            return _construirTarjetaAtencion(index);
          },
        ),
      ],
    );
  }

  /// Tarjeta de atención individual
  Widget _construirTarjetaAtencion(int index) {
    // Datos de ejemplo
    final atenciones = [
      {
        'paciente': 'Laura Rodríguez',
        'fecha': 'Hace 2 horas',
        'tipo': 'Blanqueamiento',
        'icono': Icons.cleaning_services,
      },
      {
        'paciente': 'Jorge Fernández',
        'fecha': 'Ayer',
        'tipo': 'Revisión',
        'icono': Icons.visibility,
      },
      {
        'paciente': 'Sofía Herrera',
        'fecha': 'Hace 2 días',
        'tipo': 'Implante dental',
        'icono': Icons.build,
      },
      {
        'paciente': 'Miguel Torres',
        'fecha': 'Hace 3 días',
        'tipo': 'Endodoncia',
        'icono': Icons.healing,
      },
    ];

    final atencion = atenciones[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            atencion['icono'] as IconData,
            color: const Color(0xFF10B981),
          ),
        ),
        title: Text(
          atencion['paciente'] as String,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              atencion['tipo'] as String,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              atencion['fecha'] as String,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () {
          // Ver detalles de la atención
        },
      ),
    );
  }

  /// Sección: Sobre ti
  Widget _construirSeccionSobreTi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Sobre ti',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: InkWell(
            onTap: () {
              // Navegar a pantalla de estadísticas con tabs
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EstadisticasScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ver mis estadísticas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Asistencia, puntualidad y más',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _cerrarSesion() async {
    await AuthService().signout();
    if (!mounted) return;
    final hasPin = await PinService().hasPinConfigured();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => hasPin ? const LoginConPin() : const Login(),
      ),
    );
  }
}

// ============================================================================
// PANTALLA DE ESTADÍSTICAS CON TABS
// ============================================================================

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen>
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mis estadísticas',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3B82F6),
          tabs: const [
            Tab(text: 'Asistencia'),
            Tab(text: 'Puntualidad'),
            Tab(text: 'Mi actividad'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _construirTabAsistencia(),
          _construirTabPuntualidad(),
          _construirTabActividad(),
        ],
      ),
    );
  }

  Widget _construirTabAsistencia() {
    return const Center(child: Text('Tab Asistencia - Por implementar'));
  }

  Widget _construirTabPuntualidad() {
    return const Center(child: Text('Tab Puntualidad - Por implementar'));
  }

  Widget _construirTabActividad() {
    return const Center(child: Text('Tab Mi Actividad - Por implementar'));
  }
}
