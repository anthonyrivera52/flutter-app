// lib/widget/drawer/app_drawer.dart
import 'package:delivery_app_mvvm/core/navigation/app_navigation.dart';
import 'package:delivery_app_mvvm/domain/entities/user_status.dart';
import 'package:delivery_app_mvvm/view/configuration_screen.dart';
import 'package:delivery_app_mvvm/view/feed_back_screen.dart';
import 'package:delivery_app_mvvm/view/home_screen.dart';
import 'package:delivery_app_mvvm/viewmodel/auth_view_model.dart';
import 'package:delivery_app_mvvm/viewmodel/home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  final AuthViewModel authViewModel;
  final HomeViewModel homeViewModel;

  const AppDrawer({
    super.key,
    required this.authViewModel,
    required this.homeViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header con gradiente
            _buildHeader(context),

            // Sección Principal
            _buildSectionTitle('Principal'),
            _buildMenuItem(
              context: context,
              icon: Icons.home_rounded,
              title: 'Inicio',
              subtitle: 'Pantalla principal',
              onTap: () => _navigateAndClose(context, AppTab.home),
            ),

            // Sección Órdenes
            _buildSectionTitle('Órdenes'),
            _buildMenuItem(
              context: context,
              icon: Icons.receipt_long_rounded,
              title: 'Historial',
              subtitle: 'Tus pedidos anteriores',
              onTap: () => _navigateAndClose(context, AppTab.orders),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.history_rounded,
              title: 'En Progreso',
              subtitle: 'Pedidos activos',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),

            // Sección Finanzas
            _buildSectionTitle('Finanzas'),
            _buildMenuItem(
              context: context,
              icon: Icons.trending_up_rounded,
              title: 'Ganancias',
              subtitle: 'Ver tus ingresos',
              onTap: () => _navigateAndClose(context, AppTab.earnings),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.account_balance_wallet_rounded,
              title: 'Billetera',
              subtitle: 'Gestionar pagos',
              onTap: () => _navigateAndClose(context, AppTab.wallet),
            ),

            // Sección Configuración
            _buildSectionTitle('Ajustes'),
            _buildMenuItem(
              context: context,
              icon: Icons.settings_rounded,
              title: 'Configuración',
              subtitle: 'Personalizar app',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConfigurationScreen()),
                );
              },
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.help_outline_rounded,
              title: 'Ayuda y Feedback',
              subtitle: 'Contáctanos',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                );
              },
            ),

            const Divider(height: 32),

            // Estado de conexión
            _buildConnectionStatus(context),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Avatar
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            // Nombre
            Text(
              authViewModel.currentUser?.email?.split('@').first ?? 'Repartidor',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(homeViewModel.userStatus.status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(homeViewModel.userStatus.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            // Estadísticas rápidas
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('4.8', 'Rating'),
                  Container(width: 1, height: 30, color: Colors.white30),
                  _buildStatItem('150+', 'Entregas'),
                  Container(width: 1, height: 30, color: Colors.white30),
                  _buildStatItem('\$500', 'Este mes'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    final isOnline = homeViewModel.userStatus.status == UserConnectionStatus.online;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isOnline ? 'Conectado - Recibiendo pedidos' : 'Desconectado',
              style: TextStyle(
                color: isOnline ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (isOnline) {
                homeViewModel.goOffline();
              } else {
                homeViewModel.goOnline();
              }
              Navigator.pop(context);
            },
            child: Text(
              isOnline ? 'Desconectar' : 'Conectar',
              style: TextStyle(
                color: isOnline ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateAndClose(BuildContext context, AppTab tab) {
    Navigator.pop(context);
    // Get the navigation provider from context
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    navProvider.setTab(tab);
  }

  Color _getStatusColor(UserConnectionStatus status) {
    switch (status) {
      case UserConnectionStatus.online:
        return Colors.green;
      case UserConnectionStatus.offline:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(UserConnectionStatus status) {
    switch (status) {
      case UserConnectionStatus.online:
        return 'En Línea';
      case UserConnectionStatus.offline:
        return 'Desconectado';
      default:
        return 'Desconocido';
    }
  }
}
