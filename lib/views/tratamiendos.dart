import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proto_appdental_v02/modals/tratamiento_model.dart';
import 'package:proto_appdental_v02/modals/cita_model.dart';
import 'package:proto_appdental_v02/views/tratamiento_nuevo.dart';
import 'package:proto_appdental_v02/views/tratamiento_detalle.dart';

class TratamiendosScreen extends StatefulWidget {
  final Map<String, dynamic> paciente;

  const TratamiendosScreen({super.key, required this.paciente});

  @override
  State<TratamiendosScreen> createState() => _TratamiendosScreenState();
}

class _TratamiendosScreenState extends State<TratamiendosScreen> {
  List<Tratamiento> _tratamientos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es');
    _cargarTratamientos();
  }

  Future<void> _cargarTratamientos() async {
    try {
      setState(() => _isLoading = true);

      final snapshot = await FirebaseFirestore.instance
          .collection('tratamientos')
          .where('paciente_id', isEqualTo: widget.paciente['id'])
          .get();

      final List<Tratamiento> tratamientosList = snapshot.docs
          .map((doc) => Tratamiento.fromFirestore(doc))
          .toList();

      // Ordenar por fecha de creación descendente
      tratamientosList.sort(
        (a, b) => b.fechaCreacion.compareTo(a.fechaCreacion),
      );

      if (mounted) {
        setState(() {
          _tratamientos = tratamientosList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarMensajeError('Error al cargar tratamientos: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando tratamientos...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_tratamientos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay tratamientos registrados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los planes de tratamiento del paciente aparecerán aquí',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarTratamientos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tratamientos.length,
        itemBuilder: (context, index) {
          return _buildTratamientoCard(_tratamientos[index]);
        },
      ),
    );
  }

  Widget _buildTratamientoCard(Tratamiento tratamiento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del tratamiento
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.medical_services,
                      color: Colors.grey.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tratamiento.tratamiento,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    _buildEstadoBadge(tratamiento.estado),
                    if (tratamiento.pagado) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Pagado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Separador entre header y cuerpo
          Divider(height: 1, thickness: 1, color: Colors.grey[200]),

          // Cuerpo del tratamiento con fondo blanco Y BORDES INFERIORES REDONDOS
          Container(
            decoration: BoxDecoration(
              color: Colors.white, // Fondo blanco
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Diagnóstico
                  Text(
                    'Diagnóstico:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      tratamiento.diagnostico,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botón Ver Detalle Completo
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TratamientoDetalle(
                              tratamiento: tratamiento,
                              paciente: widget.paciente,
                            ),
                          ),
                        ).then((_) => _cargarTratamientos());
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ver Detalle'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey!),
                        foregroundColor: Colors.green,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color color;
    String texto;

    switch (estado.toLowerCase()) {
      case 'activo':
        color = Colors.green;
        texto = 'Activo';
        break;
      case 'completado':
        color = Colors.blue;
        texto = 'Completado';
        break;
      case 'cancelado':
        color = Colors.red;
        texto = 'Cancelado';
        break;
      default:
        color = Colors.grey;
        texto = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NuevoTratamiento(paciente: widget.paciente),
          ),
        ).then((_) => _cargarTratamientos());
      },
      tooltip: 'Agregar Tratamiento',
      backgroundColor: Colors.green,
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  void _mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: _cargarTratamientos,
        ),
      ),
    );
  }
}