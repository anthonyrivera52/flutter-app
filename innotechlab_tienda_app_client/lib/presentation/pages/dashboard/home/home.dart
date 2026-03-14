import 'package:flutter/material.dart';
import 'package:flutter_app/config/constants/category_constants.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/domain/entities/category.dart';
import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_app/domain/entities/shop.dart';
import 'package:flutter_app/presentation/pages/dashboard/home/home_viewmodel.dart';
import 'package:flutter_app/presentation/provider/home_provider.dart';
import 'package:flutter_app/presentation/provider/shop_status_provider.dart';
import 'package:flutter_app/presentation/widget/common/home_appbar.dart';
import 'package:flutter_app/presentation/widget/common/search_input_widget.dart';
import 'package:flutter_app/presentation/widget/common/shop_map_widget.dart';
import 'package:flutter_app/presentation/widget/product/product_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final selectedCategoryProvider = StateProvider<String>((ref) {
  return CategoryConstants.allProductsCategoryId;
});

enum ShopViewMode { map, list }

final shopViewModeProvider = StateProvider<ShopViewMode>((ref) {
  return ShopViewMode.map;
});

/// Provider para obtener las categorías únicas de los productos cargados
/// Se deriva automáticamente de los productos del comercio seleccionado
final categoriesFromProductsProvider = Provider<List<Category>>((ref) {
  final homeState = ref.watch(homeProvider);
  final products = homeState.products;

  if (products.isEmpty) {
    // Retornar categorías por defecto si no hay productos
    return _getDefaultCategories();
  }

  // Obtener categorías únicas de los productos
  final uniqueCategoryIds = products.map((p) => p.categoryId).toSet();

  // Mapear los categoryId a Category con nombres legibles
  return uniqueCategoryIds.map((id) {
    return Category(id: id, name: _getCategoryName(id));
  }).toList()..sort((a, b) => a.name.compareTo(b.name));
});

/// Obtener nombre legible de categoría desde el ID
String _getCategoryName(String categoryId) {
  // Mapear IDs de categorías a nombres legibles
  final categoryNames = {
    CategoryConstants.allProductsCategoryId: 'Todos',
    'vegetables': 'Verduras',
    'vegetables_category_id': 'Verduras',
    'fruits': 'Frutas',
    'fruits_category_id': 'Frutas',
    'meat': 'Carnes',
    'meat_category_id': 'Carnes',
    'drinks': 'Bebidas',
    'drinks_category_id': 'Bebidas',
    'dairy': 'Lácteos',
    'dairy_category_id': 'Lácteos',
    'bakery': 'Panadería',
    'bakery_category_id': 'Panadería',
  };

  return categoryNames[categoryId] ?? _formatCategoryId(categoryId);
}

/// Convertir ID de categoría a formato legible (ej: "vegetables_category_id" -> "Vegetables")
String _formatCategoryId(String categoryId) {
  // Quitar sufijos comunes
  String formatted = categoryId
      .replaceAll('_category_id', '')
      .replaceAll('_subcategory_id', '');

  // Convertir a título (primera letra mayúscula)
  if (formatted.isEmpty) return categoryId;

  return formatted[0].toUpperCase() + formatted.substring(1);
}

/// Categorías por defecto
List<Category> _getDefaultCategories() {
  return [
    Category(id: CategoryConstants.allProductsCategoryId, name: 'Todos'),
    Category(id: 'vegetables', name: 'Verduras'),
    Category(id: 'fruits', name: 'Frutas'),
    Category(id: 'meat', name: 'Carnes'),
    Category(id: 'drinks', name: 'Bebidas'),
    Category(id: 'dairy', name: 'Lácteos'),
    Category(id: 'bakery', name: 'Panadería'),
  ];
}

class HomeTabPageContent extends ConsumerStatefulWidget {
  const HomeTabPageContent({super.key});

  @override
  ConsumerState<HomeTabPageContent> createState() => _HomeTabPageContentState();
}

class _HomeTabPageContentState extends ConsumerState<HomeTabPageContent> {
  late final ValueNotifier<String> _searchTermNotifier;

  @override
  void initState() {
    super.initState();
    _searchTermNotifier = ValueNotifier<String>('');
  }

  @override
  void dispose() {
    _searchTermNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final homeNotifier = ref.read(homeProvider.notifier);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);
    final categories = ref.watch(categoriesFromProductsProvider);

    if (homeState.isLoading && homeState.nearbyShops.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedShop = homeState.selectedShop;
    final products = _filterProducts(
      products: homeState.products,
      selectedCategoryId: selectedCategoryId,
      searchTerm: _searchTermNotifier.value,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Tiendas cercanas'),
        actions: const [HomeAppBarActions(), SizedBox(width: 8)],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: homeNotifier.refreshNearbyShops,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildLocationBlock(
                  context,
                  homeState.locationMessage,
                  homeState.errorMessage,
                ),
                const SizedBox(height: 16),
                _buildShopsView(context, homeState),
                const SizedBox(height: 12),
                _buildShopListHint(
                  context,
                  homeState.nearbyShops.length,
                  homeState.selectedShop,
                ),
                const SizedBox(height: 20),
                if (selectedShop == null)
                  const _EmptyCommerceSelection()
                else ...[
                  _SelectedCommerceHeader(
                    shop: selectedShop,
                    onChangeShop: () {
                      ref.read(selectedCategoryProvider.notifier).state =
                          CategoryConstants.allProductsCategoryId;
                      ref.read(homeProvider.notifier).clearSelectedShop();
                    },
                  ),
                  const SizedBox(height: 16),
                  SearchInputWidget(
                    searchTermNotifier: _searchTermNotifier,
                    initialIsSearching: true,
                    isShowCancelButton: false,
                    onSearchModeChanged: (_) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  _CategoriesFilter(
                    categories: categories,
                    selectedCategoryId: selectedCategoryId,
                    onCategorySelected: (categoryId) {
                      ref.read(selectedCategoryProvider.notifier).state =
                          categoryId;
                    },
                  ),
                  const SizedBox(height: 16),
                  _ProductsSection(products: products),
                ],
              ],
            ),
          ),
          if (homeState.isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildShopsList(HomeState homeState, HomeNotifier homeNotifier) {
    if (homeState.nearbyShops.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('No hay comercios cercanos')),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: homeState.nearbyShops.length,
        itemBuilder: (context, index) {
          final shopDistance = homeState.nearbyShops[index];
          final shop = shopDistance.shop;
          final isSelected = homeState.selectedShop?.id == shop.id;

          return _ShopCard(
            shop: shop,
            distanceKm: shopDistance.distanceKm,
            isSelected: isSelected,
            onTap: () => homeNotifier.selectShop(shop),
          );
        },
      ),
    );
  }

  Widget _buildShopsView(BuildContext context, HomeState homeState) {
    final viewMode = ref.watch(shopViewModeProvider);
    final homeNotifier = ref.read(homeProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${homeState.nearbyShops.length} comercios cercanos',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SegmentedButton<ShopViewMode>(
              segments: const [
                ButtonSegment(
                  value: ShopViewMode.map,
                  icon: Icon(Icons.map_outlined, size: 18),
                ),
                ButtonSegment(
                  value: ShopViewMode.list,
                  icon: Icon(Icons.list, size: 18),
                ),
              ],
              selected: {viewMode},
              onSelectionChanged: (selection) {
                ref.read(shopViewModeProvider.notifier).state = selection.first;
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (viewMode == ShopViewMode.map)
          SizedBox(
            height: 200,
            child: ShopMapWidget(
              nearbyShops: homeState.nearbyShops,
              userLatitude: homeState.userLatitude ?? 0,
              userLongitude: homeState.userLongitude ?? 0,
              selectedShop: homeState.selectedShop,
              onShopTap: homeNotifier.selectShop,
            ),
          )
        else
          _buildShopsList(homeState, homeNotifier),
      ],
    );
  }
}

Widget _buildLoadingOverlay() {
  return Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: 0.15),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
    ),
  );
}

List<Product> _filterProducts({
  required List<Product> products,
  required String selectedCategoryId,
  required String searchTerm,
}) {
  final normalizedSearch = searchTerm.trim().toLowerCase();

  return products.where((product) {
    final categoryMatch =
        selectedCategoryId == CategoryConstants.allProductsCategoryId
        ? true
        : product.categoryId == selectedCategoryId;

    if (!categoryMatch) return false;
    if (normalizedSearch.isEmpty) return true;

    return product.name.toLowerCase().contains(normalizedSearch) ||
        product.description.toLowerCase().contains(normalizedSearch);
  }).toList();
}

Widget _buildLocationBlock(
  BuildContext context,
  String? locationMessage,
  String? errorMessage,
) {
  final hasError = errorMessage != null && locationMessage == null;

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: hasError ? Colors.red.shade50 : Colors.green.shade50,
      borderRadius: BorderRadius.circular(12),
      border: hasError ? Border.all(color: Colors.red.shade200) : null,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          hasError ? Icons.location_off : Icons.my_location,
          color: hasError ? Colors.red : Colors.green,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasError
                ? errorMessage
                : (locationMessage ?? 'Buscando comercios de tu zona...'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: hasError ? Colors.red.shade800 : null,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildShopListHint(
  BuildContext context,
  int shopsCount,
  Shop? selectedShop,
) {
  if (shopsCount <= 1 || selectedShop != null) {
    return const SizedBox.shrink();
  }

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.touch_app, size: 16, color: Colors.grey.shade600),
      const SizedBox(width: 6),
      Text(
        'Toca una sucursal en el mapa para ver su catálogo',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
    ],
  );
}

class _EmptyCommerceSelection extends StatelessWidget {
  const _EmptyCommerceSelection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('Selecciona un comercio cercano para ver su catalogo.'),
    );
  }
}

class _SelectedCommerceHeader extends StatelessWidget {
  final Shop shop;
  final VoidCallback onChangeShop;

  const _SelectedCommerceHeader({
    required this.shop,
    required this.onChangeShop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shop.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(shop.address, style: Theme.of(context).textTheme.bodySmall),
          if (shop.schedule != null && shop.schedule!.isNotEmpty)
            Text(shop.schedule!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onChangeShop,
              child: const Text('Cambiar comercio'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesFilter extends StatelessWidget {
  final List<Category> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  const _CategoriesFilter({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    // Asegurar que "Todos" siempre esté primero
    final sortedCategories = List<Category>.from(categories);
    sortedCategories.sort((a, b) {
      if (a.id == CategoryConstants.allProductsCategoryId) return -1;
      if (b.id == CategoryConstants.allProductsCategoryId) return 1;
      return a.name.compareTo(b.name);
    });

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final category in sortedCategories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category.name),
                selected: selectedCategoryId == category.id,
                onSelected: (_) => onCategorySelected(category.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductsSection extends StatelessWidget {
  final List<Product> products;

  const _ProductsSection({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 30),
        child: Center(
          child: Text('No hay productos para este comercio o filtro.'),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () => context.go('/product/${product.id}'),
        );
      },
    );
  }
}

class _ShopCard extends ConsumerWidget {
  final Shop shop;
  final double distanceKm;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShopCard({
    required this.shop,
    required this.distanceKm,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopStatus = ref.watch(shopStatusProvider(shop.id));

    Color borderColor;
    Color? cardColor;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (shopStatus.status) {
      case ShopStatus.active:
        borderColor = AppColors.primaryColor;
        cardColor = Colors.white;
        statusColor = Colors.green;
        statusText = 'Abierto';
        statusIcon = Icons.check_circle;
        break;
      case ShopStatus.waiting:
        borderColor = Colors.orange;
        cardColor = Colors.orange.shade50;
        statusColor = Colors.orange;
        statusText = 'Alta demanda';
        statusIcon = Icons.warning_amber_rounded;
        break;
      case ShopStatus.inactive:
        borderColor = Colors.red.shade300;
        cardColor = Colors.red.shade50;
        statusColor = Colors.red;
        statusText = 'No disponible';
        statusIcon = Icons.cancel;
        break;
      case ShopStatus.closed:
        borderColor = Colors.grey.shade400;
        cardColor = Colors.grey.shade100;
        statusColor = Colors.grey.shade600;
        statusText = shopStatus.nextOpenTime != null
            ? 'Cerrado - Abre ${shopStatus.nextOpenTime}'
            : 'Cerrado';
        statusIcon = Icons.lock_clock;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.05)
              : cardColor,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: shop.logoUrl.isNotEmpty
                              ? Image.network(
                                  shop.logoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.store,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(Icons.store, color: Colors.grey),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 2),
                            Text(
                              statusText.length > 10
                                  ? '${statusText.substring(0, 10)}...'
                                  : statusText,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shop.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shop.address,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${distanceKm.toStringAsFixed(1)} km',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (shopStatus.status == ShopStatus.closed ||
                shopStatus.status == ShopStatus.inactive)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock, color: Colors.white, size: 32),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
