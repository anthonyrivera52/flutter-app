import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_tienda/presentation/providers/auth_provider.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';
import 'package:mi_tienda/presentation/widgets/common/custom_button.dart';
import 'package:mi_tienda/presentation/widgets/common/custom_text_field.dart';
import 'package:mi_tienda/presentation/widgets/common/loading_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File
import 'package:cached_network_image/cached_network_image.dart'; // Para cargar imágenes en caché

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    final currentUser = ref.read(authProvider).user;
    if (currentUser != null) {
      _usernameController.text = currentUser.username ?? '';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authNotifier = ref.read(authProvider.notifier);
      String? newAvatarUrl;

      // Si se seleccionó una nueva imagen, subirla primero
      if (_pickedImage != null) {
        newAvatarUrl = await authNotifier.uploadProfileImage(_pickedImage!.path);
        if (newAvatarUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authNotifier.errorMessage ?? 'Error al subir la imagen de perfil'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Actualizar el perfil del usuario
      final success = await authNotifier.updateUserProfile(
        username: _usernameController.text.trim(),
        avatarUrl: newAvatarUrl, // newAvatarUrl será null si no se cambió la imagen
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado con éxito!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authNotifier.errorMessage ?? 'Error al actualizar el perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _signOut() async {
    final authNotifier = ref.read(authProvider.notifier);
    // Asume que tienes un método signOut en AuthNotifier que devuelve Either<Failure, void>
    final success = await authNotifier.signOut(); 

    if (success) { // Si signOut devuelve bool
      context.go('/login');
    } else { // Si signOut devuelve un mensaje de error o false
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authNotifier.errorMessage ?? 'Error al cerrar sesión'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
      ),
      body: authState.isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (currentUser?.avatarUrl != null && currentUser!.avatarUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(currentUser.avatarUrl!) as ImageProvider<Object>
                                : null),
                        child: _pickedImage == null && (currentUser?.avatarUrl == null || currentUser!.avatarUrl!.isEmpty)
                            ? const Icon(Icons.camera_alt, size: 40, color: AppColors.primaryColor)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currentUser?.email ?? 'Correo no disponible',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                    ),
                    const SizedBox(height: 30),
                    CustomTextField(
                      controller: _usernameController,
                      labelText: 'Nombre de Usuario',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, introduce un nombre de usuario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    CustomButton(
                      text: 'Guardar Cambios',
                      onPressed: _saveProfile,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Cerrar Sesión',
                      onPressed: _signOut,
                      backgroundColor: Colors.red.shade600,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}