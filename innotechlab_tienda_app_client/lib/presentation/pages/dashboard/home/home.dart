import 'package:flutter/material.dart';
import 'package:flutter_app/config/constants/category_constants.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/features/products/domain/models/product_entity.dart';
import 'package:flutter_app/features/products/domain/models/category_entity.dart';
import 'package:flutter_app/features/products/presentation/viewmodels/home_viewmodel.dart';
import 'package:flutter_app/presentation/provider/shops_polling_provider.dart';
import 'package:flutter_app/presentation/widget/common/full_map_widget.dart';
import 'package:flutter_app/presentation/widget/common/shop_panel_widget.dart';
import 'package:flutter_app/presentation/widget/common/responsive_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/presentation/widget/common/debounced_search_input.dart';
import 'package:flutter_app/presentation/widget/common/price_display.dart';
import 'package:flutter_app/presentation/provider/region_provider.dart';
import 'package:flutter_app/presentation/widget/common/region_change_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/features/products/domain/models/shop_entity.dart';
import 'dart:ui';

final selectedCategoryProvider = StateProvider<String>((ref) {
  return CategoryConstants.allProductsCategoryId;
});

class HomeTabPageContent extends ConsumerStatefulWidget {
  const HomeTabPageContent({super.key});

  @override
  ConsumerState<HomeTabPageContent> createState() => _HomeTabPageContentState();
}

class _HomeTabPageContentState extends ConsumerState<HomeTabPageContent> {
  bool _hasCheckedRegionModal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRegionChange();
    });
  }

  Future<void> _checkRegionChange() async {
    if (_hasCheckedRegionModal) return;
    _hasCheckedRegionModal = true;

    final regionState = ref.read(regionProvider);

    if (regionState.shouldShowCountryChangeModal && mounted) {
      final shouldUpdate = await RegionChangeModal.show(
        context,
        detectedConfig: regionState.gpsDetectedConfig!,
        currentConfig: regionState.config,
      );

      if (!mounted) return;

      if (shouldUpdate == true) {
        await ref.read(regionProvider.notifier).acceptGPSCountry();
      } else {
        await ref.read(regionProvider.notifier).keepCurrentCountry();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pollingState = ref.watch(shopsPollingProvider);
    final homeState = ref.watch(homeProvider);
    final homeNotifier = ref.read(homeProvider.notifier);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);

    ref.listen(shopsPollingProvider, (previous, next) {
      if (next.shops != previous?.shops) {
        ref.read(homeProvider.notifier).updateNearbyShops(next.shops);
      }
    });

    // Ensure state is updated on initial load
    if (homeState.nearbyShops.isEmpty && pollingState.shops.isNotEmpty) {
      Future.microtask(
        () => ref
            .read(homeProvider.notifier)
            .updateNearbyShops(pollingState.shops),
      );
    }

    if (pollingState.isLoading && pollingState.shops.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedShop = homeState.selectedShop;
    final products = homeState.products;
    final categoryIds = _getCategoryIds(homeState.categories);
    final categories = homeState.categories;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AdaptiveLayout(
        mobile: (_) => _buildMobileLayout(
          pollingState: pollingState,
          homeState: homeState,
          homeNotifier: homeNotifier,
          selectedCategoryId: selectedCategoryId,
          selectedShop: selectedShop,
          products: products,
          categoryIds: categoryIds,
          categories: categories,
        ),
        tablet: (_) => _buildExpandedLayout(
          pollingState: pollingState,
          homeState: homeState,
          homeNotifier: homeNotifier,
          selectedCategoryId: selectedCategoryId,
          selectedShop: selectedShop,
          products: products,
          categoryIds: categoryIds,
          categories: categories,
          mapFlex: 6,
          panelFlex: 4,
        ),
        desktop: (_) => _buildExpandedLayout(
          pollingState: pollingState,
          homeState: homeState,
          homeNotifier: homeNotifier,
          selectedCategoryId: selectedCategoryId,
          selectedShop: selectedShop,
          products: products,
          categoryIds: categoryIds,
          categories: categories,
          mapFlex: 5,
          panelFlex: 5,
        ),
      ),
    );
  }

  Widget _buildMobileLayout({
    required ShopsPollingState pollingState,
    required HomeState homeState,
    required HomeNotifier homeNotifier,
    required String selectedCategoryId,
    required dynamic selectedShop,
    required List<Product> products,
    required List<String> categoryIds,
    required List<Category> categories,
  }) {
    return Stack(
      children: [
        SizedBox.expand(
          child: FullMapWidget(
            nearbyShops: homeState.filteredNearbyShops,
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
        _buildFloatingHeader(
          context: context,
          ref: ref,
          homeNotifier: homeNotifier,
          isLoading: pollingState.isLoading,
        ),
        if (selectedShop != null)
          Positioned.fill(
            child: ShopPanelWidget(
              shop: selectedShop,
              products: _filterProducts(
                products: products,
                selectedCategoryId: selectedCategoryId,
              ),
              categoryIds: categoryIds,
              categories: categories,
              selectedCategoryId: selectedCategoryId,
              onCategorySelected: (categoryId) {
                ref.read(selectedCategoryProvider.notifier).state = categoryId;
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
              isLoadingProducts: homeState.isLoading,
            ),
          ),
        if (pollingState.isLoading && homeState.nearbyShops.isEmpty)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildFloatingHeader({
    required BuildContext context,
    required WidgetRef ref,
    required HomeNotifier homeNotifier,
    required bool isLoading,
  }) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.9),
                    child: DebouncedSearchInput(
                      onChanged: (v) => homeNotifier.setSearchQuery(v),
                      hintText: 'Buscar comercios...',
                      debounceDuration: const Duration(milliseconds: 300),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _FloatingCircleButton(
            icon: Icons.refresh,
            onPressed: () => ref.read(shopsPollingProvider.notifier).refresh(),
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedLayout({
    required ShopsPollingState pollingState,
    required HomeState homeState,
    required HomeNotifier homeNotifier,
    required String selectedCategoryId,
    required dynamic selectedShop,
    required List<Product> products,
    required List<String> categoryIds,
    required List<Category> categories,
    required int mapFlex,
    required int panelFlex,
  }) {
    return Row(
      children: [
        Expanded(
          flex: mapFlex,
          child: Stack(
            children: [
              FullMapWidget(
                nearbyShops: homeState.filteredNearbyShops,
                userLatitude: homeState.userLatitude ?? 0,
                userLongitude: homeState.userLongitude ?? 0,
                selectedShop: selectedShop,
                onShopSelected: (shop) {
                  ref.read(selectedCategoryProvider.notifier).state =
                      CategoryConstants.allProductsCategoryId;
                  homeNotifier.selectShop(shop);
                },
              ),
              _buildFloatingHeader(
                context: context,
                ref: ref,
                homeNotifier: homeNotifier,
                isLoading: pollingState.isLoading,
              ),
              if (pollingState.isLoading && homeState.nearbyShops.isEmpty)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.15),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
        if (selectedShop != null)
          Expanded(
            flex: panelFlex,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Colors.grey.shade200)),
              ),
              child: _FixedShopPanel(
                shop: selectedShop,
                products: _filterProducts(
                  products: products,
                  selectedCategoryId: selectedCategoryId,
                ),
                categoryIds: categoryIds,
                categories: categories,
                selectedCategoryId: selectedCategoryId,
                onCategorySelected: (categoryId) {
                  ref.read(selectedCategoryProvider.notifier).state =
                      categoryId;
                },
                onClose: () {
                  ref.read(selectedCategoryProvider.notifier).state =
                      CategoryConstants.allProductsCategoryId;
                  homeNotifier.clearSelectedShop();
                },
                shopHours: homeState.selectedShopHours,
                isLoadingHours: homeState.isLoadingHours,
              ),
            ),
          ),
        if (selectedShop == null && pollingState.shops.isNotEmpty)
          Expanded(
            flex: panelFlex,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(left: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Selecciona una tienda',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toca un marcador en el mapa para ver los productos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<String> _getCategoryIds(List<Category> categories) {
    if (categories.isEmpty) {
      return [CategoryConstants.allProductsCategoryId];
    }
    final categoryIds = categories.map((c) => c.id).toList();
    return [CategoryConstants.allProductsCategoryId, ...categoryIds];
  }

  List<String> _getCategories(List<Product> products) {
    if (products.isEmpty) {
      return [CategoryConstants.allProductsCategoryId];
    }
    final uniqueCategories = products
        .map((p) => p.categoryId)
        .where((id) => id.isNotEmpty)
        .toSet();
    return [CategoryConstants.allProductsCategoryId, ...uniqueCategories];
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

class _FloatingCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;

  const _FloatingCircleButton({
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: IconButton(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: AppColors.primaryColor),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _FixedShopPanel extends StatelessWidget {
  final dynamic shop;
  final List<Product> products;
  final List<String> categoryIds;
  final List<Category> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onClose;
  final List<dynamic> shopHours;
  final bool isLoadingHours;

  const _FixedShopPanel({
    required this.shop,
    required this.products,
    required this.categoryIds,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onClose,
    required this.shopHours,
    required this.isLoadingHours,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: shop.logoUrl.isNotEmpty
                    ? NetworkImage(shop.logoUrl)
                    : null,
                child: shop.logoUrl.isEmpty
                    ? Icon(Icons.store, color: Colors.grey.shade400)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shop.address,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                tooltip: 'Cerrar',
              ),
            ],
          ),
        ),
        if (categoryIds.length > 1)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categoryIds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final categoryId = categoryIds[index];
                final category = index > 0 && index - 1 < categories.length
                    ? categories[index - 1]
                    : null;
                final isSelected = categoryId == selectedCategoryId;
                final displayName = categoryId == 'all'
                    ? 'Todos'
                    : (category?.name ?? categoryId);
                return FilterChip(
                  label: Text(
                    displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => onCategorySelected(categoryId),
                  selectedColor: AppColors.primaryColor,
                  backgroundColor: Colors.grey.shade100,
                  checkmarkColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                );
              },
            ),
          ),
        Expanded(
          child: products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay productos disponibles',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _ProductCard(product: products[index], shop: shop);
                  },
                ),
        ),
      ],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 3;
    if (width >= 900) return 2;
    return 2;
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final dynamic shop;

  const _ProductCard({required this.product, required this.shop});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final bool isShopOpen = shop.isOpen ?? false;
        final bool hasActiveChannels =
            (shop.deliveryStatus == ShopDeliveryStatus.active ||
                shop.deliveryStatus == ShopDeliveryStatus.waiting) ||
            (shop.pickupStatus == ShopDeliveryStatus.active ||
                shop.pickupStatus == ShopDeliveryStatus.waiting);
        final bool canViewDetail = isShopOpen && hasActiveChannels;

        if (!canViewDetail) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                !isShopOpen
                    ? 'El comercio está cerrado. No se puede ver el detalle.'
                    : 'El comercio no tiene canales de atención activos.',
              ),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          context.go('/product/${product.id}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: Icon(Icons.image, color: Colors.grey.shade400),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.image, color: Colors.grey.shade400),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  PriceText(
                    price: product.price,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
