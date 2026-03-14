import 'package:flutter/material.dart';
import 'package:flutter_app/core/location/location_result.dart';
import 'package:flutter_app/core/location/location_service.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/common/custom_text_field.dart';
import 'package:flutter_app/presentation/widget/common/info_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

/// Provider for location selection page
final locationSelectionProvider =
    StateNotifierProvider<LocationSelectionNotifier, LocationSelectionState>((
      ref,
    ) {
      return LocationSelectionNotifier();
    });

class LocationSelectionState {
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isLoading;
  final String? errorMessage;

  const LocationSelectionState({
    this.address,
    this.latitude,
    this.longitude,
    this.isLoading = false,
    this.errorMessage,
  });

  LocationSelectionState copyWith({
    String? address,
    double? latitude,
    double? longitude,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LocationSelectionState(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LocationSelectionNotifier extends StateNotifier<LocationSelectionState> {
  final LocationService _locationService;

  LocationSelectionNotifier()
    : _locationService = LocationService(),
      super(const LocationSelectionState());

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
  }

  Future<void> updateAddress(String address) async {
    state = state.copyWith(address: address);
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final location = await _locationService.getCurrentPosition(
        accuracy: LocationAccuracy.high,
        timeout: const Duration(seconds: 15),
        maxRetries: 2,
      );

      state = state.copyWith(
        isLoading: false,
        latitude: location.latitude,
        longitude: location.longitude,
        address:
            'Ubicación GPS (${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)})',
      );
    } on LocationException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al obtener ubicación',
      );
    }
  }
}

class LocationSelectionPage extends ConsumerStatefulWidget {
  const LocationSelectionPage({super.key});

  @override
  ConsumerState<LocationSelectionPage> createState() =>
      _LocationSelectionPageState();
}

class _LocationSelectionPageState extends ConsumerState<LocationSelectionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Try to load saved address if available
    final savedAddress = ref.read(locationSelectionProvider).address;
    if (savedAddress != null) {
      _addressController.text = savedAddress;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    await ref.read(locationSelectionProvider.notifier).getCurrentLocation();

    if (!mounted) return;

    final state = ref.read(locationSelectionProvider);
    if (state.errorMessage != null) {
      showInfoToast(
        context,
        message: state.errorMessage!,
        backgroundColor: AppColors.errorColor,
        icon: Icons.location_off,
        isDismissible: true,
      );
    } else if (state.address != null) {
      _addressController.text = state.address!;
      showInfoToast(
        context,
        message: 'Ubicación aplicada',
        backgroundColor: AppColors.successColor,
        icon: Icons.my_location,
        isDismissible: true,
      );
    }
  }

  void _continueToHome() {
    if (_formKey.currentState?.validate() ?? false) {
      // Save the address to the provider
      ref
          .read(locationSelectionProvider.notifier)
          .updateAddress(_addressController.text.trim());

      // Navigate to home
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationSelectionProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 30),
                Text(
                  '¿Dónde te entregamos?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ingresa tu dirección de entrega para ver productos y tiendas disponibles en tu zona.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _addressController,
                        labelText: 'Dirección de entrega',
                        hintText: 'Ej: Calle Principal 123, Ciudad',
                        prefixIcon: Icons.location_on_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La dirección es obligatoria';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _useCurrentLocation,
                      icon: locationState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      color: AppColors.primaryColor,
                      tooltip: 'Usar ubicación actual',
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                CustomButton(text: 'Continuar', onPressed: _continueToHome),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // Allow skipping location selection (use default or ask later)
                    context.go('/');
                  },
                  child: const Text(
                    'Usar ubicación más tarde',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
