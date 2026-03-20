import 'package:flutter/material.dart';
import 'package:flutter_app/presentation/pages/dashboard/home/home.dart';
import 'package:flutter_app/presentation/pages/dashboard/orders/order_list.dart';
import 'package:flutter_app/presentation/pages/dashboard/profile/profile.dart';
import 'package:flutter_app/presentation/pages/dashboard/search/search_page.dart';
import 'package:flutter_app/presentation/pages/dashboard/favorites/favorites_page.dart';
import 'package:flutter_app/presentation/widget/common/responsive_widgets.dart';

class DashboardPage extends StatefulWidget {
  final int? initialTabIndex;

  const DashboardPage({super.key, this.initialTabIndex});

  static const String routeName = '/dashboard';

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late int _selectedIndex;

  static const List<String> _appBarTitles = <String>[
    'Home',
    'Buscar',
    'Pedidos',
    'Favoritos',
    'Perfil',
  ];

  static const List<IconData> _appBarIcons = <IconData>[
    Icons.home,
    Icons.search,
    Icons.list_alt,
    Icons.favorite_border,
    Icons.person,
  ];

  static const List<IconData> _selectedIcons = <IconData>[
    Icons.home,
    Icons.search,
    Icons.list_alt,
    Icons.favorite,
    Icons.person,
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex ?? 0;
  }

  static List<Widget> _widgetOptions(BuildContext context) {
    return <Widget>[
      const HomeTabPageContent(),
      const SearchPage(),
      const OrdersListPage(),
      const FavoritesPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;
    final isExpanded = isDesktop || isTablet;

    final widgets = _widgetOptions(context);

    return Scaffold(
      body: isExpanded
          ? _buildExpandedLayout(widgets)
          : _buildCompactLayout(widgets),
      bottomNavigationBar: isExpanded ? null : _buildBottomNavigationBar(),
    );
  }

  Widget _buildCompactLayout(List<Widget> widgets) {
    return Column(
      children: [
        Expanded(child: widgets.elementAt(_selectedIndex)),
        _buildBottomNavigationBar(),
      ],
    );
  }

  Widget _buildExpandedLayout(List<Widget> widgets) {
    return Row(
      children: [
        _buildNavigationRail(),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: widgets.elementAt(_selectedIndex)),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      destinations: List.generate(
        _appBarTitles.length,
        (index) => NavigationDestination(
          icon: Icon(_appBarIcons[index]),
          selectedIcon: Icon(_selectedIcons[index]),
          label: _appBarTitles[index],
        ),
      ),
    );
  }

  Widget _buildNavigationRail() {
    final isWideDesktop = MediaQuery.sizeOf(context).width >= 1200;

    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      labelType: isWideDesktop
          ? NavigationRailLabelType.all
          : NavigationRailLabelType.selected,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Icon(
          Icons.store,
          size: isWideDesktop ? 40 : 32,
          color: Theme.of(context).primaryColor,
        ),
      ),
      destinations: List.generate(
        _appBarTitles.length,
        (index) => NavigationRailDestination(
          icon: Icon(_appBarIcons[index]),
          selectedIcon: Icon(_selectedIcons[index]),
          label: Text(_appBarTitles[index]),
        ),
      ),
    );
  }
}
