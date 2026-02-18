import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PacienteEditar extends StatefulWidget {
  final Map<String, dynamic> paciente;

  const PacienteEditar({Key? key, required this.paciente}) : super(key: key);

  @override
  State<PacienteEditar> createState() => _PacienteEditarState();
}

class _PacienteEditarState extends State<PacienteEditar> {
  final _formKey = GlobalKey<FormState>();
  bool _isGuardando = false;

  // Controllers para los campos de texto
  late TextEditingController _nombreController;
  late TextEditingController _apellidoPaternoController;
  late TextEditingController _apellidoMaternoController;
  late TextEditingController _dniController;
  late TextEditingController _celularController;
  late TextEditingController _telefonoFijoController;
  late TextEditingController _emailController;
  late TextEditingController _direccionController;
  late TextEditingController _distritoController;
  late TextEditingController _lugarProcedenciaController;
  late TextEditingController _ocupacionController;

  String? _sexoSeleccionado;
  String? _estadoCivilSeleccionado;
  DateTime? _fechaNacimiento;

  final List<String> _opcionesSexo = ['Masculino', 'Femenino'];
  final List<String> _opcionesEstadoCivil = [
    'Soltero',
    'Casado',
    'Divorciado',
    'Viudo',
    'Conviviente'
  ];

  @override
  void initState() {
    super.initState();
    _inicializarControllers();
  }

  void _inicializarControllers() {
    _nombreController = TextEditingController(text: widget.paciente['nombre'] ?? '');
    _apellidoPaternoController = TextEditingController(text: widget.paciente['apellido_paterno'] ?? '');
    _apellidoMaternoController = TextEditingController(text: widget.paciente['apellido_materno'] ?? '');
    _dniController = TextEditingController(text: widget.paciente['dni_cliente'] ?? '');
    _celularController = TextEditingController(text: widget.paciente['celular'] ?? '');
    _telefonoFijoController = TextEditingController(text: widget.paciente['telefono_fijo'] ?? '');
    _emailController = TextEditingController(text: widget.paciente['email'] ?? '');
    _direccionController = TextEditingController(text: widget.paciente['direccion'] ?? '');
    _distritoController = TextEditingController(text: widget.paciente['distrito_direccion'] ?? '');
    _lugarProcedenciaController = TextEditingController(text: widget.paciente['lugar_procedencia'] ?? '');
    _ocupacionController = TextEditingController(text: widget.paciente['ocupacion'] ?? '');

    _sexoSeleccionado = widget.paciente['sexo'];
    _estadoCivilSeleccionado = widget.paciente['estado_civil'];

    // Convertir Timestamp a DateTime
    if (widget.paciente['fecha_nacimiento'] != null) {
      if (widget.paciente['fecha_nacimiento'] is Timestamp) {
        _fechaNacimiento = (widget.paciente['fecha_nacimiento'] as Timestamp).toDate();
      } else if (widget.paciente['fecha_nacimiento'] is DateTime) {
        _fechaNacimiento = widget.paciente['fecha_nacimiento'];
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _dniController.dispose();
    _celularController.dispose();
    _telefonoFijoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _distritoController.dispose();
    _lugarProcedenciaController.dispose();
    _ocupacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSeccion(
                'Datos Personales',
                [
                  _buildTextField('Nombres', _nombreController, obligatorio: true),
                  const SizedBox(height: 16),
                  _buildTextField('Apellido Paterno', _apellidoPaternoController, obligatorio: true),
                  const SizedBox(height: 16),
                  _buildTextField('Apellido Materno', _apellidoMaternoController),
                  const SizedBox(height: 16),
                  _buildTextField('DNI', _dniController, 
                    teclado: TextInputType.number, 
                    maxLength: 8,
                    obligatorio: true,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown('Sexo', _sexoSeleccionado, _opcionesSexo, (valor) {
                    setState(() => _sexoSeleccionado = valor);
                  }),
                  const SizedBox(height: 16),
                  _buildDatePicker(),
                  const SizedBox(height: 16),
                  _buildDropdown('Estado Civil', _estadoCivilSeleccionado, _opcionesEstadoCivil, (valor) {
                    setState(() => _estadoCivilSeleccionado = valor);
                  }),
                  const SizedBox(height: 16),
                  _buildTextField('Ocupación', _ocupacionController),
                ],
              ),
              const SizedBox(height: 24),
              _buildSeccion(
                'Información de Contacto',
                [
                  _buildTextField('Celular', _celularController, 
                    teclado: TextInputType.phone,
                    obligatorio: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('Teléfono Fijo', _telefonoFijoController, 
                    teclado: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('Email', _emailController, 
                    teclado: TextInputType.emailAddress,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSeccion(
                'Ubicación',
                [
                  _buildTextField('Dirección', _direccionController),
                  const SizedBox(height: 16),
                  _buildTextField('Distrito', _distritoController),
                  const SizedBox(height: 16),
                  _buildTextField('Lugar de Procedencia', _lugarProcedenciaController),
                ],
              ),
              const SizedBox(height: 32),
              _buildBotonesAccion(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
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
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.black,
                    size: 14,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Editar Paciente',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType teclado = TextInputType.text,
    int? maxLength,
    bool obligatorio = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            if (obligatorio)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: teclado,
          maxLength: maxLength,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            counterText: '',
          ),
          validator: obligatorio
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? valorActual,
    List<String> opciones,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonFormField<String>(
            value: valorActual,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            hint: Text('Seleccionar $label'),
            items: opciones.map((opcion) {
              return DropdownMenuItem(
                value: opcion,
                child: Text(opcion),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha de Nacimiento',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _seleccionarFecha,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Text(
                  _fechaNacimiento != null
                      ? DateFormat('dd/MM/yyyy').format(_fechaNacimiento!)
                      : 'Seleccionar fecha',
                  style: TextStyle(
                    fontSize: 14,
                    color: _fechaNacimiento != null ? Colors.black : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonesAccion() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isGuardando ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isGuardando ? null : _guardarCambios,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isGuardando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Guardar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _fechaNacimiento) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  int _calcularEdad(DateTime fechaNacimiento) {
    final ahora = DateTime.now();
    int edad = ahora.year - fechaNacimiento.year;
    if (ahora.month < fechaNacimiento.month ||
        (ahora.month == fechaNacimiento.month && ahora.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      _mostrarMensaje('Por favor completa los campos obligatorios', esError: true);
      return;
    }

    setState(() => _isGuardando = true);

    try {
      final datosActualizados = <String, dynamic>{
        'nombre': _nombreController.text.trim(),
        'apellido_paterno': _apellidoPaternoController.text.trim(),
        'apellido_materno': _apellidoMaternoController.text.trim(),
        'dni_cliente': _dniController.text.trim(),
        'celular': _celularController.text.trim(),
        'telefono_fijo': _telefonoFijoController.text.trim(),
        'email': _emailController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'distrito_direccion': _distritoController.text.trim(),
        'lugar_procedencia': _lugarProcedenciaController.text.trim(),
        'ocupacion': _ocupacionController.text.trim(),
        'sexo': _sexoSeleccionado,
        'estado_civil': _estadoCivilSeleccionado,
      };

      if (_fechaNacimiento != null) {
        datosActualizados['fecha_nacimiento'] = Timestamp.fromDate(_fechaNacimiento!);
        datosActualizados['edad'] = _calcularEdad(_fechaNacimiento!);
      }

      await FirebaseFirestore.instance
          .collection('pacientes')
          .doc(widget.paciente['id'])
          .update(datosActualizados);

      if (mounted) {
        _mostrarMensaje('Paciente actualizado exitosamente');
        Navigator.pop(context, true); // Retornar true para indicar que se guardó
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGuardando = false);
        _mostrarMensaje('Error al guardar cambios: $e', esError: true);
      }
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}