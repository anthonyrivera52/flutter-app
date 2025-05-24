import 'package:flutter/material.dart';

class ClientOrDeliveryDashboard extends StatefulWidget {
  const ClientOrDeliveryDashboard({super.key});

  @override
  State<ClientOrDeliveryDashboard> createState() => _ClientOrDeliveryDashboardState();
}

class _ClientOrDeliveryDashboardState extends State<ClientOrDeliveryDashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;
  late final List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _pages = const [
      Center(child: Text('Client Home')),
      Center(child: Text('Client Orders')),
      Center(child: Text('Client Profile')),
    ];
    _navItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: _navItems,
        onTap: _onItemTapped,
      ),
    );
  }
}
