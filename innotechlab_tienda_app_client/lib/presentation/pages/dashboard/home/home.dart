import 'package:flutter/material.dart';
import 'package:flutter_app/config/constants/category_constants.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/features/products/domain/models/product_entity.dart';
import 'package:flutter_app/features/products/presentation/viewmodels/home_viewmodel.dart';
import 'package:flutter_app/presentation/widget/common/full_map_widget.dart';
import 'package:flutter_app/presentation/widget/common/shop_panel_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedCategoryProvider = StateProvider<String>((ref) {
  return CategoryConstants.allProductsCategoryId;
});

class HomeTabPageContent extends ConsumerStatefulWidget {
  const HomeTabPageContent({super.key});

  @override
  ConsumerState<HomeTabPageContent> createState() => _HomeTabPageContentState();
}

class _HomeTabPageContentState extends ConsumerState<HomeTabPageContent> {
  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final homeNotifier = ref.read(homeProvider.notifier);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);

    if (homeState.isLoading && homeState.nearbyShops.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedShop = homeState.selectedShop;
    final products = homeState.products;
    final categories = _getCategories(products);

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Mapa completo
              SizedBox.expand(
                child: FullMapWidget(
                  nearbyShops: homeState.nearbyShops,
                  userLatitude: homeState.userLatitude ?? 0,
                  userLongitude: homeState.userLongitude ?? 0,
                  selectedShop: selectedShop,
                  onShopSelected: (shop) {
                    ref.read(selectedCategoryProvider.notifier).state =
                        CategoryConstants.allProductsCategoryId;
                    homeNotifier.selectShop(shop);
                  },
                ),
              ),

              // Banner de ubicación
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _LocationBanner(
                      locationMessage: homeState.locationMessage,
                      errorMessage: homeState.errorMessage,
                      onRefresh: homeNotifier.refreshNearbyShops,
                    ),
                  ),
                ),
              ),

              // Panel de comercio seleccionado
              if (selectedShop != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ShopPanelWidget(
                    shop: selectedShop,
                    products: _filterProducts(
                      products: products,
                      selectedCategoryId: selectedCategoryId,
                    ),
                    categories: categories,
                    selectedCategory: selectedCategoryId,
                    onCategorySelected: (category) {
                      ref.read(selectedCategoryProvider.notifier).state =
                          category;
                    },
                    onClose: () {
                      ref.read(selectedCategoryProvider.notifier).state =
                          CategoryConstants.allProductsCategoryId;
                      homeNotifier.clearSelectedShop();
                    },
                    onChangeShop: () {
                      ref.read(selectedCategoryProvider.notifier).state =
                          CategoryConstants.allProductsCategoryId;
                      homeNotifier.clearSelectedShop();
                    },
                    shopHours: homeState.selectedShopHours,
                    isLoadingHours: homeState.isLoadingHours,
                  ),
                ),

              // Loading overlay
              if (homeState.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.15),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<String> _getCategories(List<Product> products) {
    if (products.isEmpty) {
      return ['all'];
    }
    final uniqueCategories = products.map((p) => p.categoryId).toSet();
    return ['all', ...uniqueCategories];
  }

  List<Product> _filterProducts({
    required List<Product> products,
    required String selectedCategoryId,
  }) {
    if (selectedCategoryId == CategoryConstants.allProductsCategoryId) {
      return products;
    }
    return products.where((p) => p.categoryId == selectedCategoryId).toList();
  }
}

class _LocationBanner extends StatelessWidget {
  final String? locationMessage;
  final String? errorMessage;
  final VoidCallback onRefresh;

  const _LocationBanner({
    required this.locationMessage,
    required this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null && locationMessage == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasError ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? Colors.red.shade200 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasError
                  ? Colors.red.shade100
                  : AppColors.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasError ? Icons.location_off : Icons.near_me,
              color: hasError ? Colors.red : AppColors.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasError ? 'Ubicación no disponible' : 'Tu ubicación',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasError
                      ? (errorMessage ?? 'Error de ubicación')
                      : (locationMessage ?? 'Detectando...'),
                  style: TextStyle(
                    fontSize: 13,
                    color: hasError ? Colors.red.shade700 : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!hasError)
            IconButton(
              onPressed: onRefresh,
              icon: Icon(Icons.refresh, color: Colors.grey.shade600, size: 20),
              tooltip: 'Actualizar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
