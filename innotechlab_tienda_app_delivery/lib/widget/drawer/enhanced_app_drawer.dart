// lib/widget/drawer/enhanced_app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_app_mvvm/domain/entities/user_status.dart';
import 'package:delivery_app_mvvm/view/configuration_screen.dart';
import 'package:delivery_app_mvvm/view/feed_back_screen.dart';
import 'package:delivery_app_mvvm/view/order_history_screen.dart';
import 'package:delivery_app_mvvm/view/wallet_screen.dart';
import 'package:delivery_app_mvvm/view/earning_page.dart';
import 'package:delivery_app_mvvm/viewmodel/home_view_model.dart';
import 'package:delivery_app_mvvm/viewmodel/auth_view_model.dart';

/// Drawer mejorado con diseño moderno y secciones organizadas
class EnhancedAppDrawer extends StatelessWidget {
  const EnhancedAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final homeView = Provider.of<HomeViewModel>(context, listen: true);
    final size = MediaQuery.of(context).size;

    return Drawer(
      width: size.width * 0.75,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // Header con información del usuario
              _buildHeader(context, homeView, size),

              // Contenido del menú
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // Sección principal
                    _buildSectionTitle(context, 'Principal'),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.home_rounded,
                      title: 'Inicio',
                      subtitle: 'Pantalla principal',
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.receipt_long_rounded,
                      title: 'Pedidos',
                      subtitle: 'Historial de pedidos',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToOrderHistory(context);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Sección financiera
                    _buildSectionTitle(context, 'Finanzas'),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Billetera',
                      subtitle: 'Gestiona tu dinero',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToWallet(context, authViewModel);
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.trending_up_rounded,
                      title: 'Ganancias',
                      subtitle: 'Ver tus ganancias',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToEarnings(context, authViewModel);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Sección configuración
                    _buildSectionTitle(context, 'Ajustes'),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.settings_rounded,
                      title: 'Configuración',
                      subtitle: 'Ajustes de la app',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToConfig(context, authViewModel);
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.help_outline_rounded,
                      title: 'Ayuda y Feedback',
                      subtitle: 'Contáctanos',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToFeedback(context, authViewModel);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Sección Cursos (placeholder)
                    _buildSectionTitle(context, 'Aprende'),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.school_rounded,
                      title: 'Cursos',
                      subtitle: 'Mejora tus habilidades',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Próximamente: Cursos de capacitación')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Footer con estado de conexión
              _buildFooter(context, homeView, authViewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HomeViewModel homeView, Size size) {
    final userStatus = homeView.userStatus;
    final isOnline = userStatus.status != UserConnectionStatus.offline;

    return Container(
      width: size.width,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar con estado
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage(
                        'https://t3.ftcdn.net/jpg/02/99/21/98/360_F_299219888_2E7GbJyosu0UwAzSGrpIxS0BrmnTCdo4.jpg',
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        isOnline ? Icons.wifi : Icons.wifi_off,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Repartidor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOnline
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOnline ? 'En Línea' : 'Desconectado',
                        style: TextStyle(
                          color: isOnline ? Colors.green[200] : Colors.grey[300],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Rating y ganancias rápidas
          Row(
            children: [
              _buildStatChip(
                icon: Icons.star_rounded,
                iconColor: Colors.amber,
                label: '4.8',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.local_fire_department_rounded,
                iconColor: Colors.orange,
                label: '${homeView.todayOrderCount} pedidos',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
    Color? iconColor,
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
                    color: (iconColor ?? Theme.of(context).primaryColor)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: iconColor ?? Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
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

  Widget _buildFooter(BuildContext context, HomeViewModel homeView, AuthViewModel authViewModel) {
    final isOnline = homeView.userStatus.status != UserConnectionStatus.offline;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón de conexión/desconexión
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                if (isOnline) {
                  homeView.goOffline();
                } else {
                  homeView.goOnline();
                }
              },
              icon: Icon(isOnline ? Icons.wifi_off_rounded : Icons.wifi_rounded),
              label: Text(isOnline ? 'Desconectar' : 'Conectar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOnline ? Colors.red[400] : Colors.green[500],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Botón de cerrar sesión
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              authViewModel.signOut();
            },
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Cerrar Sesión'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[400],
            ),
          ),
        ],
      ),
    );
  }

  // Navegación a Order History
  void _navigateToOrderHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
    );
  }

  // Navegación a Wallet
  void _navigateToWallet(BuildContext context, AuthViewModel authViewModel) {
    if (!authViewModel.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, inicia sesión para ver tu billetera.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WalletScreen()),
    );
  }

  // Navegación a Earnings
  void _navigateToEarnings(BuildContext context, AuthViewModel authViewModel) {
    if (!authViewModel.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, inicia sesión para ver tus ganancias.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EarningPage()),
    );
  }

  // Navegación a Configuration
  void _navigateToConfig(BuildContext context, AuthViewModel authViewModel) {
    if (!authViewModel.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, inicia sesión para acceder a configuración.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ConfigurationScreen()),
    );
  }

  // Navegación a Feedback
  void _navigateToFeedback(BuildContext context, AuthViewModel authViewModel) {
    if (!authViewModel.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, inicia sesión.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
    );
  }
}
