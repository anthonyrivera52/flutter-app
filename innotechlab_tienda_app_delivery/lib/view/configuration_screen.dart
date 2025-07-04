import 'package:delivery_app_mvvm/view/feed_back_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_app_mvvm/viewmodel/auth_view_model.dart'; // Assuming you have this

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  // Example settings values (these would typically come from a ViewModel/repository)
  bool _newOrderNotifications = true;
  bool _chatNotifications = true;
  bool _darkModeEnabled = false;
  String _preferredNavigationApp = 'Google Maps'; // Example default

  @override
  Widget build(BuildContext context) {
    // You might want to access a SettingsViewModel here if you have one
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuraciones'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sección de Cuenta
          _buildSectionHeader('Cuenta'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Ver/Editar Perfil'),
            onTap: () {
              // TODO: Navigate to Profile editing page
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navegar a Perfil')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.car_rental),
            title: const Text('Información del Vehículo'),
            onTap: () {
              // TODO: Navigate to Vehicle info page
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navegar a Vehículo')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Cambiar Contraseña'),
            onTap: () {
              // TODO: Navigate to Change Password page
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navegar a Cambiar Contraseña')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () {
              // TODO: Implement Logout logic using AuthViewModel
              _showLogoutConfirmationDialog(context, authViewModel);
            },
          ),
          const Divider(),

          // Sección de Notificaciones
          _buildSectionHeader('Notificaciones'),
          SwitchListTile(
            title: const Text('Nuevos Pedidos'),
            subtitle: const Text('Recibir alertas de nuevos pedidos disponibles'),
            secondary: const Icon(Icons.delivery_dining),
            value: _newOrderNotifications,
            onChanged: (bool value) {
              setState(() {
                _newOrderNotifications = value;
                // TODO: Save this setting (e.g., to SharedPreferences or ViewModel)
              });
            },
          ),
          SwitchListTile(
            title: const Text('Mensajes de Chat'),
            subtitle: const Text('Recibir notificaciones de mensajes de clientes'),
            secondary: const Icon(Icons.chat_bubble_outline),
            value: _chatNotifications,
            onChanged: (bool value) {
              setState(() {
                _chatNotifications = value;
                // TODO: Save this setting
              });
            },
          ),
          // You can add more notification specific options (sound, vibrate)
          const Divider(),

          // Sección de Preferencias de la App
          _buildSectionHeader('Preferencias de la App'),
          SwitchListTile(
            title: const Text('Modo Oscuro'),
            subtitle: const Text('Activar tema oscuro para la aplicación'),
            secondary: const Icon(Icons.dark_mode),
            value: _darkModeEnabled,
            onChanged: (bool value) {
              setState(() {
                _darkModeEnabled = value;
                // TODO: Implement Theme change logic here or via a ThemeProvider
                // Example: Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Idioma'),
            subtitle: const Text('Español (España)'), // Display current language
            onTap: () {
              // TODO: Implement Language selection dialog/page
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navegar a Selección de Idioma')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.navigation),
            title: const Text('Aplicación de Navegación Preferida'),
            subtitle: Text(_preferredNavigationApp),
            onTap: () {
              _showNavigationAppSelectionDialog(context);
            },
          ),
          const Divider(),

          // Sección de Ayuda y Soporte
          _buildSectionHeader('Ayuda y Soporte'),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Enviar Sugerencia/Queja'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FeedbackScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Centro de Ayuda / Preguntas Frecuentes'),
            onTap: () {
              // TODO: Launch URL to help center
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Abrir Centro de Ayuda')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.call),
            title: const Text('Contactar Soporte'),
            onTap: () {
              // TODO: Launch phone dialer or open in-app chat
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contactar Soporte')));
            },
          ),
          const Divider(),

          // Sección de Información de la App
          _buildSectionHeader('Información de la App'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versión de la App'),
            trailing: Text('1.0.0'), // Replace with actual app version
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Términos y Condiciones'),
            onTap: () {
              // TODO: Launch URL to T&C
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Abrir Términos y Condiciones')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Política de Privacidad'),
            onTap: () {
              // TODO: Launch URL to Privacy Policy
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Abrir Política de Privacidad')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context, AuthViewModel authViewModel) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                await authViewModel.signOut(); // Perform logout
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showNavigationAppSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('App de Navegación Preferida'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<String>(
                title: const Text('Google Maps'),
                value: 'Google Maps',
                groupValue: _preferredNavigationApp,
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _preferredNavigationApp = value;
                      // TODO: Save this setting
                    });
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Waze'),
                value: 'Waze',
                groupValue: _preferredNavigationApp,
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _preferredNavigationApp = value;
                      // TODO: Save this setting
                    });
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
              // Add more navigation apps if needed
            ],
          ),
        );
      },
    );
  }
}