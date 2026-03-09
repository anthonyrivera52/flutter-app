// lib/core/navigation/app_navigation.dart
import 'package:flutter/material.dart';
import 'package:delivery_app_mvvm/view/home_screen.dart';
import 'package:delivery_app_mvvm/view/order_history_screen.dart';
import 'package:delivery_app_mvvm/view/earning_page.dart';
import 'package:delivery_app_mvvm/view/wallet_screen.dart';

/// Enum para las tabs principales de navegación
enum AppTab {
  home(0, 'Inicio', Icons.home_rounded),
  orders(1, 'Pedidos', Icons.receipt_long_rounded),
  earnings(2, 'Ganancias', Icons.trending_up_rounded),
  wallet(3, 'Billetera', Icons.account_balance_wallet_rounded);

  final int tabIndex;
  final String label;
  final IconData icon;

  const AppTab(this.tabIndex, this.label, this.icon);

  static AppTab fromIndex(int index) {
    return AppTab.values.firstWhere(
      (tab) => tab.tabIndex == index,
      orElse: () => AppTab.home,
    );
  }
}

/// Proveedor de estado de navegación
class NavigationProvider extends ChangeNotifier {
  AppTab _currentTab = AppTab.home;
  final PageController _pageController = PageController();

  AppTab get currentTab => _currentTab;
  PageController get pageController => _pageController;

  void setTab(AppTab tab) {
    if (_currentTab != tab) {
      _currentTab = tab;
      _pageController.jumpToPage(tab.tabIndex);
      notifyListeners();
    }
  }

  void setTabByIndex(int index) {
    setTab(AppTab.fromIndex(index));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

/// Scaffold principal con Bottom Navigation y Drawer
class MainScaffold extends StatelessWidget {
  final Widget child;
  final NavigationProvider navigationProvider;
  final Widget? drawer;

  const MainScaffold({
    super.key,
    required this.child,
    required this.navigationProvider,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer,
      body: PageView(
        controller: navigationProvider.pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: const [
          HomeScreen(),
          OrderHistoryScreen(),
          EarningPage(),
          WalletScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: navigationProvider.currentTab.tabIndex,
          onTap: navigationProvider.setTabByIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          elevation: 0,
          items: AppTab.values.map((tab) {
            return BottomNavigationBarItem(
              icon: Icon(tab.icon),
              activeIcon: _buildActiveIcon(tab),
              label: tab.label,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActiveIcon(AppTab tab) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(tab.icon, size: 28),
    );
  }
}
