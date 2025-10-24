import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NuevoTratamiento extends StatefulWidget {
  final Map<String, dynamic> paciente;

  const NuevoTratamiento({super.key, required this.paciente});
  @override
  State<NuevoTratamiento> createState() => _NuevoTratamientoState();
}

class _NuevoTratamientoState extends State<NuevoTratamiento> {
  final TextEditingController _objetivos = TextEditingController();
  final TextEditingController _detalle = TextEditingController();
  final TextEditingController _edad = TextEditingController();
  final TextEditingController _fechaCita = TextEditingController(
    text:
        "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
  );
  final TextEditingController _horaCita = TextEditingController(
    text:
        "${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}",
  );

  String? _tratamientoSeleccionado;
  String? _numeroCitasSeleccionado;
  String? _duracionAproximadaSeleccionada;

  bool _activo = true;

  /// Referencia a la colección de tratamientos en Firestore
  static const String _collectionName = 'tratamientos';



  final List<String> _tratamientosList = [
    'Limpieza dental',
    'Extracción dental',
    'Implante dental',
    'Ortodoncia',
    'Blanqueamiento dental',
    'Calza dental',
    'Corona dental',
    'Prótesis dental',
    'Endodoncia',
    'Periodoncia',
  ];

  final List<String> _numeroCitas = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  ];

  final List<String> _duracionAproximada = [
    '30 minutos',
    '1 hora',
    '1 hora 30 minutos',
    '2 horas',
  ];

  List<Map<String, dynamic>> tratamientos = [];
  @override
  void initState() {
    super.initState();
  }

  Future<void> createTratamiento() async {
    try {
    // 1. Primero creamos el documento del tratamiento
    final tratamientoData = {
      'dni_paciente': widget.paciente['dni_cliente'],
      'creado_por': 'Usuario Actual', // Aquí puedes poner el usuario logueado
      'tratamiento': _tratamientoSeleccionado ?? 'General',
      'detalle': _detalle.text,
      'fecha_creacion': FieldValue.serverTimestamp(), //fecha de creación del tratamiento
      'fecha_finalizacion': null, // Se actualizará al finalizar el tratamiento
      'activo': true,

      //Citas
      'citas_ids': [], // Inicialmente vacío, se irán agregando las citas
      'numero_citas_total': 0, // Se incrementará con cada cita
      'numero_citas_completadas': 0,
    };
    
    // Crear el tratamiento y obtener su referencia
    DocumentReference tratamientoRef = await FirebaseFirestore.instance
        .collection(_collectionName)
        .add(tratamientoData);
    
    // 2. Ahora crear la cita inicial asociada al tratamiento
    final citaData = {
      'tratamiento_id': tratamientoRef.id, // Referencia al tratamiento
      //Campos de paciente
      'nombre_paciente': '${widget.paciente['nombre']} ${widget.paciente['apellido_paterno']}'.trim(),
      'dni_paciente': widget.paciente['dni_cliente'],
      'telefono': widget.paciente['numero_telefonico'],

      //Campos de cita
      'objetivos': _objetivos.text,
      'fecha_cita': _fechaCita.text,
      'hora_cita': _horaCita.text,
      'duracion_aproximada': _duracionAproximadaSeleccionada ?? '1 hora',
      'duracion_real': null,
      'numero_cita': 1,
      'estado': 'planificada',
      'tratamiento': _tratamientoSeleccionado ?? 'General',
      'creado_por': 'Usuario Actual',
      'fecha_creacion': FieldValue.serverTimestamp(),
    };
    
    // Crear la cita
    DocumentReference citaRef = await FirebaseFirestore.instance
        .collection('citas')
        .add(citaData);
    
    // 3. Actualizar el tratamiento con la referencia de la primera cita
    await tratamientoRef.update({
      'citas_ids': FieldValue.arrayUnion([citaRef.id]),
      'numero_citas_total': FieldValue.increment(1),
      'ultima_cita_id': citaRef.id,
    });
    
    desecharVista();
    mensajeria(
      'Tratamiento y cita inicial creados exitosamente.',
      Colors.green,
    );
    
  } catch (e) {
    print('Error al crear tratamiento y cita: $e');
    mensajeria(
      'Error al crear el tratamiento: $e',
      Colors.red,
    );
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
          Expanded(child: _formularioTratamientoNuevo(formKey)),
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
                'Nuevo Tratamiento',
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

  Widget _formularioTratamientoNuevo(GlobalKey<FormState> formKey) {
    // En tu build method, envuelve todo en un Form
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tituloGeneralWidget('Información del tratamiento'),
            Divider(color: Colors.grey.shade300, thickness: 1),

            tituloTextAreaWidget('Tratamiento *'),
            DropdownButtonFormField<String>(
              value: _tratamientoSeleccionado,
              items: _tratamientosList.map((tratamiento) {
                return DropdownMenuItem(
                  value: tratamiento,
                  child: Text(tratamiento),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tratamientoSeleccionado = value;
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

            tituloTextAreaWidget('Detalle *'),
            TextFormField(
              minLines: 4,
              maxLines: 5,
              controller: _detalle,
              keyboardType: TextInputType.text,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                alignLabelWithHint: true,
                labelText: 'En este tratamiento se realizará...',
                floatingLabelStyle: TextStyle(
                  color: Colors.black, // ← Color gris
                  fontSize: 14,
                ),
                border: OutlineInputBorder(),
              ),
              validator: _validarCampoVacio,
            ),
            const SizedBox(height: 15),

            const SizedBox(height: 15),
            tituloGeneralWidget('Plan de tratamiento'),
            Divider(color: Colors.grey.shade300, thickness: 1),

            tituloTextAreaWidget('Numero de citas planificadas *'),
            DropdownButtonFormField<String>(
              value: _numeroCitasSeleccionado,
              items: _numeroCitas.map((cita) {
                return DropdownMenuItem(value: cita, child: Text(cita));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _numeroCitasSeleccionado = value;
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

            Text(
              'Primera cita',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontFamily: 'Helvetica',
              ),
            ),
            const SizedBox(height: 5),

            tituloTextAreaWidget('Objetivos *'),
            TextFormField(
              minLines: 4,
              maxLines: 5,
              controller: _objetivos,
              keyboardType: TextInputType.text,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                alignLabelWithHint: true,
                labelText: 'En esta cita se realizará...',
                floatingLabelAlignment: FloatingLabelAlignment.start,
                floatingLabelStyle: TextStyle(
                  color: Colors.black, // ← Color gris
                  fontSize: 14,
                ),
                border: OutlineInputBorder(),
              ),
              validator: _validarCampoVacio,
            ),
            const SizedBox(height: 15),

            tituloTextAreaWidget('Fecha y Hora *'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fechaCita,
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
                          _fechaCita.text =
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
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _horaCita,
                    readOnly: true,
                    onTap: () async {
                      TimeOfDay? horaSeleccionada = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (horaSeleccionada != null) {
                        setState(() {
                          _horaCita.text =
                              "${horaSeleccionada.hour}:${horaSeleccionada.minute.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      //labelText: 'Hora',
                      suffixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Este campo es requerido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            tituloTextAreaWidget('Duración aproximada *'),
            DropdownButtonFormField<String>(
              value: _duracionAproximadaSeleccionada,
              items: _duracionAproximada.map((cita) {
                return DropdownMenuItem(value: cita, child: Text(cita));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _duracionAproximadaSeleccionada = value;
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
            
            SwitchListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              title: const Text('¿Se encuentra activo?'),
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
                    createTratamiento();
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
