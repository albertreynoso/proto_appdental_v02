import 'package:flutter/material.dart';
import 'package:proto_appdental_v02/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    return PreferredSize(
      preferredSize: const Size.fromHeight(70), // Altura deseada
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
        // ELIMINA el SafeArea que envuelve todo
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(
              context,
            ).padding.top, // <-- Añade padding manual para la zona segura
            left: 20,
            right: 20,
            bottom: 8, // <-- Espacio inferior adicional si quieres
          ),
          child: Row(
            children: [
              // Logo de texto
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Bamboo',
                      style: TextStyle(
                        color: Color.fromARGB(255, 27, 163, 0),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Botón de usuario
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // Mostrar menú de usuario
                    _mostrarMenuUsuario();
                  },
                  icon: const Icon(
                    Icons.person_outline,
                    color: Colors.black,
                    size: 20,
                  ),
                  tooltip: 'Perfil',
                ),
              ),
            ],
          ),
        ),
      ),
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
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF3B82F6),
                    child: Text(
                      'AP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dr. Alberto Patiño',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'alberto.patino@dentlink.com',
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
                      // Navegar a perfil
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.fingerprint),
                    title: const Text('Preferencias de ingreso'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.pop(context);
                      // Navegar a preferencias de ingreso
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Preferencias de notificaciones'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.pop(context);
                      // Navegar a notificaciones
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Acerca de'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.pop(context);
                      // Navegar a about
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
          const Text(
            'Dr. Alberto Patiño',
            style: TextStyle(
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
        SizedBox(
          height: 140,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 4, // 4 citas
            itemBuilder: (context, index) {
              return _construirTarjetaCita(index);
            },
          ),
        ),
      ],
    );
  }

  /// Tarjeta de cita individual
  Widget _construirTarjetaCita(int index) {
    // Datos de ejemplo
    final citas = [
      {
        'paciente': 'María González',
        'fecha': 'Hoy, 10:00 AM',
        'tipo': 'Limpieza dental',
        'color': const Color(0xFF10B981),
      },
      {
        'paciente': 'Carlos López',
        'fecha': 'Mañana, 2:30 PM',
        'tipo': 'Ortodoncia',
        'color': const Color(0xFF3B82F6),
      },
      {
        'paciente': 'Ana Martínez',
        'fecha': 'Miércoles, 9:00 AM',
        'tipo': 'Consulta',
        'color': const Color(0xFFF59E0B),
      },
      {
        'paciente': 'Pedro Sánchez',
        'fecha': 'Jueves, 4:00 PM',
        'tipo': 'Extracción',
        'color': const Color(0xFFEF4444),
      },
    ];

    final cita = citas[index];

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12, left: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                    color: cita['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cita['paciente'] as String,
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
                  cita['fecha'] as String,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              cita['tipo'] as String,
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

  void _cerrarSesion() async {
    await AuthService().signout(context: context);
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
