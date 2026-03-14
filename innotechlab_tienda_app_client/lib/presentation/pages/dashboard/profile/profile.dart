import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/pages/dashboard/profile/profile_viewmodel.dart';
import 'package:flutter_app/presentation/widget/common/info_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late VoidCallback _removeAuthProfileListener;

  @override
  void initState() {
    super.initState();

    // Escuchar los cambios en el estado de AuthNotifierProfile
    _removeAuthProfileListener = ref
        .read(authProfileProvider.notifier)
        .addListener((state) {
          // Deferir las acciones de UI hasta después del frame actual
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return; // Asegurarse de que el widget sigue montado

            // Manejar el cierre de sesión exitoso
            // previousState no está disponible directamente con addListener,
            // pero podemos inferir el cambio si isAuthenticated pasa a ser false.
            // También chequeamos si el user es null para confirmar el logout.
            if (!state.isAuthenticated && (state.user == null)) {
              // Navigate to sign in page after logout
              context.go('/signin');
            }
            // Manejar mensajes de error
            if (state.errorMessage != null) {
              showInfoToast(
                context,
                message: state.errorMessage!,
                backgroundColor: Colors.red,
                icon: Icons.error_outline,
                isDismissible: true,
              );
              // Limpiar el mensaje de error en el ViewModel después de mostrarlo
              ref.read(authProfileProvider.notifier).clearErrorMessage();
            }
          });
        });
  }

  @override
  void dispose() {
    _removeAuthProfileListener(); // Asegúrate de cerrar el listener
    super.dispose();
  }

  void _signOut() async {
    // Llama al método signOut del ViewModel, que ya no necesita 'context'
    ref.read(authProfileProvider.notifier).signOut();
    // La navegación se manejará en el listener de initState
  }

  @override
  Widget build(BuildContext context) {
    final authProfileState = ref.watch(authProfileProvider);

    if (!authProfileState.isAuthenticated || authProfileState.user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No hay sesión activa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Por favor inicia sesión para ver tu perfil',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/signin'),
                child: const Text('Iniciar sesión'),
              ),
            ],
          ),
        ),
      );
    }

    final User currentUser = authProfileState.user!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // User info section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(
                    currentUser.userMetadata?['avatar_url'] as String? ??
                        'https://placehold.co/100x100',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser.userMetadata?['display_name'] as String? ??
                            'Usuario',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser.email ?? 'No email',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    // Navigate to edit profile
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.location_on_outlined,
                  title: 'Direcciones',
                  onTap: () {
                    // Navigate to addresses page
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.payment_outlined,
                  title: 'Métodos de pago',
                  onTap: () {
                    // Navigate to payment methods page
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.local_offer_outlined,
                  title: 'Promociones',
                  onTap: () {
                    // Navigate to promotions page
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.support_agent_outlined,
                  title: 'Soporte',
                  onTap: () {
                    // Navigate to support page
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Configuración',
                  onTap: () {
                    // Navigate to settings page
                  },
                ),
                const Divider(height: 1, thickness: 1),
                _buildMenuItem(
                  context,
                  icon: Icons.logout_outlined,
                  title: 'Cerrar sesión',
                  onTap: _signOut,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primaryColor),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
