import 'package:flutter/material.dart';
import 'package:flutter_app/presentation/pages/dashboard/home/home.dart';
import 'package:flutter_app/presentation/pages/dashboard/orders/order_list.dart';
import 'package:flutter_app/presentation/pages/dashboard/profile/profile.dart';
import 'package:flutter_app/presentation/pages/cart/cart_page.dart';
// import 'package:flutter_app/presentation/pages/dashboard/search/search_page.dart';
import 'package:flutter_app/presentation/widget/common/responsive_widgets.dart';
import 'package:flutter_app/presentation/provider/dashboard_provider.dart';
import 'package:flutter_app/features/cart/presentation/viewmodels/cart_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:badges/badges.dart' as badges;

class DashboardPage extends ConsumerStatefulWidget {
  final int? initialTabIndex;

  const DashboardPage({super.key, this.initialTabIndex});

  static const String routeName = '/dashboard';

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<String> _appBarTitles = <String>[
    'Home',
    // 'Buscar',
    'Pedidos',
    'Perfil',
  ];

  static const List<IconData> _appBarIcons = <IconData>[
    Icons.home,
    // Icons.search,
    Icons.list_alt,
    Icons.person,
  ];

  static const List<IconData> _selectedIcons = <IconData>[
    Icons.home_rounded,
    // Icons.search_rounded,
    Icons.list_alt_rounded,
    Icons.person_rounded,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTabIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dashboardTabIndexProvider.notifier).state =
            widget.initialTabIndex!;
      });
    }
  }

  static List<Widget> _widgetOptions(BuildContext context) {
    return <Widget>[
      const HomeTabPageContent(),
      // const SearchPage(),
      const OrdersListPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    ref.read(dashboardTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(dashboardTabIndexProvider);
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;
    final isExpanded = isDesktop || isTablet;

    final widgets = _widgetOptions(context);

    // Ensure selectedIndex is within bounds if it was saved as 4
    final safeIndex = selectedIndex >= widgets.length ? 0 : selectedIndex;

    return Scaffold(
      body: isExpanded
          ? _buildExpandedLayout(widgets, safeIndex)
          : _buildCompactLayout(widgets, safeIndex),
    );
  }

  Widget _buildCompactLayout(List<Widget> widgets, int selectedIndex) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _AppDrawer(
        selectedIndex: selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: IndexedStack(index: selectedIndex, children: widgets),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(_appBarIcons[0]),
            activeIcon: Icon(_selectedIcons[0]),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(_appBarIcons[1]),
            activeIcon: Icon(_selectedIcons[1]),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(_appBarIcons[2]),
            activeIcon: Icon(_selectedIcons[2]),
            label: 'Perfil',
          ),
          // const BottomNavigationBarItem(
          //   icon: Icon(Icons.menu),
          //   label: 'Menú',
          // ),
        ],
      ),
      floatingActionButton: _buildCartFAB(),
    );
  }

  Widget _buildCartFAB() {
    return Consumer(
      builder: (context, ref, child) {
        final totalQuantity = ref.watch(
          cartProvider.select((s) => s.totalQuantity),
        );

        return badges.Badge(
          showBadge: totalQuantity > 0,
          badgeContent: Text(
            totalQuantity.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          position: badges.BadgePosition.topEnd(top: 0, end: 0),
          badgeStyle: const badges.BadgeStyle(
            badgeColor: Colors.red,
            padding: EdgeInsets.all(5),
          ),
          child: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext context) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.75,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (_, __) => const CartModalContent(),
                  );
                },
              );
            },
            backgroundColor: AppColors.primaryColor,
            child: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildExpandedLayout(List<Widget> widgets, int selectedIndex) {
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(selectedIndex),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(index: selectedIndex, children: widgets),
          ),
        ],
      ),
      floatingActionButton: _buildCartFAB(),
    );
  }

  Widget _buildNavigationRail(int selectedIndex) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        // Correct index if menu was still present (unlikely with this setup)
        _onItemTapped(index);
      },
      destinations: [
        NavigationRailDestination(
          icon: Icon(_appBarIcons[0]),
          selectedIcon: Icon(_selectedIcons[0]),
          label: Text(_appBarTitles[0]),
        ),
        NavigationRailDestination(
          icon: Icon(_appBarIcons[1]),
          selectedIcon: Icon(_selectedIcons[1]),
          label: Text(_appBarTitles[1]),
        ),
        NavigationRailDestination(
          icon: Icon(_appBarIcons[2]),
          selectedIcon: Icon(_selectedIcons[2]),
          label: Text(_appBarTitles[2]),
        ),
      ],
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const _AppDrawer({required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            accountName: Text(
              user?.userMetadata?['display_name'] ?? 'Usuario',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? 'invitado@example.com'),
          ),
          _DrawerItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            isSelected: selectedIndex == 0,
            onTap: () {
              onItemTapped(0);
              Navigator.pop(context);
            },
          ),
          _DrawerItem(
            icon: Icons.list_alt_outlined,
            selectedIcon: Icons.list_alt,
            label: 'Pedidos',
            isSelected: selectedIndex == 1,
            onTap: () {
              onItemTapped(1);
              Navigator.pop(context);
            },
          ),
          _DrawerItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Perfil',
            isSelected: selectedIndex == 2,
            onTap: () {
              onItemTapped(2);
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          const Divider(),
          _DrawerItem(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                context.go('/signin');
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isSelected ? (selectedIcon ?? icon) : icon,
        color: isSelected ? AppColors.primaryColor : Colors.grey.shade600,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primaryColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }
}
