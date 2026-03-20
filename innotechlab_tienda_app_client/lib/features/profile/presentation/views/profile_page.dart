import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/features/profile/presentation/viewmodels/profile_viewmodel.dart';
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
  late VoidCallback _removeListener;

  @override
  void initState() {
    super.initState();
    _removeListener =
        ref.read(profileProvider.notifier).addListener((state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!state.isAuthenticated && state.user == null) {
          context.go('/signin');
        }
        if (state.errorMessage != null) {
          showInfoToast(context,
              message: state.errorMessage!,
              backgroundColor: Colors.red,
              icon: Icons.error_outline,
              isDismissible: true);
          ref.read(profileProvider.notifier).clearError();
        }
      });
    });
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    if (!state.isAuthenticated || state.user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No hay sesión activa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

    final User user = state.user!;

    return SingleChildScrollView(
      child: Column(
        children: [
          _ProfileHeader(user: user),
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _MenuItem(
                icon: Icons.location_on_outlined,
                title: 'Direcciones',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.payment_outlined,
                title: 'Métodos de pago',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.local_offer_outlined,
                title: 'Promociones',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.support_agent_outlined,
                title: 'Soporte',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.settings_outlined,
                title: 'Configuración',
                onTap: () {},
              ),
              const Divider(height: 1),
              _MenuItem(
                icon: Icons.logout_outlined,
                title: 'Cerrar sesión',
                onTap: () => ref.read(profileProvider.notifier).signOut(),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              user.userMetadata?['avatar_url'] as String? ??
                  'https://placehold.co/100x100',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.userMetadata?['display_name'] as String? ?? 'Usuario',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primaryColor),
      title: Text(title,
          style: TextStyle(
              color: color ?? Colors.black, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
