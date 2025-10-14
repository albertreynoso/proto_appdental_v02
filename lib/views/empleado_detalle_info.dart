import 'package:flutter/material.dart';

class EmpleadoDetalleInformacion extends StatelessWidget {
  /// Mapa con los datos del empleado a mostrar
  final Map<String, dynamic> empleado;

  /// Constructor
  const EmpleadoDetalleInformacion({Key? key, required this.empleado}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información Personal
        const Text(
          'Datos Personales',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem('Nombres', empleado['nombres']?.toString() ?? ''),
        _buildInfoItem(
          'Apellido Paterno',
          empleado['apellido_paterno']?.toString() ?? '',
        ),
        _buildInfoItem(
          'Apellido Materno',
          empleado['apellido_materno']?.toString() ?? '',
        ),
        _buildInfoItem('DNI', empleado['dni_empleado']?.toString() ?? ''),
        _buildInfoItem('Edad', empleado['edad']?.toString() ?? ''),
        _buildInfoItem('Género', empleado['genero']?.toString() ?? ''),
        _buildInfoItem(
          'Fecha de Nacimiento',
          _formatearFecha(empleado['fecha_nacimiento']),
        ),

        const SizedBox(height: 16),

        // Información de Contacto
        const Text(
          'Información de Contacto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem('Dirección', empleado['direccion']?.toString() ?? ''),
        _buildInfoItem(
          'Teléfono',
          empleado['numero_telefonico']?.toString() ?? '',
        ),

        const SizedBox(height: 16),

        // Información Laboral
        const Text(
          'Información Laboral',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          'Tipo de Empleado',
          empleado['tipo_empleado_id']?.toString() ?? '',
        ),
        _buildInfoItem('Salario', _formatearSalario(empleado['salario'])),
        _buildInfoItem(
          'Fecha de Contratación',
          _formatearFecha(empleado['fecha_contratacion']),
        ),
      ],
    );;
  }
  /// Ítem de información con etiqueta y valor
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : 'No disponible',
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  /// Formatea una fecha ISO string a formato legible
  String _formatearFecha(dynamic fechaInput) {
    if (fechaInput == null) return 'No disponible';

    try {
      String fechaString;

      if (fechaInput is String) {
        fechaString = fechaInput;
      } else if (fechaInput is DateTime) {
        fechaString = fechaInput.toIso8601String();
      } else {
        return fechaInput.toString();
      }

      final fecha = DateTime.parse(fechaString);
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    } catch (e) {
      return fechaInput.toString();
    }
  }
  String _formatearSalario(dynamic salario) {
    if (salario == null) return 'No disponible';

    try {
      final numero = salario is int
          ? salario
          : int.tryParse(salario.toString());
      if (numero == null) return salario.toString();

      return 'S/. ${numero.toStringAsFixed(2)}';
    } catch (e) {
      return salario.toString();
    }
  }
}