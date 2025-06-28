// lib/widget/drawer/custom_app_drawer.dart
import 'package:delivery_app_mvvm/domain/entities/user_status.dart';
import 'package:delivery_app_mvvm/viewmodel/home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_app_mvvm/viewmodel/auth_view_model.dart'; // Para el logout

class CustomAppDrawer extends StatelessWidget {
  const CustomAppDrawer({super.key, required AuthViewModel authViewModel});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final homeView = Provider.of<HomeViewModel>(context, listen: true);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Encabezado del Drawer (opcional, puedes personalizarlo)
          DrawerHeader(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorDark, // Usa tu color primario
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      'https://t3.ftcdn.net/jpg/02/99/21/98/360_F_299219888_2E7GbJyosu0UwAzSGrpIxS0BrmnTCdo4.jpg',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Nombre del Repartidor', // Puedes obtener esto de tu ViewModel
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Calificación:', // Puedes obtener esto de tu ViewModel
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.star, color: Colors.yellow, size: 20.0),
                    SizedBox(width: 5),
                    Text(
                      '4.5', // Puedes obtener esto de tu ViewModel
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      // Replace with a real property or method from your AuthViewModel, e.g. isOnline
                      (homeView.userStatus.status != UserConnectionStatus.offline ? 'En Línea' : 'Desconectado'
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          // Opciones del menú
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              // Navegar a la pantalla de inicio si no estás ya allí
            },
          ),
          ListTile(
            leading: const Icon(Icons.payments),
            title: const Text('Ganancias'),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              // Navegar al historial de pedidos
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Cursos'),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              // Navegar al historial de pedidos
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              // Navegar a la configuración
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Feedback'),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              // Navegar a la configuración
            },
          ),
          const Divider(), // Separador
          if (homeView.userStatus.status == UserConnectionStatus.online) ...[
            ListTile(
              leading: const Icon(Icons.wifi_off, color: Colors.red),
              title: const Text('Desconectar', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer antes de desconectar
                homeView.goOffline();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer antes de logout
                authViewModel.signOut();
              },
            ),
          ] else if (authViewModel.isAuthenticated) ...[
            ListTile(
              leading: const Icon(Icons.wifi, color: Colors.green),
              title: const Text('Conectar', style: TextStyle(color: Colors.green)),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer antes de conectar
                homeView.goOnline();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer antes de logout
                authViewModel.signOut();
              },
            ),
          ],
        ],
      ),
    );
  }
}