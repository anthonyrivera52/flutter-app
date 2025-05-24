import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final authVM = ref.read(authViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              onChanged: authVM.setEmail,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              onChanged: authVM.setPassword,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (authState.errorMessage != null)
              Text(authState.errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: authState.loading ? null : () => authVM.login(context),
              child: authState.loading
                  ? const CircularProgressIndicator()
                  : const Text('Iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
