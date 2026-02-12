import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:proto_appdental_v02/modals/tratamiento_model.dart';

class EditarTratamiento extends StatefulWidget {
  final Tratamiento tratamiento;
  final Map<String, dynamic> paciente;

  const EditarTratamiento({
    Key? key,
    required this.tratamiento,
    required this.paciente,
  }) : super(key: key);

  @override
  State<EditarTratamiento> createState() => _EditarTratamientoState();
}

class _EditarTratamientoState extends State<EditarTratamiento> {
  final _formKey = GlobalKey<FormState>();
  bool _isGuardando = false;
  bool _tieneCitasCompletadas = false;
  bool _isLoadingValidacion = true;

  late TextEditingController _diagnosticoController;
  late TextEditingController _cantidadCitasController;

  String? _tipoTratamientoSeleccionado;
  List<ItemPresupuesto> _presupuesto = [];

  final List<String> _tiposTratamiento = [
    'Ortodoncia',
    'Implantes',
    'Endodoncia',
    'Periodoncia',
    'Rehabilitación oral',
    'Cirugía oral',
    'Estética dental',
    'Odontopediatría',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _validarCitasCompletadas();
    _inicializarControllers();
    _cargarDatosTratamiento();
  }

  Future<void> _validarCitasCompletadas() async {
    try {
      if (widget.tratamiento.citas.isEmpty) {
        setState(() {
          _tieneCitasCompletadas = false;
          _isLoadingValidacion = false;
        });
        return;
      }

      final citasSnapshot = await FirebaseFirestore.instance
          .collection('citas')
          .where(FieldPath.documentId, whereIn: widget.tratamiento.citas)
          .get();

      final tieneCitasCompletadas = citasSnapshot.docs.any(
        (doc) => doc.data()['estado']?.toString().toLowerCase() == 'completada',
      );

      setState(() {
        _tieneCitasCompletadas = tieneCitasCompletadas;
        _isLoadingValidacion = false;
      });

      if (_tieneCitasCompletadas) {
        Future.delayed(Duration.zero, () {
          _mostrarMensajeBloqueo();
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingValidacion = false;
      });
    }
  }

  void _mostrarMensajeBloqueo() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edición Bloqueada'),
          content: const Text(
            'No se puede editar este tratamiento porque ya tiene citas completadas.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  void _inicializarControllers() {
    _diagnosticoController = TextEditingController();
    _cantidadCitasController = TextEditingController();
  }

  void _cargarDatosTratamiento() {
    _tipoTratamientoSeleccionado = widget.tratamiento.tratamiento;

    // Formatear el diagnóstico con viñetas
    String diagnosticoFormateado = widget.tratamiento.diagnostico
        .split('\n')
        .map((linea) => linea.trim())
        .where((linea) => linea.isNotEmpty)
        .map((linea) => '• $linea')
        .join('\n');

    _diagnosticoController.text = diagnosticoFormateado;
    _cantidadCitasController.text = widget.tratamiento.cantidadCitasPlanificadas
        .toString();

    // Cargar presupuesto
    _presupuesto = widget.tratamiento.presupuesto.map((item) {
      final itemPresupuesto = ItemPresupuesto();
      itemPresupuesto.cantidadController.text = item.cantidad.toString();
      itemPresupuesto.descripcionController.text = item.descripcion;
      itemPresupuesto.precioController.text = item.precioUnitario.toString();

      if (item.subitems != null && item.subitems!.isNotEmpty) {
        itemPresupuesto.subitems = item.subitems!.map((subitem) {
          final sub = SubitemPresupuesto();
          sub.cantidadController.text = subitem.cantidad.toString();
          sub.descripcionController.text = subitem.descripcion;
          sub.precioController.text = subitem.precioUnitario.toString();
          return sub;
        }).toList();
      }

      return itemPresupuesto;
    }).toList();
  }

  @override
  void dispose() {
    _diagnosticoController.dispose();
    _cantidadCitasController.dispose();
    for (var item in _presupuesto) {
      item.dispose();
    }
    super.dispose();
  }

  double _calcularTotalItem(ItemPresupuesto item) {
    if (item.subitems.isNotEmpty) {
      final sumaSubitems = item.subitems.fold(0.0, (sum, sub) {
        final cantidad = double.tryParse(sub.cantidadController.text) ?? 0;
        final precio = double.tryParse(sub.precioController.text) ?? 0;
        return sum + (cantidad * precio);
      });
      final cantidadItem = double.tryParse(item.cantidadController.text) ?? 0;
      return sumaSubitems * cantidadItem;
    }
    final cantidad = double.tryParse(item.cantidadController.text) ?? 0;
    final precio = double.tryParse(item.precioController.text) ?? 0;
    return cantidad * precio;
  }

  double _calcularTotal() {
    return _presupuesto.fold(
      0.0,
      (sum, item) => sum + _calcularTotalItem(item),
    );
  }

  void _agregarItem() {
    setState(() {
      _presupuesto.add(ItemPresupuesto());
    });
  }

  void _eliminarItem(int index) {
    if (_presupuesto.length > 1) {
      setState(() {
        _presupuesto[index].dispose();
        _presupuesto.removeAt(index);
      });
    }
  }

  void _agregarSubitem(int itemIndex) {
    setState(() {
      _presupuesto[itemIndex].subitems.add(SubitemPresupuesto());
    });
  }

  void _eliminarSubitem(int itemIndex, int subitemIndex) {
    setState(() {
      _presupuesto[itemIndex].subitems[subitemIndex].dispose();
      _presupuesto[itemIndex].subitems.removeAt(subitemIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingValidacion) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
              _buildSeccion('Información del Tratamiento', [
                _buildDropdown(
                  'Tipo de Tratamiento',
                  _tipoTratamientoSeleccionado,
                  _tiposTratamiento,
                  (valor) {
                    setState(() => _tipoTratamientoSeleccionado = valor);
                  },
                  obligatorio: true,
                ),
                const SizedBox(height: 16),
                _buildTextArea(
                  'Diagnóstico',
                  _diagnosticoController,
                  obligatorio: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Cantidad de Citas Planificadas',
                  _cantidadCitasController,
                  teclado: TextInputType.number,
                  obligatorio: true,
                ),
              ]),
              const SizedBox(height: 24),
              _buildPresupuestoSeccion(),
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
                  'Editar Tratamiento',
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
          onTap: () {
            if (teclado == TextInputType.number ||
                teclado ==
                    const TextInputType.numberWithOptions(decimal: true)) {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            }
          },
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            counterText: '',
          ),
          style: const TextStyle(fontSize: 14),
          validator: obligatorio
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  if (teclado == TextInputType.number) {
                    final numero = int.tryParse(value);
                    if (numero == null || numero < 1) {
                      return 'Debe ser al menos 1';
                    }
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildTextArea(
    String label,
    TextEditingController controller, {
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
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus &&
                (controller.text == '• ' || controller.text.trim() == '•')) {
              controller.clear();
            }
          },
          child: TextFormField(
            controller: controller,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onTap: () {
              if (controller.text.isEmpty) {
                controller.text = '• ';
                controller.selection = TextSelection.collapsed(offset: 2);
              }
            },
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
                borderSide: const BorderSide(
                  color: Color(0xFF3B82F6),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintText: 'Describe el diagnóstico del paciente...',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (value) {
              final cursorPos = controller.selection.base.offset;

              if (value.length <= 2 &&
                  (value == '• ' || value == '•' || value == ' ')) {
                controller.clear();
                return;
              }

              if (value.isEmpty) {
                return;
              }

              final lines = value.split('\n');
              if (lines.length > 1) {
                if (lines.last == '• ' || lines.last == '•') {
                  lines.removeLast();
                  final newText = lines.join('\n');
                  controller.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(offset: newText.length),
                  );
                  return;
                }
              }

              if (value.endsWith('\n')) {
                final newText = value + '• ';
                controller.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(offset: newText.length),
                );
                return;
              }

              // Manejar la adición de viñeta inicial sin interferir con la capitalización
              if (!value.startsWith('• ')) {
                // Capitalizar la primera letra después de la viñeta
                String textAfterBullet = value;
                if (textAfterBullet.isNotEmpty) {
                  textAfterBullet =
                      textAfterBullet[0].toUpperCase() +
                      (textAfterBullet.length > 1
                          ? textAfterBullet.substring(1)
                          : '');
                }

                final newText = '• $textAfterBullet';
                final newCursorPos = cursorPos + 2 <= newText.length
                    ? cursorPos + 2
                    : newText.length;

                controller.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(offset: newCursorPos),
                );
                return;
              }

              // Capitalizar después de cada viñeta en nuevas líneas
              if (value.contains('\n• ')) {
                final processedLines = <String>[];
                for (final line in lines) {
                  if (line.startsWith('• ') && line.length > 2) {
                    final afterBullet = line.substring(2);
                    if (afterBullet.isNotEmpty) {
                      final capitalized =
                          afterBullet[0].toUpperCase() +
                          (afterBullet.length > 1
                              ? afterBullet.substring(1)
                              : '');
                      processedLines.add('• $capitalized');
                    } else {
                      processedLines.add(line);
                    }
                  } else {
                    processedLines.add(line);
                  }
                }

                final newText = processedLines.join('\n');
                if (newText != value) {
                  controller.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(
                      offset: cursorPos <= newText.length
                          ? cursorPos
                          : newText.length,
                    ),
                  );
                }
              }
            },
            validator: obligatorio
                ? (value) {
                    if (value == null ||
                        value.trim().isEmpty ||
                        value.trim() == '•') {
                      return 'Este campo es obligatorio';
                    }
                    final contenidoReal = value
                        .replaceAll('•', '')
                        .replaceAll('\n', '')
                        .trim();
                    if (contenidoReal.length < 10) {
                      return 'El diagnóstico debe tener al menos 10 caracteres';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? valorActual,
    List<String> opciones,
    Function(String?) onChanged, {
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            hint: Text(
              'Seleccionar $label',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade700,
            ),
            isExpanded: true,
            style: const TextStyle(fontSize: 14, color: Colors.black),
            dropdownColor: Colors.white,
            items: opciones.map((opcion) {
              return DropdownMenuItem(
                value: opcion,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  child: Text(
                    opcion,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            validator: obligatorio
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPresupuestoSeccion() {
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      'Presupuesto Detallado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      ' *',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _agregarItem,
                  icon: const Icon(Icons.add_circle_outline, size: 24),
                  color: Colors.grey.shade500,
                  padding: const EdgeInsets.all(12),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _presupuesto.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              return _buildItemPresupuesto(index);
            },
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'S/ ${_calcularTotal().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(140, 0, 0, 0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemPresupuesto(int index) {
    final item = _presupuesto[index];
    final tieneSubitems = item.subitems.isNotEmpty;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cant.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: item.cantidadController,
                            keyboardType: TextInputType.number,
                            enabled: true,
                            textAlign: TextAlign.center,
                            onTap: () {
                              item.cantidadController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset:
                                    item.cantidadController.text.length,
                              );
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF7F7F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 10,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Descripción',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: item.descripcionController,
                            textCapitalization: TextCapitalization.words,
                            inputFormatters: [
                              TextInputFormatter.withFunction((
                                oldValue,
                                newValue,
                              ) {
                                // Capitalizar cada palabra
                                final words = newValue.text.split(' ');
                                final capitalizedWords = words
                                    .map((word) {
                                      if (word.isEmpty) return word;
                                      return word[0].toUpperCase() +
                                          word.substring(1).toLowerCase();
                                    })
                                    .join(' ');

                                return TextEditingValue(
                                  text: capitalizedWords,
                                  selection: newValue.selection,
                                );
                              }),
                            ],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF7F7F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              hintText: 'Descripción del servicio...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Requerido';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 75,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Precio Unit.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          tieneSubitems
                              ? Container(
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      final sumaSubitems = item.subitems.fold(
                                        0.0,
                                        (sum, sub) {
                                          final cantidad =
                                              double.tryParse(
                                                sub.cantidadController.text,
                                              ) ??
                                              0;
                                          final precio =
                                              double.tryParse(
                                                sub.precioController.text,
                                              ) ??
                                              0;
                                          return sum + (cantidad * precio);
                                        },
                                      );
                                      return Text(
                                        'S/ ${sumaSubitems.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : TextFormField(
                                  controller: item.precioController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onTap: () {
                                    item.precioController.selection =
                                        TextSelection(
                                          baseOffset: 0,
                                          extentOffset:
                                              item.precioController.text.length,
                                        );
                                  },
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF7F7F7),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3B82F6),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 10,
                                    ),
                                    prefixText: 'S/ ',
                                    prefixStyle: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                  onChanged: (_) => setState(() {}),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _agregarSubitem(index),
                          icon: const Icon(Icons.add),
                          iconSize: 20,
                          color: Colors.grey.shade500,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          splashRadius: 16,
                        ),
                        if (_presupuesto.length > 1) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _eliminarItem(index),
                            icon: const Icon(Icons.delete_outline),
                            iconSize: 20,
                            color: Colors.red,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            splashRadius: 16,
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'S/ ${_calcularTotalItem(item).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(140, 0, 0, 0),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (tieneSubitems)
            Container(
              color: const Color(0xFFF7F7F7),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: item.subitems.length,
                itemBuilder: (context, subIndex) {
                  return _buildSubitem(index, subIndex);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubitem(int itemIndex, int subIndex) {
    final subitem = _presupuesto[itemIndex].subitems[subIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 0, 10),
      child: Row(
        children: [
          Icon(
            Icons.subdirectory_arrow_right,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: TextFormField(
              controller: subitem.cantidadController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onTap: () {
                subitem.cantidadController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: subitem.cantidadController.text.length,
                );
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
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
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                hintText: 'Cant.',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: subitem.descripcionController,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  // Capitalizar cada palabra
                  final words = newValue.text.split(' ');
                  final capitalizedWords = words
                      .map((word) {
                        if (word.isEmpty) return word;
                        return word[0].toUpperCase() +
                            word.substring(1).toLowerCase();
                      })
                      .join(' ');

                  return TextEditingValue(
                    text: capitalizedWords,
                    selection: newValue.selection,
                  );
                }),
              ],
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
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
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                hintText: 'Descripción...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              style: const TextStyle(fontSize: 13),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Requerido';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: subitem.precioController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onTap: () {
                subitem.precioController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: subitem.precioController.text.length,
                );
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
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
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                prefixText: 'S/ ',
                prefixStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
                hintText: '0.00',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => _eliminarSubitem(itemIndex, subIndex),
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: 18,
            color: Colors.red,
            constraints: const BoxConstraints(),
            splashRadius: 16,
          ),
        ],
      ),
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isGuardando ? null : _guardarCambios,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade500,
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

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      _mostrarMensaje(
        'Por favor completa todos los campos obligatorios',
        esError: true,
      );
      return;
    }

    if (_tipoTratamientoSeleccionado == null ||
        _tipoTratamientoSeleccionado!.isEmpty) {
      _mostrarMensaje('Selecciona un tipo de tratamiento', esError: true);
      return;
    }

    setState(() => _isGuardando = true);

    try {
      final totalPresupuesto = _calcularTotal();

      String diagnosticoLimpio = _diagnosticoController.text
          .replaceAll('• ', '')
          .replaceAll('•', '')
          .trim();

      final presupuestoData = _presupuesto.map((item) {
        return {
          'cantidad': int.tryParse(item.cantidadController.text) ?? 1,
          'precio_unitario': double.tryParse(item.precioController.text) ?? 0,
          'descripcion': item.descripcionController.text.trim(),
          'subitems': item.subitems.map((sub) {
            return {
              'cantidad': int.tryParse(sub.cantidadController.text) ?? 1,
              'precio_unitario':
                  double.tryParse(sub.precioController.text) ?? 0,
              'descripcion': sub.descripcionController.text.trim(),
            };
          }).toList(),
        };
      }).toList();

      // Calcular el nuevo pago pendiente
      final diferenciaPago =
          totalPresupuesto - widget.tratamiento.totalPresupuesto;
      final nuevoPagoPendiente =
          widget.tratamiento.pagoPendiente + diferenciaPago;

      final tratamientoData = {
        'tratamiento': _tipoTratamientoSeleccionado,
        'diagnostico': diagnosticoLimpio,
        'cantidad_citas_planificadas': int.parse(_cantidadCitasController.text),
        'presupuesto': presupuestoData,
        'total_presupuesto': totalPresupuesto,
        'pago_pendiente': nuevoPagoPendiente,
        'fecha_ultima_actualizacion': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('tratamientos')
          .doc(widget.tratamiento.id)
          .update(tratamientoData);

      if (mounted) {
        _mostrarMensaje('Tratamiento actualizado exitosamente');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGuardando = false);
        _mostrarMensaje('Error al actualizar tratamiento: $e', esError: true);
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

class ItemPresupuesto {
  final TextEditingController cantidadController;
  final TextEditingController precioController;
  final TextEditingController descripcionController;
  List<SubitemPresupuesto> subitems;

  ItemPresupuesto()
    : cantidadController = TextEditingController(text: '1'),
      precioController = TextEditingController(text: '0'),
      descripcionController = TextEditingController(),
      subitems = [];

  void dispose() {
    cantidadController.dispose();
    precioController.dispose();
    descripcionController.dispose();
    for (var subitem in subitems) {
      subitem.dispose();
    }
  }
}

class SubitemPresupuesto {
  final TextEditingController cantidadController;
  final TextEditingController precioController;
  final TextEditingController descripcionController;

  SubitemPresupuesto()
    : cantidadController = TextEditingController(text: '1'),
      precioController = TextEditingController(text: '0'),
      descripcionController = TextEditingController();

  void dispose() {
    cantidadController.dispose();
    precioController.dispose();
    descripcionController.dispose();
  }
}
