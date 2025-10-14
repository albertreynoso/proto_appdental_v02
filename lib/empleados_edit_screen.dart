import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pantalla para editar empleados existentes de clínica dental
class EmpleadoEditarScreen extends StatefulWidget {
  final Map<String, dynamic> empleadoToEdit;

  const EmpleadoEditarScreen({super.key, required this.empleadoToEdit});

  @override
  State<EmpleadoEditarScreen> createState() => _EmpleadoEditarScreenState();
}

class _EmpleadoEditarScreenState extends State<EmpleadoEditarScreen> {
  // ========== CONTROLADORES ==========
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidoPaternoController = TextEditingController();
  final TextEditingController _apellidoMaternoController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _numeroTelefonicoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _salarioController = TextEditingController();
  final TextEditingController _fechaNacimientoController = TextEditingController();
  final TextEditingController _fechaContratacionController = TextEditingController();

  // ========== VARIABLES DE ESTADO ==========
  String _selectedGenero = 'masculino';
  String _selectedTipoEmpleado = 'odontologo';
  DateTime? _fechaNacimiento;
  DateTime? _fechaContratacion;
  bool _isLoading = false;

  // ========== CONSTANTES ==========
  static const String _collectionName = 'empleados';

  static const List<String> _generos = ['masculino', 'femenino', 'otro'];
  static const List<String> _tiposEmpleado = [
    'odontologo',
    'asistente_dental',
    'recepcionista',
    'higienista',
    'administrador'
  ];

  static const Map<String, String> _generoLabels = {
    'masculino': 'Masculino',
    'femenino': 'Femenino',
    'otro': 'Otro',
  };

  static const Map<String, String> _tipoEmpleadoLabels = {
    'odontologo': 'Odontólogo',
    'asistente_dental': 'Asistente Dental',
    'recepcionista': 'Recepcionista',
    'higienista': 'Higienista Dental',
    'administrador': 'Administrador',
  };

  // ========== CICLO DE VIDA ==========
  @override
  void initState() {
    super.initState();
    _cargarDatosEmpleado();
  }

  void _cargarDatosEmpleado() {
    final Map<String, dynamic> empleado = widget.empleadoToEdit;
    
    _nombresController.text = empleado['nombres'] ?? '';
    _apellidoPaternoController.text = empleado['apellido_paterno'] ?? '';
    _apellidoMaternoController.text = empleado['apellido_materno'] ?? '';
    _dniController.text = empleado['dni_empleado'] ?? '';
    _direccionController.text = empleado['direccion'] ?? '';
    _numeroTelefonicoController.text = empleado['numero_telefonico'] ?? '';
    _emailController.text = empleado['email'] ?? '';
    _salarioController.text = empleado['salario']?.toString() ?? '';
    _selectedGenero = empleado['genero'] ?? _generos.first;
    _selectedTipoEmpleado = empleado['tipo_empleado_id'] ?? _tiposEmpleado.first;

    // Configurar fechas
    if (empleado['fecha_nacimiento'] != null) {
      try {
        _fechaNacimiento = (empleado['fecha_nacimiento'] as Timestamp).toDate();
        _fechaNacimientoController.text = _formatearFechaParaInput(_fechaNacimiento!);
      } catch (e) {
        _fechaNacimiento = DateTime.now().subtract(const Duration(days: 365 * 25));
      }
    }

    if (empleado['fecha_contratacion'] != null) {
      try {
        _fechaContratacion = (empleado['fecha_contratacion'] as Timestamp).toDate();
        _fechaContratacionController.text = _formatearFechaParaInput(_fechaContratacion!);
      } catch (e) {
        _fechaContratacion = DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _dniController.dispose();
    _direccionController.dispose();
    _numeroTelefonicoController.dispose();
    _emailController.dispose();
    _salarioController.dispose();
    _fechaNacimientoController.dispose();
    _fechaContratacionController.dispose();
    super.dispose();
  }

  // ========== MÉTODOS DE VALIDACIÓN ==========
  String? _validarCampoRequerido(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingrese $fieldName';
    }
    return null;
  }

  String? _validarDNI(String? value) {
    final String? baseValidation = _validarCampoRequerido(value, 'el DNI');
    if (baseValidation != null) return baseValidation;
    
    final String trimmedValue = value!.trim();
    if (!RegExp(r'^\d{8}$').hasMatch(trimmedValue)) {
      return 'El DNI debe tener 8 dígitos';
    }
    return null;
  }

  String? _validarNombres(String? value) {
    final String? baseValidation = _validarCampoRequerido(value, 'los nombres');
    if (baseValidation != null) return baseValidation;
    
    final String trimmedValue = value!.trim();
    if (trimmedValue.length < 2) {
      return 'Los nombres deben tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validarApellidos(String? value, String tipo) {
    final String? baseValidation = _validarCampoRequerido(value, 'el apellido $tipo');
    if (baseValidation != null) return baseValidation;
    
    final String trimmedValue = value!.trim();
    if (trimmedValue.length < 2) {
      return 'El apellido debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validarTelefono(String? value) {
    final String? baseValidation = _validarCampoRequerido(value, 'el número telefónico');
    if (baseValidation != null) return baseValidation;
    
    final String trimmedValue = value!.trim();
    if (!RegExp(r'^\+?[\d\s\-\(\)]{9,}$').hasMatch(trimmedValue)) {
      return 'Ingrese un número telefónico válido';
    }
    return null;
  }

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email es opcional
    }
    
    final String trimmedValue = value.trim();
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(trimmedValue)) {
      return 'Ingrese un email válido';
    }
    return null;
  }

  String? _validarSalario(String? value) {
    final String? baseValidation = _validarCampoRequerido(value, 'el salario');
    if (baseValidation != null) return baseValidation;
    
    final String trimmedValue = value!.trim();
    final double? salario = double.tryParse(trimmedValue);
    if (salario == null || salario <= 0) {
      return 'Ingrese un salario válido mayor a 0';
    }
    return null;
  }

  String? _validarFechaNacimiento(String? value) {
    if (_fechaNacimiento == null) {
      return 'Seleccione la fecha de nacimiento';
    }
    
    final DateTime ahora = DateTime.now();
    final int edad = ahora.year - _fechaNacimiento!.year;
    
    if (edad < 18) {
      return 'El empleado debe ser mayor de edad';
    }
    
    if (edad > 100) {
      return 'Verifique la fecha de nacimiento';
    }
    
    return null;
  }

  String? _validarFechaContratacion(String? value) {
    if (_fechaContratacion == null) {
      return 'Seleccione la fecha de contratación';
    }
    
    if (_fechaNacimiento != null && _fechaContratacion!.isBefore(_fechaNacimiento!)) {
      return 'La fecha de contratación no puede ser anterior a la fecha de nacimiento';
    }
    
    return null;
  }

  // ========== MÉTODOS PRINCIPALES ==========
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _showConfirmationDialog();
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Actualización'),
        content: const Text(
          '¿Está seguro de que desea actualizar la información de este empleado?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _actualizarEmpleado();
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _actualizarEmpleado() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Calcular edad
      final int edad = _fechaNacimiento != null 
          ? DateTime.now().year - _fechaNacimiento!.year
          : 0;

      // Preparar datos actualizados
      final empleadoData = {
        'nombres': _nombresController.text.trim(),
        'apellido_paterno': _apellidoPaternoController.text.trim(),
        'apellido_materno': _apellidoMaternoController.text.trim(),
        'dni_empleado': _dniController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'numero_telefonico': _numeroTelefonicoController.text.trim(),
        'email': _emailController.text.trim(),
        'genero': _selectedGenero,
        'tipo_empleado_id': _selectedTipoEmpleado,
        'salario': double.parse(_salarioController.text.trim()),
        'edad': edad,
        'fecha_nacimiento': Timestamp.fromDate(_fechaNacimiento!),
        'fecha_contratacion': Timestamp.fromDate(_fechaContratacion!),
        'fecha_actualizacion': Timestamp.now(),
      };

      // Actualizar en Firebase
      await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(widget.empleadoToEdit['id'])
          .update(empleadoData);

      _mostrarMensajeExito('Empleado actualizado correctamente');
      
      if (mounted) {
        Navigator.pop(context, true);
      }

    } catch (error) {
      _mostrarMensajeError('Error al actualizar el empleado: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _eliminarEmpleado() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Empleado'),
        content: const Text(
          '¿Está seguro de que desea eliminar este empleado? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);

      try {
        await FirebaseFirestore.instance
            .collection(_collectionName)
            .doc(widget.empleadoToEdit['id'])
            .delete();

        _mostrarMensajeExito('Empleado eliminado correctamente');
        
        if (mounted) {
          Navigator.pop(context, true);
        }

      } catch (error) {
        _mostrarMensajeError('Error al eliminar el empleado: $error');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // ========== MÉTODOS DE UTILIDAD ==========
  Future<void> _mostrarSelectorFecha(bool esNacimiento) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: esNacimiento 
          ? (_fechaNacimiento ?? DateTime.now().subtract(const Duration(days: 365 * 25)))
          : (_fechaContratacion ?? DateTime.now()),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendar,
      helpText: esNacimiento ? 'SELECCIONAR FECHA DE NACIMIENTO' : 'SELECCIONAR FECHA DE CONTRATACIÓN',
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esNacimiento) {
          _fechaNacimiento = fechaSeleccionada;
          _fechaNacimientoController.text = _formatearFechaParaInput(fechaSeleccionada);
        } else {
          _fechaContratacion = fechaSeleccionada;
          _fechaContratacionController.text = _formatearFechaParaInput(fechaSeleccionada);
        }
      });
    }
  }

  String _formatearFechaParaInput(DateTime fecha) {
    return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
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

  void _mostrarMensajeExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ========== INTERFAZ DE USUARIO ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Empleado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _eliminarEmpleado,
            tooltip: 'Eliminar empleado',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // INFORMACIÓN PERSONAL
                    _buildSeccionTitulo('Información Personal'),
                    
                    // Nombres
                    _buildNombresField(),
                    const SizedBox(height: 16),

                    // Apellidos
                    Row(
                      children: [
                        Expanded(child: _buildApellidoPaternoField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildApellidoMaternoField()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // DNI y Género
                    Row(
                      children: [
                        Expanded(flex: 2, child: _buildDNIField()),
                        const SizedBox(width: 12),
                        Expanded(flex: 3, child: _buildGeneroField()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Fecha de Nacimiento
                    _buildFechaNacimientoField(),
                    const SizedBox(height: 16),

                    // INFORMACIÓN LABORAL
                    _buildSeccionTitulo('Información Laboral'),
                    
                    // Tipo de Empleado
                    _buildTipoEmpleadoField(),
                    const SizedBox(height: 16),

                    // Fecha de Contratación y Salario
                    Row(
                      children: [
                        Expanded(child: _buildFechaContratacionField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSalarioField()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dirección
                    _buildDireccionField(),
                    const SizedBox(height: 16),

                    // INFORMACIÓN DE CONTACTO
                    _buildSeccionTitulo('Información de Contacto'),
                    
                    // Teléfono y Email
                    _buildTelefonoField(),
                    const SizedBox(height: 16),
                    _buildEmailField(),

                    const SizedBox(height: 30),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildNombresField() {
    return TextFormField(
      controller: _nombresController,
      decoration: const InputDecoration(
        labelText: 'Nombres *',
        hintText: 'Ej: Juan Carlos',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      validator: _validarNombres,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildApellidoPaternoField() {
    return TextFormField(
      controller: _apellidoPaternoController,
      decoration: const InputDecoration(
        labelText: 'Apellido Paterno *',
        hintText: 'Ej: Pérez',
        border: OutlineInputBorder(),
      ),
      validator: (value) => _validarApellidos(value, 'paterno'),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildApellidoMaternoField() {
    return TextFormField(
      controller: _apellidoMaternoController,
      decoration: const InputDecoration(
        labelText: 'Apellido Materno *',
        hintText: 'Ej: García',
        border: OutlineInputBorder(),
      ),
      validator: (value) => _validarApellidos(value, 'materno'),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildDNIField() {
    return TextFormField(
      controller: _dniController,
      decoration: const InputDecoration(
        labelText: 'DNI *',
        hintText: '71234567',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.badge),
        counterText: '8 dígitos',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      validator: _validarDNI,
      textInputAction: TextInputAction.next,
      maxLength: 8,
    );
  }

  Widget _buildGeneroField() {
    return DropdownButtonFormField<String>(
      value: _selectedGenero,
      decoration: const InputDecoration(
        labelText: 'Género *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person_outline),
      ),
      items: _generos.map((genero) {
        return DropdownMenuItem(
          value: genero,
          child: Text(_generoLabels[genero]!),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGenero = value!;
        });
      },
    );
  }

  Widget _buildFechaNacimientoField() {
    return TextFormField(
      controller: _fechaNacimientoController,
      decoration: InputDecoration(
        labelText: 'Fecha de Nacimiento *',
        hintText: 'YYYY-MM-DD',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.cake),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: () => _mostrarSelectorFecha(true),
        ),
      ),
      readOnly: true,
      onTap: () => _mostrarSelectorFecha(true),
      validator: _validarFechaNacimiento,
    );
  }

  Widget _buildTipoEmpleadoField() {
    return DropdownButtonFormField<String>(
      value: _selectedTipoEmpleado,
      decoration: const InputDecoration(
        labelText: 'Tipo de Empleado *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.medical_services),
      ),
      items: _tiposEmpleado.map((tipo) {
        return DropdownMenuItem(
          value: tipo,
          child: Text(_tipoEmpleadoLabels[tipo]!),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedTipoEmpleado = value!;
        });
      },
    );
  }

  Widget _buildFechaContratacionField() {
    return TextFormField(
      controller: _fechaContratacionController,
      decoration: InputDecoration(
        labelText: 'Fecha de Contratación *',
        hintText: 'YYYY-MM-DD',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: () => _mostrarSelectorFecha(false),
        ),
      ),
      readOnly: true,
      onTap: () => _mostrarSelectorFecha(false),
      validator: _validarFechaContratacion,
    );
  }

  Widget _buildSalarioField() {
    return TextFormField(
      controller: _salarioController,
      decoration: const InputDecoration(
        labelText: 'Salario (S/.) *',
        hintText: 'Ej: 2500.00',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: _validarSalario,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildDireccionField() {
    return TextFormField(
      controller: _direccionController,
      decoration: const InputDecoration(
        labelText: 'Dirección *',
        hintText: 'Ej: Av. Principal 123',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on),
      ),
      validator: (value) => _validarCampoRequerido(value, 'la dirección'),
      textInputAction: TextInputAction.next,
      maxLines: 2,
    );
  }

  Widget _buildTelefonoField() {
    return TextFormField(
      controller: _numeroTelefonicoController,
      decoration: const InputDecoration(
        labelText: 'Número Telefónico *',
        hintText: 'Ej: +51 987654321',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone),
      ),
      keyboardType: TextInputType.phone,
      validator: _validarTelefono,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Correo Electrónico',
        hintText: 'Ej: ejemplo@correo.com',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: _validarEmail,
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Actualizar',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}