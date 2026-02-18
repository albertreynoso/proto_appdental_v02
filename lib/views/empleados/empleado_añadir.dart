import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NuevoEmpleado extends StatefulWidget {
  const NuevoEmpleado({super.key});
  @override
  State<NuevoEmpleado> createState() => _NuevoEmpleadoState();
}

class _NuevoEmpleadoState extends State<NuevoEmpleado> {
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _apellidoPaterno = TextEditingController();
  final TextEditingController _apellidoMaterno = TextEditingController();
  final TextEditingController _dniEmpleado = TextEditingController();
  final TextEditingController _numeroTelefonico = TextEditingController();
  final TextEditingController _direccion = TextEditingController();
  final TextEditingController _edad = TextEditingController();
  String? _generoSeleccionado;
  final TextEditingController _fechaNacimiento = TextEditingController();

  final TextEditingController _salario = TextEditingController();
  final TextEditingController _fechaContratacion = TextEditingController();
  String? _tipoEmpleadoSeleccionado;

  bool _activo = true;

  /// Referencia a la colección de empleados en Firestore
  static const String _collectionName = 'personal';

  final List<String> _tipoEmpleadoList = [
    'Odontologo',
    'Asistente',
    'Administrativo',
    'Otro',
  ];
  final List<String> _generoList = ['Masculino', 'Femenino', 'Otro'];

  List<Map<String, dynamic>> empleado = [];
  @override
  void initState() {
    super.initState();
  }

  Future<void> createEmpleado() async {
    if (!_validarCampos()) return;
    final datos = {
      'nombre': _nombre.text,
      'apellido_paterno': _apellidoPaterno.text,
      'apellido_materno': _apellidoMaterno.text,
      'dni_empleado': _dniEmpleado.text,
      'numero_telefonico': _numeroTelefonico.text,
      'direccion': _direccion.text,
      'edad': _edad.text,
      'genero': _generoSeleccionado,
      'fecha_nacimiento': _fechaNacimiento.text,

      'salario': double.tryParse(_salario.text) ?? 0.0,
      'tipo_empleado_id': _tipoEmpleadoSeleccionado,
      'fecha_contratacion': _fechaContratacion.text,
      'activo': _activo,
    };
    try {
      await FirebaseFirestore.instance.collection(_collectionName).add(datos);
      desecharVista();
      mensajeria(
        'Se ha agregado el nuevo empleado exitosamente.',
        Colors.green,
      );
      //limpiarFormulario();
    } catch (e) {
      print('Error al crear empleado: $e');
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

  bool _validarCampos() {
    if (_nombre.text.isEmpty ||
        _apellidoPaterno.text.isEmpty ||
        _apellidoMaterno.text.isEmpty ||
        _dniEmpleado.text.isEmpty ||
        _numeroTelefonico.text.isEmpty ||
        _direccion.text.isEmpty ||
        _edad.text.isEmpty ||
        _fechaNacimiento.text.isEmpty ||
        _salario.text.isEmpty ||
        _fechaContratacion.text.isEmpty ||
        _generoSeleccionado == null ||
        _tipoEmpleadoSeleccionado == null) {
      mensajeria(
        'Por favor, complete todos los campos obligatorios.',
        Colors.red,
      );
      return false;
    }
    return true;
  }

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
                'Añadir Empleado',
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
            tituloGeneralWidget('Información del Empleado'),
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

            tituloTextAreaWidget('DNI Empleado *'),
            textAreaWidget(
              _dniEmpleado,
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
                    _edad.text = edad.toString(); // ← Solo el número
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
              controller: _edad,
              readOnly: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              validator: _validarCampoVacio,
            ),
            const SizedBox(height: 15),

            tituloGeneralWidget('Información Laboral'),
            Divider(color: Colors.grey.shade300, thickness: 1),

            tituloTextAreaWidget('Salario *'),
            textAreaWidget(
              _salario,
              TextInputType.numberWithOptions(decimal: true),
              validator: _validarSalario,
            ),
            const SizedBox(height: 15),

            tituloTextAreaWidget('Tipo de Empleado *'),

            FocusScope(
              node: FocusScopeNode(canRequestFocus: false),
              child: DropdownButtonFormField<String>(
                value: _tipoEmpleadoSeleccionado,
                items: _tipoEmpleadoList.map((tipo) {
                  return DropdownMenuItem(value: tipo, child: Text(tipo));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoEmpleadoSeleccionado = value;
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
            ),

            /*
            MenuAnchor(
              style: MenuStyle(
                backgroundColor: WidgetStateProperty.all(Colors.white),
                elevation: WidgetStateProperty.all(8),
                surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                minimumSize: WidgetStateProperty.all(
                  const Size(double.infinity, 0),
                ),
                maximumSize: WidgetStateProperty.all(
                  const Size(double.infinity, 200),
                ),
              ),
              menuChildren: _tipoEmpleadoList.map((tipo) {
                return MenuItemButton(
                  onPressed: () {
                    setState(() {
                      _tipoEmpleadoSeleccionado = tipo;
                    });
                  },
                  child: Text(tipo),
                );
              }).toList(),
              builder: (context, controller, child) {
                return GestureDetector(
                  onTap: () {
                    // Al tocar cualquier parte del TextField, abrimos o cerramos el menú
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: AbsorbPointer(
                    // Evita que el TextField consuma el tap
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _tipoEmpleadoSeleccionado,
                      ),
                      decoration: InputDecoration(
                        labelText: "Tipo de empleado",
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Este campo es requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                );
              },
            ), */

            /*DropdownButtonFormField<String>(
              value: _tipoEmpleadoSeleccionado,
              items: _tipoEmpleadoList.map((tipo) {
                return DropdownMenuItem(value: tipo, child: Text(tipo));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tipoEmpleadoSeleccionado = value;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
            ),*/
            const SizedBox(height: 15),

            tituloTextAreaWidget('Fecha de Contratación *'),
            TextFormField(
              controller: _fechaContratacion,
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
                    _fechaContratacion.text =
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
              title: const Text('¿Se encuentra trabajando?'),
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
                    createEmpleado();
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

  // Para edad (1-3 dígitos)
  String? _validarEdad(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es requerido';
    }
    if (!RegExp(r'^\d{1,3}$').hasMatch(value)) {
      return 'Edad inválida';
    }
    final edad = int.tryParse(value);
    if (edad == null || edad < 1 || edad > 120) {
      return 'Edad debe ser entre 1 y 120';
    }
    return null;
  }

  // Para salario (números con decimales)
  String? _validarSalario(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es requerido';
    }
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
      return 'Formato de salario inválido';
    }
    return null;
  }
}
