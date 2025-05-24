import 'package:flutter/material.dart';
import 'package:flutter_app/modules/admin/presentation/screen/home_admin.dart';
import 'package:flutter_app/modules/admin/presentation/screen/profile_client.dart';


  class AdminDashboardPage extends StatefulWidget {
    const AdminDashboardPage({super.key});

    @override
    _AdminDashboardPageState createState() => _AdminDashboardPageState();
  }

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Widget _currentPage = const AdminHome();

  void _navigateTo(Widget page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menú Admin'),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () {
                _navigateTo(const AdminHome());
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Pedidos'),
              onTap: () {
                // _navigateTo(const PedidosPage());
                // Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Perfil'),
              onTap: () {
                _navigateTo(const ProfilePage());
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _currentPage,
    );
  }
}