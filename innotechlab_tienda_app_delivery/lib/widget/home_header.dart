// lib/widget/home_header.dart
import 'package:flutter/material.dart';
import 'package:delivery_app_mvvm/domain/entities/user_status.dart'; // Importa UserStatus
import 'package:delivery_app_mvvm/widget/drawer/drawer_menu_button.dart'; // Asegúrate de que esta ruta sea correcta

class HomeHeader extends StatelessWidget {
  final UserStatus userStatus;
  final double totalEarnings;

  const HomeHeader({
    super.key,
    required this.userStatus,
    required this.totalEarnings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const DrawerMenuButton(),
              // Contenedor de ganancias
              Container(
                margin: const EdgeInsets.all(50),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 30,
                  children: [
                    const Text(
                      '\$',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 20),
                    ),
                    Text(
                      totalEarnings.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 50),
              // const SizedBox(width: 40),
              // // Mostrar el estado del usuario (online/offline) y su mensaje
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              //   decoration: BoxDecoration(
              //     color: userStatus.status == 'online' ? Colors.green[100] : Colors.red[100],
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       Icon(
              //         userStatus.status == 'online' ? Icons.online_prediction : Icons.offline_bolt,
              //         color: userStatus.status == 'online' ? Colors.green[700] : Colors.red[700],
              //         size: 20,
              //       ),
              //       const SizedBox(width: 8),
              //       Text(
              //         userStatus.message,
              //         style: TextStyle(
              //           color: userStatus.status == 'online' ? Colors.green[900] : Colors.red[900],
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // Eliminado el SizedBox(width: 40) y el FloatingActionButton de aquí.
              // El FloatingActionButton se moverá al Scaffold en HomeScreen.
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}