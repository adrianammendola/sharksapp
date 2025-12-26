import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:painter/painter.dart';

class PizarraScreen extends StatefulWidget {
  const PizarraScreen({Key? key}) : super(key: key);

  @override
  _PizarraScreenState createState() => _PizarraScreenState();
}

class _PizarraScreenState extends State<PizarraScreen> {
  final PainterController _controller = _newController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Para la pizarra queremos un fondo totalmente negro, también en las barras del sistema.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      systemNavigationBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Restaurar un estilo más neutro para el resto de la app
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    super.dispose();
  }

  static PainterController _newController() {
    PainterController controller = PainterController();
    controller.thickness = 5.0;
    controller.backgroundColor = Colors.transparent;
    controller.drawColor = Colors.red; // Color por defecto
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Material(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand, // Asegura que los hijos no posicionados llenen el Stack
          children: [
            // Imagen de fondo
            Image.asset(
              'assets/images/pizarra/tennis_court.png',
              // En horizontal llenamos la pantalla; en vertical mantenemos la vista "normal"
              fit: BoxFit.fill,
            ),
            // Lienzo para dibujar
            Painter(_controller),
            // Controles en la parte inferior
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.undo, color: Colors.white),
                        onPressed: () => _controller.undo(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () => _controller.clear(),
                      ),
                      const SizedBox(width: 16),
                      _buildColorButton(Colors.red),
                      _buildColorButton(Colors.blue),
                      _buildColorButton(Colors.green),
                      _buildColorButton(Colors.yellow),
                      _buildColorButton(Colors.white),
                      _buildColorButton(Colors.black),
                    ],
                  ),
                ),
              ),
            ),
            // Botón para volver atrás
            Positioned(
              top: 40,
              left: 16,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    bool isSelected = _controller.drawColor == color;
    return IconButton(
      icon: Icon(
        isSelected ? Icons.circle : Icons.circle_outlined,
        color: color,
      ),
      iconSize: 32,
      onPressed: () {
        setState(() {
          _controller.drawColor = color;
        });
      },
    );
  }
}