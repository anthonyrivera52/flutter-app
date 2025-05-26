import 'package:flutter/material.dart';
// Placeholder import for HomeTabPageContent - will be corrected
import 'package:mi_tienda/presentation/pages/home/home_tab_content.dart'; 
// Corrected import for ProfilePage
import 'package:mi_tienda/presentation/pages/profile/profile_page.dart';
// Import for OrdersListPage
import 'package:mi_tienda/presentation/pages/orders/orders_list_page.dart';
// Import for GoRouter
import 'package:go_router/go_router.dart';
// CartPage and NotificationsPage imports are not strictly needed if using path-based navigation
// and not directly referencing their routeName constants.
// However, ProfilePage is used directly in _widgetOptions.


class DashboardPage extends StatefulWidget {
  final int? initialTabIndex; // Accept initialTabIndex

  const DashboardPage({super.key, this.initialTabIndex});

  static const String routeName = '/dashboard'; // Or just '/' if it's the new home

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late int _selectedIndex; // Use late to initialize in initState

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex ?? 0; // Set initial index
  }

  // Define titles for each tab to update AppBar dynamically
  static const List<String> _appBarTitles = <String>[
    'Mi Tienda', // For Home tab
    'My Orders',  // For Orders tab
    'My Profile', // For Profile tab
  ];

  static List<Widget> _widgetOptions(BuildContext context) {
    return <Widget>[
      const HomeTabPageContent(), // Content of old HomePage
      const OrdersListPage(),     // New Orders List Page
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
    // Get the current list of widgets for the body
    final List<Widget> currentWidgetOptions = _widgetOptions(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]), // Dynamic title
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              context.go('/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              context.go('/cart');
            },
          ),
          // Conditionally show profile icon in AppBar if not on Profile tab,
          // or always show if it navigates to a different screen e.g. edit profile.
          // For now, keeping it as per original instruction (will review redundancy later)
          if (_selectedIndex != 2) // Only show if not on Profile tab
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                // This could navigate to ProfilePage using context.go('/profile')
                // or switch to the profile tab.
                // Current logic: switch to the profile tab if not already there.
                if (_selectedIndex != 2) {
                  _onItemTapped(2);
                }
                // If you wanted to navigate to the profile page via router (e.g., from a deep link scenario)
                // else { context.go('/profile'); } 
              },
            ),
        ],
      ),
      body: Center(
        child: currentWidgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt), 
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor, 
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible
      ),
    );
  }
}
