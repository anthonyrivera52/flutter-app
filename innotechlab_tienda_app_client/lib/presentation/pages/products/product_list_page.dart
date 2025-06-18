// product_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/config/mock/app_mock.dart'; // Asumiendo que MockData está aquí
import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_app/domain/entities/category.dart';
import 'package:flutter_app/presentation/widget/common/search_input_widget.dart';
import 'package:flutter_app/presentation/widget/product/product_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Helper functions (retained for this file as they are used here)
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

Set<String> _getApplicableCategoryIds(String rootCategoryId, List<Category> allMockCategoriesRoot) {
  final Set<String> ids = {};
  final rootCatObject = _findCategoryRecursive(allMockCategoriesRoot, rootCategoryId);

  if (rootCatObject != null) {
    ids.add(rootCatObject.id);
    if (rootCatObject.subcategories != null && rootCatObject.subcategories!.isNotEmpty) {
      void collectIdsRecursive(Category category) {
        category.subcategories?.forEach((sub) {
          ids.add(sub.id);
          collectIdsRecursive(sub);
        });
      }
      collectIdsRecursive(rootCatObject);
    }
  } else {
    // If the root category object itself isn't found (e.g., for 'All Products' or 'Discounted'),
    // we should still add the rootCategoryId to the set to filter correctly.
    // This case also handles direct category IDs without subcategories.
    ids.add(rootCategoryId);
  }
  return ids;
}


class ProductListPage extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;

  const ProductListPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  late ValueNotifier<String> _searchTermNotifier;
  // _isSearchMode is not strictly needed if SearchInputWidget is always a TextField here
  // and its internal state handles the input. It's kept for consistency with HomeTabPageContent.
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _searchTermNotifier = ValueNotifier<String>('');
    _searchTermNotifier.addListener(_onSearchTermChanged);
    // Initialize search mode if a search term was passed or if we anticipate search.
    // For ProductListPage, we assume the search input is always "active" (a TextField).
    _isSearchMode = true;
  }

  @override
  void dispose() {
    _searchTermNotifier.removeListener(_onSearchTermChanged);
    _searchTermNotifier.dispose();
    super.dispose();
  }

  void _onSearchTermChanged() {
    // The search term changing directly updates the UI in build method.
    // No need to force _isSearchMode true here if it's always considered active.
    setState(() {}); // Rebuilds the widget when the search term changes
  }

  void _onSearchModeChanged(bool isSearching) {
    // This method might be less critical if SearchInputWidget is always a TextField here,
    // but keep it for consistency or if you decide to toggle its visibility.
    setState(() {
      _isSearchMode = isSearching;
      if (!isSearching) {
        _searchTermNotifier.value = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the list of products based on category and then filter by search term.
    List<Product> productsToFilter; // Products before search filter
    if (widget.categoryId == MockData.allProductsCategoryId) {
      productsToFilter = MockData.mockProducts;
    } else if (widget.categoryId == MockData.discountedProductsCategoryId) {
      productsToFilter = MockData.mockProducts.where((p) => p.discountedPrice != null).toList();
    } else {
      final allCategoriesStructure = MockData.mockCategories;
      final applicableIds = _getApplicableCategoryIds(widget.categoryId, allCategoriesStructure);
      productsToFilter = MockData.mockProducts
          .where((product) => applicableIds.contains(product.categoryId))
          .toList();
    }

    // Apply search filter
    final String currentSearchTerm = _searchTermNotifier.value.toLowerCase();
    List<Product> productsToDisplay = productsToFilter; // Start with filtered category products

    if (currentSearchTerm.isNotEmpty) {
      productsToDisplay = productsToFilter
          .where((product) =>
              product.name.toLowerCase().contains(currentSearchTerm) ||
              (product.description?.toLowerCase().contains(currentSearchTerm) ?? false)) // Handle null description
          .toList();
    }

    // Determine the message to display if no products are found
    String noProductsMessage = '';
    bool showNoProductsMessage = false;

    if (productsToDisplay.isEmpty) {
      if (currentSearchTerm.isNotEmpty) {
        noProductsMessage = 'No products found matching "$currentSearchTerm" in "${widget.categoryName}".';
      } else {
        noProductsMessage = 'No products available in "${widget.categoryName}".';
      }
      showNoProductsMessage = true;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          widget.categoryName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        // A back button is automatically provided by AppBar when pushed onto the stack.
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchInputWidget(
              searchTermNotifier: _searchTermNotifier,
              onSearchModeChanged: _onSearchModeChanged,
              initialIsSearching: true, // Always show as a TextField
              isShowCancelButton: false, // No cancel button needed as it's always a search field
            ),
          ),

          // Lógica para mostrar mensajes o el GridView
          if (showNoProductsMessage)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  noProductsMessage,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                // Use primary: false and a SingleChildScrollView parent if this GridView
                // needs to scroll with other content, otherwise use its own ScrollPhysics.
                // Since it's in an Expanded, it will handle its own scrolling.
                shrinkWrap: false, // Set to false if it's in an Expanded widget and fills space
                physics: const AlwaysScrollableScrollPhysics(), // Allows scrolling even if content is small
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.7,
                ),
                itemCount: productsToDisplay.length,
                itemBuilder: (context, index) {
                  final product = productsToDisplay[index];
                  return ProductCard(
                    product: product,
                    onTap: () {
                      // FIX: Use context.push() instead of context.go()
                      // This keeps ProductListPage on the navigation stack.
                      context.push('/product/${product.id}');
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// Helper extension for .firstWhereOrNull
// (You might have this globally, but included here for completeness of the file)
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}