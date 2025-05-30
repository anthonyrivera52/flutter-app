import 'package:flutter/material.dart';
import 'package:flutter_app/presentation/widget/common/home_appbar.dart';

class HomeTabPageContent extends StatelessWidget {
  const HomeTabPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: const Text('Mi Tienda'),
        actions: const [
          // Usa el widget refactorizado que contiene los botones de acción
          HomeAppBarActions(),
          SizedBox(width: 10), // Espacio al final de los iconos
        ],
      ),
      body: Center(
        child: Text(
          'Welcome to the Home Tab',
        ),
      ),
    );
  }
}