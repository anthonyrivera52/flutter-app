import 'package:flutter/material.dart';
import 'package:flutter_app/config/mock/app_mock.dart'; // Asegúrate que Category y Product están bien definidos
import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_app/domain/entities/category.dart'; // Asegúrate que importas tu clase Category actualizada
import 'package:flutter_app/presentation/provider/home_provider.dart';
import 'package:flutter_app/presentation/widget/common/home_appbar.dart';
import 'package:flutter_app/presentation/widget/common/home_skeleton_loader.dart.dart';
import 'package:flutter_app/presentation/widget/product/product_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Provider para la categoría seleccionada (sin cambios en su definición)
final selectedCategoryProvider = StateProvider<String>((ref) {
  return MockData.allProductsCategoryId; // Valor inicial: "All Products"
});

class HomeTabPageContent extends ConsumerWidget {
  const HomeTabPageContent({super.key});

  Widget _buildHomeSkeleton() {
    return const HomeSkeletonLoader();
  }

  // NUEVO: Helper para encontrar una categoría por ID recursivamente en la estructura anidada
  Category? _findCategoryRecursive(List<Category> catList, String id) {
    for (var cat in catList) {
      if (cat.id == id) return cat;
      if (cat.subcategories != null) {
        var foundInSub = _findCategoryRecursive(cat.subcategories!, id);
        if (foundInSub != null) return foundInSub;
      }
    }
    return null;
  }

  // NUEVO: Helper para obtener todos los IDs de categoría aplicables (categoría raíz + todos sus descendientes)
  Set<String> _getApplicableCategoryIds(String rootCategoryId, List<Category> allMockCategoriesRoot) {
    final Set<String> ids = {};

    // Encuentra el objeto de la categoría raíz primero
    final rootCatObject = _findCategoryRecursive(allMockCategoriesRoot, rootCategoryId);

    // Función recursiva interna para coleccionar IDs
    void collectIdsRecursive(Category category) {
      ids.add(category.id);
      category.subcategories?.forEach(collectIdsRecursive);
    }

    if (rootCatObject != null) {
      collectIdsRecursive(rootCatObject); // Colecciona IDs desde esta categoría hacia abajo
    }
    return ids;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);
    final selectedCategoryNotifier = ref.read(selectedCategoryProvider.notifier);

    final mockUser = MockData().mockUser;
    final currentUserDisplayName = mockUser.userMetadata?['display_name'] ?? 'Guest';
    final currentUserAvatarUrl = mockUser.userMetadata?['avatar_url'] as String?;

    // Obtener categorías (ahora potencialmente con subcategorías anidadas)
    final allCategoriesStructure = MockData.mockCategories;

    // MODIFICADO: Encontrar el objeto de la categoría seleccionada (puede ser principal o subcategoría)
    final Category selectedFullCategoryObject = _findCategoryRecursive(allCategoriesStructure, selectedCategoryId) ??
        allCategoriesStructure.firstWhere((cat) => cat.id == MockData.allProductsCategoryId); // Fallback a "All Products"

    final discountedProducts = MockData.mockProducts.where((p) => p.discountedPrice != null).toList();

    // MODIFICADO: Lógica para obtener productos para la cuadrícula principal
    List<Product> mainProductsGrid;
    if (selectedCategoryId == MockData.allProductsCategoryId) {
      mainProductsGrid = MockData.mockProducts;
    } else {
      // This is the key part that should work with nested categories.
      // It correctly gets all descendant IDs of the selected category.
      final applicableIds = _getApplicableCategoryIds(selectedCategoryId, allCategoriesStructure);
      mainProductsGrid = MockData.mockProducts
          .where((product) => applicableIds.contains(product.categoryId))
          .toList();
    }

    final displayedMainProducts = mainProductsGrid.take(4).toList();
    final showDisplayTextForNoProducts = mainProductsGrid.isEmpty && selectedCategoryId != MockData.allProductsCategoryId;


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // ... (AppBar sin cambios significativos, solo si quieres mostrar el nombre de la categoría seleccionada aquí)
         backgroundColor: Colors.white,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning,',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                Text(
                  currentUserDisplayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const Spacer(
              flex: 1,
            ),
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(currentUserAvatarUrl ?? 'https://placehold.co/100x100/CCCCCC/000000?text=S'),
              onBackgroundImageError: (exception, stackTrace) {
                // Manejo de errores de imagen del avatar
              },
            ),
          ],
        ),
        actions: const [
          HomeAppBarActions(),
          SizedBox(width: 10),
        ],
      ),
      body: homeState.isLoading
          ? _buildHomeSkeleton()
          : homeState.errorMessage != null
              ? Center(child: Text('Error: ${homeState.errorMessage!}'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ... (Sección de ubicación y búsqueda sin cambios)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 18, color: Colors.green),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Oststrasse 123, 10245, Berlin',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down, size: 18),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Search something...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: const Icon(Icons.tune),
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sección de Categorías Principales
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Categories',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () {
                                context.goNamed(
                                  'product_list',
                                  pathParameters: {
                                    'categoryId': selectedCategoryId,
                                    'categoryName': selectedFullCategoryObject.name, // MODIFICADO: nombre de la categoría/subcategoría actual
                                  },
                                );
                              },
                              // MODIFICADO: Condición para 'View More'
                              child: (selectedCategoryId != MockData.allProductsCategoryId && mainProductsGrid.isEmpty)
                                     ? const SizedBox.shrink()
                                     : const Text('View More'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: allCategoriesStructure.length, // Show all top-level categories
                          itemBuilder: (context, index) {
                            final category = allCategoriesStructure[index];
                            // A category is "selected" if its ID matches, OR
                            // if a subcategory of it is currently selected.
                            // To handle deep nesting, we can check if the selected category's
                            // applicable IDs contain the current category's ID, or if the
                            // current category's applicable IDs contain the selected category's ID.
                            // However, for the main list, a simpler check is often preferred:
                            // Is this the selected category, or is this the *direct parent* of the selected category?
                            // Or, even better, is the currently selected category (or one of its ancestors) *this* category?
                            
                            // Let's refine `isSelected` for the main category bar:
                            // A category in the *top bar* is selected if `selectedCategoryId` is *itself*,
                            // or if `selectedCategoryId` is one of its *descendants*.
                            final Set<String> currentCategoryAndDescendantIds = _getApplicableCategoryIds(category.id, allCategoriesStructure);
                            final bool isSelected = currentCategoryAndDescendantIds.contains(selectedCategoryId);


                            return GestureDetector(
                              onTap: () {
                                selectedCategoryNotifier.state = category.id;
                              },
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundColor: isSelected ? Colors.white : Colors.grey[300],
                                      backgroundImage: NetworkImage(category.imageUrl),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      category.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected ? Colors.white : Colors.grey[700],
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // const SizedBox(height: 24), // Espacio antes de la lista de subcategorías

                      // NUEVO: Sección para mostrar Subcategorías
                      if (selectedCategoryId != MockData.allProductsCategoryId) // Only show subcategories if not "All Products"
                        // Check if the currently selected category has subcategories, OR if its parent has subcategories
                        // (which means we might need to show siblings of the selected subcategory).
                        // Simpler: just show subcategories of the *currently selected category object*, if it has any.
                        if (selectedFullCategoryObject.subcategories != null && selectedFullCategoryObject.subcategories!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0), // Añade espacio arriba
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'Subcategories in ${selectedFullCategoryObject.name}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 90,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    itemCount: selectedFullCategoryObject.subcategories!.length,
                                    itemBuilder: (context, index) {
                                      final subCategory = selectedFullCategoryObject.subcategories![index];
                                      final isSubSelected = selectedCategoryId == subCategory.id;
                                      return GestureDetector(
                                        onTap: () {
                                          selectedCategoryNotifier.state = subCategory.id; // Selecciona la subcategoría
                                        },
                                        child: Container(
                                          width: 80,
                                          margin: const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            color: isSubSelected ? Theme.of(context).primaryColor.withOpacity(0.8) : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              CircleAvatar(
                                                radius: 25,
                                                backgroundColor: isSubSelected ? Colors.white : Colors.grey[300],
                                                backgroundImage: NetworkImage(subCategory.imageUrl),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                subCategory.name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isSubSelected ? Colors.white : Colors.grey[700],
                                                  fontWeight: isSubSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                      const SizedBox(height: 24), // Espacio después de la lista de subcategorías (si existe)


                      // Sección Principal de Productos Filtrados
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          // MODIFICADO: Usa el nombre del objeto de categoría/subcategoría completamente resuelto
                          selectedFullCategoryObject.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // MODIFICADO: Condición para mostrar "No hay productos"
                      showDisplayTextForNoProducts
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text('No products found for this category.'),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16.0,
                                mainAxisSpacing: 16.0,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: displayedMainProducts.length,
                              itemBuilder: (context, index) {
                                final product = displayedMainProducts[index];
                                return ProductCard(
                                  product: product,
                                  onTap: () {
                                    context.go('/product/${product.id}');
                                  },
                                  onAddToCart: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${product.name} agregado al carrito'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                      const SizedBox(height: 24),

                      // ... (Sección de Productos con Descuento sin cambios necesarios para la lógica de subcategorías)
                       Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Discounted',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () {
                                context.goNamed(
                                  'product_list',
                                  pathParameters: {
                                    'categoryId': MockData.discountedProductsCategoryId, // Este ID es especial y no parte de la jerarquía normal
                                    'categoryName': 'Discounted Products',
                                  },
                                );
                              },
                              child: const Text('See all'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: discountedProducts.length,
                          itemBuilder: (context, index) {
                            final product = discountedProducts[index];
                            return ProductCard(
                              product: product,
                              onTap: () {
                                context.go('/product/${product.id}');
                              },
                              onAddToCart: () {
                                // ref.read(cartProvider.notifier).addItemToCart(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} agregado al carrito'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Banner "Invite friends"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            image: const DecorationImage(
                              image: NetworkImage('https://placehold.co/400x120/A7D9B1/000000?text=Invite+friends'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 45),
                    ],
                  ),
                ),
    );
  }
}