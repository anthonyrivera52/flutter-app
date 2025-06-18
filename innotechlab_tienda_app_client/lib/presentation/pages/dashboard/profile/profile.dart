import 'package:flutter/material.dart';
import 'package:flutter_app/config/mock/app_mock.dart';
import 'package:flutter_app/presentation/pages/dashboard/profile/profile_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    _removeAuthProfileListener = ref.read(authProfileProvider.notifier).addListener((state) {
      // Deferir las acciones de UI hasta después del frame actual
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // Asegurarse de que el widget sigue montado

        // Manejar el cierre de sesión exitoso
        // previousState no está disponible directamente con addListener,
        // pero podemos inferir el cambio si isAuthenticated pasa a ser false.
        // También chequeamos si el user es null para confirmar el logout.
        if (!state.isAuthenticated && (state.user == null)) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('¡Sesión cerrada exitosamente!')),
          // );
          // context.go('/signIn'); // Redirige a la pantalla de login
        }
        // Manejar mensajes de error
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
          // Limpiar el mensaje de error en el ViewModel después de mostrarlo
          ref.read(authProfileProvider.notifier).clearErrorMessage();
        }
      });
    });
  }

  @override
  void dispose() {
    _removeAuthProfileListener(); // Asegúrate de cerrar el listener
    super.dispose();
  }

  void _signOut() async {
    // Llama al método signOut del ViewModel, que ya no necesita 'context'
    ref.read(authProfileProvider.notifier).signOut();
    // La navegación y los mensajes se manejarán en el listener de initState
  }

  @override
  Widget build(BuildContext context) {
    final authProfileState = ref.watch(authProfileProvider);

    // Usar el usuario mock si authProfileState.user es nulo, de lo contrario usar el real
    final currentUser = authProfileState.user ?? MockData().mockUser;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mostrar información del usuario (siempre se muestra, usando mock si el real es nulo)
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(currentUser.userMetadata?['avatar_url'] ?? 'https://placehold.co/100x100'),
            ),
            const SizedBox(height: 16),
            Text(
              currentUser.userMetadata?['display_name'] ?? 'Usuario',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              currentUser.email ?? 'No email',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 30), // Este SizedBox siempre se renderizará
            // Indicador de carga
            if (authProfileState.isLoading)
              const CircularProgressIndicator()
            else
              // Botón de cierre de sesión
              ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Cerrar Sesión'),
              ),
          ],
        ),
      ),
    );
  }
}
