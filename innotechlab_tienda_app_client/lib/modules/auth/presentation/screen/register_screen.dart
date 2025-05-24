import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/flavors.dart';
import '../viewmodels/register_viewmodel.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(registerViewModelProvider.notifier);
    final nameController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await viewModel.register(nameController.text, F.role);
                context.go('/dashboard');
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}