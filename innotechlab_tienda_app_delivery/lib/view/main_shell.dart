// lib/view/main_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delivery_app_mvvm/core/navigation/app_navigation.dart';
import 'package:delivery_app_mvvm/widget/drawer/enhanced_app_drawer.dart';
import 'package:delivery_app_mvvm/service/menu_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pantalla principal que envuelve toda la app con navegación
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late NavigationProvider _navigationProvider;
  late MenuService _menuService;

  @override
  void initState() {
    super.initState();
    _navigationProvider = NavigationProvider();
    _menuService = MenuService(Supabase.instance.client);
  }

  @override
  void dispose() {
    _navigationProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _navigationProvider,
      child: Consumer<NavigationProvider>(
        builder: (context, navProvider, _) {
          return Scaffold(
            drawer: const EnhancedAppDrawer(),
            body: PageView(
              controller: navProvider.pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Tab 0: Home
                const _HomeTab(),
                // Tab 1: Orders
                _OrdersTab(),
                // Tab 2: Earnings
                _EarningsTab(),
                // Tab 3: Wallet
                _WalletTab(),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(navProvider),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(NavigationProvider navProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: AppTab.values.map((tab) {
              final isSelected = navProvider.currentTab == tab;
              return _buildNavItem(
                tab: tab,
                isSelected: isSelected,
                onTap: () => navProvider.setTab(tab),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required AppTab tab,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[500],
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                tab.label,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================
// TAB CONTENT WIDGETS
// ============================================

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    // Import dynamically to avoid circular dependencies
    return const _DynamicImport(child: SizedBox());
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return const _DynamicImport(child: SizedBox());
  }
}

class _EarningsTab extends StatelessWidget {
  const _EarningsTab();

  @override
  Widget build(BuildContext context) {
    return const _DynamicImport(child: SizedBox());
  }
}

class _WalletTab extends StatelessWidget {
  const _WalletTab();

  @override
  Widget build(BuildContext context) {
    return const _DynamicImport(child: SizedBox());
  }
}

// Placeholder para importar las pantallas reales
class _DynamicImport extends StatelessWidget {
  final Widget child;

  const _DynamicImport({required this.child});

  @override
  Widget build(BuildContext context) {
    // Este widget será reemplazado por las pantallas reales
    // Se usa un FutureBuilder para cargar las pantallas bajo demanda
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 100)),
      builder: (context, snapshot) {
        // Retornar placeholder mientras carga
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
