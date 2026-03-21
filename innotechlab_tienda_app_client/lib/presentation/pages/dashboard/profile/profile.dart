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
  late VoidCallback _removeAuthProfileListener;

  @override
  void initState() {
    super.initState();

    // Escuchar los cambios en el estado de AuthNotifierProfile
    _removeAuthProfileListener = ref.read(profileProvider.notifier).addListener(
      (state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!state.isAuthenticated && state.user == null) {
            context.go('/signin');
          }
          if (state.errorMessage != null) {
            showInfoToast(
              context,
              message: state.errorMessage!,
              backgroundColor: Colors.red,
              icon: Icons.error_outline,
              isDismissible: true,
            );
            ref.read(profileProvider.notifier).clearError();
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _removeAuthProfileListener(); // Asegúrate de cerrar el listener
    super.dispose();
  }

  void _signOut() async {
    ref.read(profileProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authProfileState = ref.watch(profileProvider);

    if (!authProfileState.isAuthenticated || authProfileState.user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_person_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sesión Inactiva',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Inicia sesión para acceder a tu perfil y pedidos',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/signin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Iniciar sesión',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final User currentUser = authProfileState.user!;
    final String displayName =
        currentUser.userMetadata?['display_name'] as String? ?? 'Usuario';
    final String email = currentUser.email ?? '';
    final String avatarUrl =
        currentUser.userMetadata?['avatar_url'] as String? ??
        'https://ui-avatars.com/api/?name=$displayName&background=random';

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Animated Gradient Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryColor.withBlue(150),
                          AppColors.primaryColor.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                  // Abstract decorative elements
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 30,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 54,
                                      backgroundColor: Colors.white,
                                      backgroundImage: NetworkImage(avatarUrl),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loyalty Premium Card
                  const _LoyaltyPremiumCard(),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Mi Cuenta'),
                  const SizedBox(height: 12),
                  _ProfileItemGroup(
                    items: [
                      _ProfileItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Editar Perfil',
                        subtitle: 'Nombre, correo y foto de perfil',
                        onTap: () {},
                        iconBgColor: const Color(0xFFE8F0FE),
                        iconColor: const Color(0xFF1A73E8),
                      ),
                      _ProfileItem(
                        icon: Icons.location_on_outlined,
                        title: 'Mis Direcciones',
                        subtitle: 'Lugares de entrega guardados',
                        onTap: () {},
                        iconBgColor: const Color(0xFFFEF3E0),
                        iconColor: const Color(0xFFF57C00),
                      ),
                      _ProfileItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Métodos de Pago',
                        subtitle: 'Gestiona tus tarjetas y pagos',
                        onTap: () {},
                        iconBgColor: const Color(0xFFE6F4EA),
                        iconColor: const Color(0xFF1E8E3E),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  _buildSectionTitle('Explorar'),
                  const SizedBox(height: 12),
                  _ProfileItemGroup(
                    items: [
                      _ProfileItem(
                        icon: Icons.confirmation_number_outlined,
                        title: 'Cupones y Descuentos',
                        subtitle: 'Tienes 3 cupones disponibles',
                        onTap: () {},
                        iconBgColor: const Color(0xFFFCE4EC),
                        iconColor: const Color(0xFFC2185B),
                        trailing: _buildBadge('3'),
                      ),
                      _ProfileItem(
                        icon: Icons.stars_rounded,
                        title: 'Mis Reseñas',
                        subtitle: 'Calificaciones de tus pedidos',
                        onTap: () {},
                        iconBgColor: const Color(0xFFF3E5F5),
                        iconColor: const Color(0xFF7B1FA2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  _buildSectionTitle('Preferencias'),
                  const SizedBox(height: 12),
                  _ProfileItemGroup(
                    items: [
                      _ProfileItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notificaciones',
                        subtitle: 'Configura tus alertas',
                        onTap: () {},
                        iconBgColor: const Color(0xFFE0F7FA),
                        iconColor: const Color(0xFF0097A7),
                      ),
                      _ProfileItem(
                        icon: Icons.security_outlined,
                        title: 'Seguridad',
                        subtitle: 'Cambiar contraseña y protección',
                        onTap: () {},
                        iconBgColor: const Color(0xFFF5F5F5),
                        iconColor: const Color(0xFF616161),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  _buildSectionTitle('Soporte'),
                  const SizedBox(height: 12),
                  _ProfileItemGroup(
                    items: [
                      _ProfileItem(
                        icon: Icons.headset_mic_outlined,
                        title: 'Centro de Ayuda',
                        subtitle: 'Chat de soporte y preguntas',
                        onTap: () {},
                        iconBgColor: const Color(0xFFEFEBE9),
                        iconColor: const Color(0xFF5D4037),
                      ),
                      _ProfileItem(
                        icon: Icons.info_outline_rounded,
                        title: 'Acerca de',
                        subtitle: 'Términos, privacidad y versión',
                        onTap: () {},
                        iconBgColor: const Color(0xFFF1F3F4),
                        iconColor: const Color(0xFF3C4043),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Logout Button
                  InkWell(
                    onTap: _signOut,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Cerrar Sesión',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildBadge(String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LoyaltyPremiumCard extends StatelessWidget {
  const _LoyaltyPremiumCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.amber,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Membresía Premium',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nivel Oro • 2500 Puntos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.7,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber, Colors.orange.shade400],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '700 pts para el próximo nivel',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                '70%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileItemGroup extends StatelessWidget {
  final List<_ProfileItem> items;
  const _ProfileItemGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              item,
              if (index < items.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 72, right: 20),
                  child: Divider(height: 1, color: Colors.grey.shade50),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconBgColor;
  final Color? iconColor;
  final Widget? trailing;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconBgColor,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconBgColor ?? AppColors.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primaryColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          letterSpacing: -0.3,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.grey.shade300,
            size: 14,
          ),
      onTap: onTap,
    );
  }
}
