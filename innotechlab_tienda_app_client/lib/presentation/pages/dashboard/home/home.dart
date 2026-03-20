import 'package:flutter/material.dart';
import 'package:flutter_app/config/constants/category_constants.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/features/products/domain/models/product_entity.dart';
import 'package:flutter_app/features/products/presentation/viewmodels/home_viewmodel.dart';
import 'package:flutter_app/presentation/provider/shops_polling_provider.dart';
import 'package:flutter_app/presentation/widget/common/full_map_widget.dart';
import 'package:flutter_app/presentation/widget/common/shop_panel_widget.dart';
import 'package:flutter_app/presentation/widget/common/responsive_widgets.dart';
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
    final pollingState = ref.watch(shopsPollingProvider);
    final homeState = ref.watch(homeProvider);
    final homeNotifier = ref.read(homeProvider.notifier);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);

    if (pollingState.isLoading && pollingState.shops.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedShop = homeState.selectedShop;
    final products = homeState.products;
    final categories = _getCategories(products);

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
          categories: categories,
        ),
        tablet: (_) => _buildExpandedLayout(
          pollingState: pollingState,
          homeState: homeState,
          homeNotifier: homeNotifier,
          selectedCategoryId: selectedCategoryId,
          selectedShop: selectedShop,
          products: products,
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
    required List<String> categories,
  }) {
    return Stack(
      children: [
        SizedBox.expand(
          child: FullMapWidget(
            nearbyShops: pollingState.shops,
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
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _LocationBanner(
                locationMessage: homeState.locationMessage,
                errorMessage: pollingState.error ?? homeState.errorMessage,
                onRefresh: () {
                  ref.read(shopsPollingProvider.notifier).startPolling();
                },
              ),
            ),
          ),
        ),
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
                ref.read(selectedCategoryProvider.notifier).state = category;
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
        if (pollingState.isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandedLayout({
    required ShopsPollingState pollingState,
    required HomeState homeState,
    required HomeNotifier homeNotifier,
    required String selectedCategoryId,
    required dynamic selectedShop,
    required List<Product> products,
    required List<String> categories,
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
                nearbyShops: pollingState.shops,
                userLatitude: homeState.userLatitude ?? 0,
                userLongitude: homeState.userLongitude ?? 0,
                selectedShop: selectedShop,
                onShopSelected: (shop) {
                  ref.read(selectedCategoryProvider.notifier).state =
                      CategoryConstants.allProductsCategoryId;
                  homeNotifier.selectShop(shop);
                },
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: SafeArea(
                  child: _LocationBanner(
                    locationMessage: homeState.locationMessage,
                    errorMessage: pollingState.error ?? homeState.errorMessage,
                    onRefresh: () {
                      ref.read(shopsPollingProvider.notifier).startPolling();
                    },
                  ),
                ),
              ),
              if (pollingState.isLoading && pollingState.shops.isEmpty)
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
                categories: categories,
                selectedCategory: selectedCategoryId,
                onCategorySelected: (category) {
                  ref.read(selectedCategoryProvider.notifier).state = category;
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

class _FixedShopPanel extends StatelessWidget {
  final dynamic shop;
  final List<Product> products;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onClose;
  final List<dynamic> shopHours;
  final bool isLoadingHours;

  const _FixedShopPanel({
    required this.shop,
    required this.products,
    required this.categories,
    required this.selectedCategory,
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
        if (categories.length > 1)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;
                return FilterChip(
                  label: Text(
                    category == 'all' ? 'Todos' : category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => onCategorySelected(category),
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
                    return _ProductCard(product: products[index]);
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

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                Text(
                  '\$${product.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
