import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NuevoCliente extends StatefulWidget {
  const NuevoCliente({super.key});
  @override
  State<NuevoCliente> createState() => _NuevoClienteState();
}

class _NuevoClienteState extends State<NuevoCliente> {
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _apellidoPaterno = TextEditingController();
  final TextEditingController _apellidoMaterno = TextEditingController();
  final TextEditingController _dniCliente = TextEditingController();
  final TextEditingController _numeroTelefonico = TextEditingController();
  final TextEditingController _edadCliente = TextEditingController();
  final TextEditingController _direccion = TextEditingController();
  final TextEditingController _fechaNacimiento = TextEditingController();
  String? _generoSeleccionado;

  final TextEditingController _fechaIngreso = TextEditingController();

  bool _activo = true;

  /// Referencia a la colección de empleados en Firestore
  static const String _collectionName = 'pacientes';

  final List<String> _generoList = ['Masculino', 'Femenino', 'Otro'];

  List<Map<String, dynamic>> empleado = [];
  @override
  void initState() {
    super.initState();
  }

  Future<void> createCliente() async {
    final datos = {
      'nombre': _nombre.text,
      'apellido_paterno': _apellidoPaterno.text,
      'apellido_materno': _apellidoMaterno.text,
      'dni_cliente': _dniCliente.text,
      'numero_telefonico': _numeroTelefonico.text,
      'direccion': _direccion.text,
      'edad_cliente': _edadCliente.text,
      'genero': _generoSeleccionado,
      'fecha_nacimiento': _fechaNacimiento.text,

      'fecha_ingreso': _fechaIngreso.text,
      'activo': _activo,
    };
    try {
      await FirebaseFirestore.instance.collection(_collectionName).add(datos);
      desecharVista();
      mensajeria(
        'Se ha agregado el nuevo cliente exitosamente.',
        Colors.green,
      );
      //limpiarFormulario();
    } catch (e) {
      print('Error al crear cliente: $e');
    }
  }

  //Función para calcular edad
  int calcularEdad(DateTime fechaNacimiento) {
    final ahora = DateTime.now();
    int edad = ahora.year - fechaNacimiento.year;

    // Verificar si ya pasó el cumpleaños este año
    if (ahora.month < fechaNacimiento.month ||
        (ahora.month == fechaNacimiento.month &&
            ahora.day < fechaNacimiento.day)) {
      edad--;
    }

    return edad;
  }

  String calcularEdadConTexto(DateTime fechaNacimiento) {
    final edad = calcularEdad(fechaNacimiento);
    return '$edad años';
  }

  void desecharVista() {
    Navigator.of(context).pop();
  }

  void mensajeria(String mensaje, Color? color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Éxito',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      mensaje,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
        duration: Duration(seconds: 4),
      ),
    );
  }

  /*
  void limpiarFormulario() {
    setState(() {
      _nombre.clear();
      _precio.clear();
      _porcion.clear();
      _categoriaSeleccionada = null;
      _disponible = true;
    });
  }*/

  ///Widgets utiles
  Widget tituloTextAreaWidget(String texto) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }

  Widget textAreaWidget(
    TextEditingController controller,
    TextInputType keyboardType, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Agrega esta key global en tu clase
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.grey[50],
      appBar: _construirAppBar(context),
      body: Column(
        children: [
          Expanded(child: _formularioEmpleadoNuevo(formKey)),
          _botonesFuncionales(formKey),
        ],
      ),
    );
  }

  // ================== APP BAR ==================
  PreferredSizeWidget _construirAppBar(context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white, // Color sólido
          // Puedes agregar un border o boxShadow si quieres una línea o sombra
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
              // Botón de retroceso
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 8),
              /* const Text(
                'Añadir Cliente',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ), */
              // ...otros widgets si necesitas
            ],
          ),
        ),
      ),
    );
  }

  Widget _formularioEmpleadoNuevo(GlobalKey<FormState> formKey) {
    // En tu build method, envuelve todo en un Form
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tituloGeneralWidget('Información del Cliente'),
            Divider(color: Colors.grey.shade300, thickness: 1),

            tituloTextAreaWidget('Nombres *'),
            textAreaWidget(
              _nombre,
              TextInputType.text,
              validator: _validarSoloTexto,
            ),
            const SizedBox(height: 15),

            tituloTextAreaWidget('Apellido Paterno *'),
            textAreaWidget(
              _apellidoPaterno,
              TextInputType.text,
              validator: _validarSoloTexto,
            ),
            const SizedBox(height: 15),

            tituloTextAreaWidget('Apellido Materno *'),
            textAreaWidget(
              _apellidoMaterno,
              TextInputType.text,
              validator: _validarSoloTexto,
            ),
            const SizedBox(height: 15),

            tituloTextAreaWidget('DNI Cliente *'),
            textAreaWidget(
              _dniCliente,
              TextInputType.number,
              validator: _validarDNI,
            ),
            const SizedBox(height: 15),

            tituloTextAreaWidget('Número Telefónico *'),
            textAreaWidget(
              _numeroTelefonico,
              TextInputType.phone,
              validator: _validarTelefono,
            ),
            const SizedBox(height: 15),

            tituloTextAreaWidget('Dirección *'),
            TextFormField(
              minLines: 2,
              maxLines: 4,
              controller: _direccion,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              validator: _validarCampoVacio,
            ),
            const SizedBox(height: 15),

            tituloTextAreaWidget('Genero *'),
            DropdownButtonFormField<String>(
              value: _generoSeleccionado,
              items: _generoList.map((genero) {
                return DropdownMenuItem(value: genero, child: Text(genero));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _generoSeleccionado = value;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            tituloTextAreaWidget('Fecha de Nacimiento *'),
            TextFormField(
              controller: _fechaNacimiento,
              readOnly: true,
              onTap: () async {
                DateTime? fechaSeleccionada = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (fechaSeleccionada != null) {
                  setState(() {
                    _fechaNacimiento.text =
                        "${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}";

                    // Calcular y asignar la edad automáticamente usando tu función
                    final edad = calcularEdad(fechaSeleccionada);
                    _edadCliente.text = edad.toString(); // ← Solo el número
                  });
                }
              },
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            tituloTextAreaWidget('Edad *'),
            TextFormField(
              controller: _edadCliente,
              readOnly: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              validator: _validarCampoVacio,
            ),
            const SizedBox(height: 15),

            tituloTextAreaWidget('Fecha de Ingreso *'),
            TextFormField(
              controller: _fechaIngreso,
              readOnly: true,
              onTap: () async {
                DateTime? fechaSeleccionada = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2030),
                );
                if (fechaSeleccionada != null) {
                  setState(() {
                    _fechaIngreso.text =
                        "${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}";
                  });
                }
              },
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            SwitchListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              title: const Text('¿Va a realizarse algún tratamiento?'),
              value: _activo,
              onChanged: (value) {
                setState(() {
                  _activo = value;
                });
              },
              secondary: Icon(
                _activo ? Icons.check_circle : Icons.cancel,
                color: _activo ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tituloGeneralWidget(String texto) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 18,
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontFamily: 'Helvetica',
        ),
      ),
    );
  }

  Widget _botonesFuncionales(GlobalKey<FormState> formKey) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          //border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.grey.shade800,
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Esta línea activa todas las validaciones
                  if (formKey.currentState!.validate()) {
                    // Si todos los campos son válidos, procede con el envío
                    createCliente();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Guardar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Validaciones

  // Para campo vacio
  String? _validarCampoVacio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es requerido';
    }
    return null;
  }

  // Para DNI (8 dígitos exactos)
  String? _validarDNI(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es requerido';
    }
    if (!RegExp(r'^\d{8}$').hasMatch(value)) {
      return 'Ingrese un DNI válido de 8 dígitos';
    }
    return null;
  }

  // Para solo texto (sin números)
  String? _validarSoloTexto(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es requerido';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return 'Ingrese valores validos';
    }
    return null;
  }

  // Para teléfono (9 dígitos)
  String? _validarTelefono(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es requerido';
    }
    if (!RegExp(r'^\d{9}$').hasMatch(value)) {
      return 'El teléfono debe tener 9 dígitos';
    }
    return null;
  }
}
