import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'clientes_detalle.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  // ========== VARIABLES DE ESTADO ==========

  List<Map<String, dynamic>> _pacientes = [];
  List<Map<String, dynamic>> _pacientesFiltrados = [];
  bool _isLoading = true;
  static const String _collectionName = 'pacientes';
  
  // Variables para búsqueda y filtros
  final TextEditingController _searchController = TextEditingController();
  String _filtroActual = 'Todos'; // Todos, Con tratamiento, Sin tratamiento
  String _ordenActual = 'Nombre A-Z'; // Nombre A-Z, Nombre Z-A, Recientes

  // ========== CICLO DE VIDA ==========

  @override
  void initState() {
    super.initState();
    _cargarPacientes();
    _searchController.addListener(_filtrarPacientes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========== MÉTODOS DE DATOS ==========

  Future<void> _cargarPacientes() async {
    try {
      setState(() => _isLoading = true);

      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .orderBy('apellido_paterno', descending: false)
          .get();

      final List<Map<String, dynamic>> pacientesList = snapshot.docs
          .map((DocumentSnapshot doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      if (mounted) {
        setState(() {
          _pacientes = pacientesList;
          _pacientesFiltrados = pacientesList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarMensajeError('Error al cargar pacientes: $e');
      }
    }
  }

  void _filtrarPacientes() {
    setState(() {
      String query = _searchController.text.toLowerCase();
      
      _pacientesFiltrados = _pacientes.where((paciente) {
        // Filtrar por búsqueda
        final nombreCompleto = _obtenerNombreCompleto(paciente).toLowerCase();
        final dni = (paciente['dni_cliente'] ?? '').toString().toLowerCase();
        final coincideBusqueda = nombreCompleto.contains(query) || dni.contains(query);
        
        if (!coincideBusqueda) return false;
        
        // Filtrar por estado
        final bool isActive = paciente['activo'] ?? true;
        if (_filtroActual == 'Con tratamiento' && !isActive) return false;
        if (_filtroActual == 'Sin tratamiento' && isActive) return false;
        
        return true;
      }).toList();
      
      // Ordenar
      _aplicarOrden();
    });
  }

  void _aplicarOrden() {
    switch (_ordenActual) {
      case 'Nombre A-Z':
        _pacientesFiltrados.sort((a, b) => 
          _obtenerNombreCompleto(a).compareTo(_obtenerNombreCompleto(b))
        );
        break;
      case 'Nombre Z-A':
        _pacientesFiltrados.sort((a, b) => 
          _obtenerNombreCompleto(b).compareTo(_obtenerNombreCompleto(a))
        );
        break;
      case 'Recientes':
        // Asumiendo que tienen un campo de fecha de creación
        _pacientesFiltrados.sort((a, b) {
          final fechaA = a['fecha_creacion'] as Timestamp?;
          final fechaB = b['fecha_creacion'] as Timestamp?;
          if (fechaA == null || fechaB == null) return 0;
          return fechaB.compareTo(fechaA);
        });
        break;
    }
  }

  // ========== UI ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _construirAppBar(),
      body: Column(
        children: [
          _construirBarraBusquedaFiltros(),
          Expanded(child: _buildListaPacientes()),
        ],
      ),
    );
  }

  PreferredSizeWidget _construirAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
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
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 20,
            right: 20,
            bottom: 8,
          ),
          child: Row(
            children: [
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirBarraBusquedaFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          // Barra de búsqueda
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Botón de filtro
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(22),
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_list,
                color: Colors.grey[800],
                size: 20,
              ),
              onPressed: _mostrarMenuFiltros,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Botón de ordenar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(22),
            ),
            child: IconButton(
              icon: Icon(
                Icons.sort,
                color: Colors.grey[800],
                size: 20,
              ),
              onPressed: _mostrarMenuOrden,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaPacientes() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_pacientesFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay pacientes registrados'
                  : 'No se encontraron resultados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPacientes,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _pacientesFiltrados.length,
        itemBuilder: (context, index) {
          return _construirTarjetaPaciente(_pacientesFiltrados[index]);
        },
      ),
    );
  }

  Widget _construirTarjetaPaciente(Map<String, dynamic> paciente) {
    final bool isActive = paciente['activo'] ?? true;
    final String dni = paciente['dni_cliente'] ?? 'No especificado';

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
            color: const Color.fromARGB(255, 88, 90, 89).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person,
            color: const Color.fromARGB(255, 88, 90, 89),
          ),
        ),
        title: Text(
          _obtenerNombreCompleto(paciente),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'DNI: $dni',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF10B981) : Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isActive ? 'Con tratamiento' : 'Sin tratamiento',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? const Color(0xFF10B981) : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClientesDetalle(paciente: paciente),
            ),
          );
        },
      ),
    );
  }
  // ========== DIÁLOGOS ==========

  void _mostrarMenuFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Filtrar por',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _construirOpcionFiltro('Todos'),
                _construirOpcionFiltro('Con tratamiento'),
                _construirOpcionFiltro('Sin tratamiento'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _construirOpcionFiltro(String opcion) {
    final bool seleccionado = _filtroActual == opcion;
    
    return ListTile(
      title: Text(opcion),
      trailing: seleccionado
          ? const Icon(Icons.check, color: Color(0xFF3B82F6))
          : null,
      onTap: () {
        setState(() {
          _filtroActual = opcion;
        });
        _filtrarPacientes();
        Navigator.pop(context);
      },
    );
  }

  void _mostrarMenuOrden() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Ordenar por',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _construirOpcionOrden('Nombre A-Z'),
                _construirOpcionOrden('Nombre Z-A'),
                _construirOpcionOrden('Recientes'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _construirOpcionOrden(String opcion) {
    final bool seleccionado = _ordenActual == opcion;
    
    return ListTile(
      title: Text(opcion),
      trailing: seleccionado
          ? const Icon(Icons.check, color: Color(0xFF3B82F6))
          : null,
      onTap: () {
        setState(() {
          _ordenActual = opcion;
        });
        _filtrarPacientes();
        Navigator.pop(context);
      },
    );
  }

  // ========== UTILIDADES ==========

  String _obtenerNombreCompleto(Map<String, dynamic> paciente) {
    final String nombreCompleto = paciente['nombre_completo'] ??
        '${paciente['nombre']} ${paciente['apellido_paterno']}';
    return nombreCompleto;
  }

  void _mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}