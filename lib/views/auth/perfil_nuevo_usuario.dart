import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proto_appdental_v02/views/auth/bienvenida.dart';
import 'package:proto_appdental_v02/core/auth_service.dart';

class PerfilNuevoUsuario extends StatefulWidget {
  const PerfilNuevoUsuario({super.key});

  @override
  State<PerfilNuevoUsuario> createState() => _PerfilNuevoUsuarioState();
}

class _PerfilNuevoUsuarioState extends State<PerfilNuevoUsuario> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  DateTime? _fechaNacimiento;
  String? _genero;
  bool _loading = false;

  static const _generos = ['Masculino', 'Femenino', 'Otro', 'Prefiero no decir'];

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1930),
      lastDate: DateTime(now.year - 16),
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_genero == null) {
      _showError('Selecciona tu género.');
      return;
    }
    if (_fechaNacimiento == null) {
      _showError('Selecciona tu fecha de nacimiento.');
      return;
    }
    setState(() => _loading = true);
    await AuthService().saveUserProfile(data: {
      'nombre': _nombreController.text.trim(),
      'apellidoPaterno': _apellidoPaternoController.text.trim(),
      'apellidoMaterno': _apellidoMaternoController.text.trim(),
      'dni': _dniController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'direccion': _direccionController.text.trim(),
      'fechaNacimiento': _fechaNacimiento!.toIso8601String(),
      'genero': _genero,
    });
    if (!mounted) return;
    setState(() => _loading = false);
    final nombre = _nombreController.text.trim();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => Bienvenida(nombre: nombre)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Completa tu perfil',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCard(
                title: 'Información personal',
                children: [
                  _buildField(
                    controller: _nombreController,
                    label: 'Nombre(s)',
                    hint: 'Juan',
                    validator: _requiredValidator,
                    capitalization: TextCapitalization.words,
                  ),
                  _buildField(
                    controller: _apellidoPaternoController,
                    label: 'Apellido paterno',
                    hint: 'García',
                    validator: _requiredValidator,
                    capitalization: TextCapitalization.words,
                  ),
                  _buildField(
                    controller: _apellidoMaternoController,
                    label: 'Apellido materno',
                    hint: 'López',
                    capitalization: TextCapitalization.words,
                  ),
                  _buildDateField(),
                  _buildGenderField(),
                ],
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Contacto',
                children: [
                  _buildField(
                    controller: _dniController,
                    label: 'DNI',
                    hint: '12345678',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (v.length != 8) return 'El DNI debe tener 8 dígitos';
                      return null;
                    },
                  ),
                  _buildField(
                    controller: _telefonoController,
                    label: 'Teléfono',
                    hint: '987654321',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    validator: _requiredValidator,
                  ),
                  _buildField(
                    controller: _direccionController,
                    label: 'Dirección',
                    hint: 'Av. Ejemplo 123, Lima',
                    capitalization: TextCapitalization.sentences,
                    validator: _requiredValidator,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF71CE06),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Guardar',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9E9E9E),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children
                  .expand((w) => [w, const SizedBox(height: 16)])
                  .toList()
                ..removeLast(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    final text = _fechaNacimiento == null
        ? 'Seleccionar'
        : '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/'
            '${_fechaNacimiento!.month.toString().padLeft(2, '0')}/'
            '${_fechaNacimiento!.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha de nacimiento',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      color: _fechaNacimiento == null
                          ? const Color(0xFFBDBDBD)
                          : Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Género',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _genero,
              hint: const Text(
                'Seleccionar',
                style:
                    TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
              ),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Colors.grey, size: 20),
              items: _generos
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _genero = v),
            ),
          ),
        ),
      ],
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo requerido';
    return null;
  }
}
