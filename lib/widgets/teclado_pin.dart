import 'package:flutter/material.dart';

/// Widget reutilizable de teclado PIN con indicadores de dígitos.
/// Llama [onCompleted] cuando se ingresan los 4 dígitos.
/// Expone [reset()] para limpiar desde el exterior.
/// [onBack] es opcional: si se provee, muestra una flecha de retroceso
/// en la esquina superior izquierda.
class TecladoPin extends StatefulWidget {
  final void Function(String pin) onCompleted;
  final VoidCallback? onBack;

  const TecladoPin({
    super.key,
    required this.onCompleted,
    this.onBack,
  });

  @override
  State<TecladoPin> createState() => TecladoPinState();
}

class TecladoPinState extends State<TecladoPin>
    with SingleTickerProviderStateMixin {
  final List<String> _digitos = [];
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void reset() {
    setState(() => _digitos.clear());
  }

  void shake() {
    _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 420), reset);
  }

  void _presionar(String digito) {
    if (_digitos.length >= 4) return;
    setState(() => _digitos.add(digito));
    if (_digitos.length == 4) {
      Future.delayed(const Duration(milliseconds: 100), () {
        widget.onCompleted(_digitos.join());
      });
    }
  }

  void _borrar() {
    if (_digitos.isEmpty) return;
    setState(() => _digitos.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Contenido principal centrado
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              ),
              child: _buildIndicadores(),
            ),
            const SizedBox(height: 48),
            _buildTeclado(),
          ],
        ),

        // Flecha de retroceso — esquina superior izquierda
        if (widget.onBack != null)
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.black87,
                iconSize: 22,
                tooltip: 'Volver',
                splashRadius: 24,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIndicadores() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < _digitos.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 56,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: filled
                ? Text(
                    _digitos[i],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        );
      }),
    );
  }

  Widget _buildTeclado() {
    const filas = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      children: [
        ...filas.map((fila) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: fila
                    .map((n) =>
                        _buildBoton(label: n, onTap: () => _presionar(n)))
                    .toList(),
              ),
            )),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 80),
              _buildBoton(label: '0', onTap: () => _presionar('0')),
              _buildBotonBorrar(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBoton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 4, top: 4),
        decoration: const BoxDecoration(
          color: Color(0xFFF0F0F0),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotonBorrar() {
    return GestureDetector(
      onTap: _borrar,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFFF0F0F0),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            color: Colors.grey,
            size: 24,
          ),
        ),
      ),
    );
  }
}