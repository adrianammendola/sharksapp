
import 'package:flutter/material.dart';
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
  }

  static PainterController _newController() {
    PainterController controller = PainterController();
    controller.thickness = 5.0;
    controller.backgroundColor = Colors.transparent;
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pizarra de Tenis'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => _controller.undo(),
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _controller.clear(),
          ),
          const SizedBox(width: 16),
          _buildColorButton(Colors.black),
          _buildColorButton(Colors.red),
          _buildColorButton(Colors.blue),
          _buildColorButton(Colors.green),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Image.asset(
            'assets/images/pizarra/tennis_court.png',
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
          Painter(_controller),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return IconButton(
      icon: Icon(Icons.circle, color: color),
      onPressed: () {
        _controller.drawColor = color;
      },
    );
  }
}
