import 'package:flutter/material.dart';
import 'package:flutter_app/config/constants/category_constants.dart';
import 'package:flutter_app/domain/entities/category.dart';
import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_app/domain/entities/shop.dart';
import 'package:flutter_app/presentation/pages/dashboard/home/shop_logo_card.dart';
import 'package:flutter_app/presentation/pages/dashboard/home/home_viewmodel.dart';
import 'package:flutter_app/presentation/provider/home_provider.dart';
import 'package:flutter_app/presentation/widget/common/home_appbar.dart';
import 'package:flutter_app/presentation/widget/common/home_skeleton_loader.dart';
import 'package:flutter_app/presentation/widget/common/search_input_widget.dart';
import 'package:flutter_app/presentation/widget/product/product_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final selectedCategoryProvider = StateProvider<String>((ref) {
  return CategoryConstants.allProductsCategoryId;
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
    return Category(
      id: id,
      name: _getCategoryName(id),
    );
  }).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
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

    if (homeState.isLoading) {
      return const HomeSkeletonLoader();
    }

    if (homeState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(homeState.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: homeNotifier.refreshNearbyShops,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
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
      body: RefreshIndicator(
        onRefresh: homeNotifier.refreshNearbyShops,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLocationBlock(context, homeState.locationMessage),
            const SizedBox(height: 16),
            _buildNearbyShopsCarousel(
              nearbyShops: homeState.nearbyShops,
              selectedShop: selectedShop,
              onShopTap: homeNotifier.selectShop,
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
                  ref.read(selectedCategoryProvider.notifier).state = categoryId;
                },
              ),
              const SizedBox(height: 16),
              _ProductsSection(products: products),
            ],
          ],
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
      final categoryMatch = selectedCategoryId == CategoryConstants.allProductsCategoryId
          ? true
          : product.categoryId == selectedCategoryId;

      if (!categoryMatch) return false;
      if (normalizedSearch.isEmpty) return true;

      return product.name.toLowerCase().contains(normalizedSearch) ||
          product.description.toLowerCase().contains(normalizedSearch);
    }).toList();
  }
}

Widget _buildLocationBlock(BuildContext context, String? locationMessage) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.my_location, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            locationMessage ?? 'Buscando comercios de tu zona...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}

Widget _buildNearbyShopsCarousel({
  required List<ShopDistance> nearbyShops,
  required Shop? selectedShop,
  required ValueChanged<Shop> onShopTap,
}) {
  if (nearbyShops.isEmpty) {
    return const Text('No hay comercios cercanos en este momento.');
  }

  return SizedBox(
    height: 215,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: nearbyShops.length,
      itemBuilder: (context, index) {
        final shopDistance = nearbyShops[index];
        return ShopLogoCard(
          shop: shopDistance.shop,
          distanceKm: shopDistance.distanceKm,
          isActive: selectedShop?.id == shopDistance.shop.id,
          onTap: () => onShopTap(shopDistance.shop),
        );
      },
    ),
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
          Text(shop.schedule, style: Theme.of(context).textTheme.bodySmall),
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
