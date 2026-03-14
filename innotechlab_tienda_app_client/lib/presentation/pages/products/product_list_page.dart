// product_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_app/domain/entities/category.dart';
import 'package:flutter_app/presentation/widget/common/search_input_widget.dart';
import 'package:flutter_app/presentation/widget/product/product_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchTermNotifier = ValueNotifier<String>('');
    _searchTermNotifier.addListener(_onSearchTermChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchTermNotifier.removeListener(_onSearchTermChanged);
    _searchTermNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      final productsResponse = await supabase
          .from('products')
          .select()
          .eq('is_active', true)
          .eq('is_available', true);

      final categoriesResponse = await supabase
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('name');

      final products = (productsResponse as List)
          .map(
            (p) => Product(
              id: p['id'] as String,
              name: p['name'] as String,
              description: p['description'] as String,
              price: (p['price'] as num).toDouble(),
              imageUrl: p['image_url'] as String,
              categoryId: p['category_id'] as String,
              unit: p['unit'] as String,
              discountedPrice: p['discounted_price'] != null
                  ? (p['discounted_price'] as num).toDouble()
                  : null,
            ),
          )
          .toList();

      final categories = (categoriesResponse as List)
          .map(
            (c) => Category(
              id: c['id'] as String,
              name: c['name'] as String,
              imageUrl: c['image_url'] as String?,
              parentId: c['parent_id'] as String?,
              subcategories: [],
            ),
          )
          .toList();

      setState(() {
        _products = products;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar los productos: ${e.toString()}';
      });
    }
  }

  void _onSearchTermChanged() {
    setState(() {});
  }

  void _onSearchModeChanged(bool isSearching) {
    setState(() {
      if (!isSearching) {
        _searchTermNotifier.value = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Text(
            widget.categoryName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Text(
            widget.categoryName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    List<Product> productsToFilter;
    if (widget.categoryId == 'all') {
      productsToFilter = _products;
    } else if (widget.categoryId == 'discounted') {
      productsToFilter = _products
          .where((p) => p.discountedPrice != null)
          .toList();
    } else {
      final applicableIds = _getApplicableCategoryIds(
        widget.categoryId,
        _categories,
      );
      productsToFilter = _products
          .where((product) => applicableIds.contains(product.categoryId))
          .toList();
    }

    final String currentSearchTerm = _searchTermNotifier.value.toLowerCase();
    List<Product> productsToDisplay = productsToFilter;

    if (currentSearchTerm.isNotEmpty) {
      productsToDisplay = productsToFilter
          .where(
            (product) =>
                product.name.toLowerCase().contains(currentSearchTerm) ||
                product.description.toLowerCase().contains(currentSearchTerm),
          )
          .toList();
    }

    String noProductsMessage = '';
    bool showNoProductsMessage = false;

    if (productsToDisplay.isEmpty) {
      if (currentSearchTerm.isNotEmpty) {
        noProductsMessage =
            'No products found matching "$currentSearchTerm" in "${widget.categoryName}".';
      } else {
        noProductsMessage =
            'No products available in "${widget.categoryName}".';
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
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchInputWidget(
              searchTermNotifier: _searchTermNotifier,
              onSearchModeChanged: _onSearchModeChanged,
              initialIsSearching: true,
              isShowCancelButton: false,
            ),
          ),
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
                shrinkWrap: false,
                physics: const AlwaysScrollableScrollPhysics(),
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

Set<String> _getApplicableCategoryIds(
  String rootCategoryId,
  List<Category> allCategoriesRoot,
) {
  final Set<String> ids = {};
  final rootCatObject = _findCategoryRecursive(
    allCategoriesRoot,
    rootCategoryId,
  );

  if (rootCatObject != null) {
    ids.add(rootCatObject.id);
    if (rootCatObject.subcategories != null &&
        rootCatObject.subcategories!.isNotEmpty) {
      void collectIdsRecursive(Category category) {
        category.subcategories?.forEach((sub) {
          ids.add(sub.id);
          collectIdsRecursive(sub);
        });
      }

      collectIdsRecursive(rootCatObject);
    }
  } else {
    ids.add(rootCategoryId);
  }
  return ids;
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
