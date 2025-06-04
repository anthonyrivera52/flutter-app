import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Import for SchedulerBinding
import 'package:flutter_app/config/mock/app_mock.dart';
import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_app/domain/entities/category.dart';
import 'package:flutter_app/presentation/provider/home_provider.dart';
import 'package:flutter_app/presentation/widget/common/home_appbar.dart';
import 'package:flutter_app/presentation/widget/common/home_skeleton_loader.dart.dart';
import 'package:flutter_app/presentation/widget/common/search_input_widget.dart';
import 'package:flutter_app/presentation/widget/product/product_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// --- Riverpod Providers (Se mantienen sin cambios) ---
final selectedCategoryProvider = StateProvider<String>((ref) {
  return MockData.allProductsCategoryId;
});

final currentParentCategoryProvider = StateProvider<Category?>((ref) {
  return null;
});

// --- Helper Functions (Modificaciones y adiciones) ---
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

Category? _findParentCategory(List<Category> allCategories, String subcategoryId) {
  for (var category in allCategories) {
    if (category.subcategories != null) {
      if (category.subcategories!.any((sub) => sub.id == subcategoryId)) {
        return category;
      }
      final foundInSub = _findParentCategory(category.subcategories!, subcategoryId);
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
    final Category? catForId = _findCategoryRecursive(allMockCategoriesRoot, rootCategoryId);
    if(catForId !=null) {
        ids.add(catForId.id);
        if (catForId.subcategories != null && catForId.subcategories!.isNotEmpty) {
            void collectIdsRecursive(Category category) {
                category.subcategories?.forEach((sub) {
                ids.add(sub.id);
                collectIdsRecursive(sub);
                });
            }
            collectIdsRecursive(catForId);
        }
    } else {
         ids.add(rootCategoryId);
    }
  }
  return ids;
}

List<Category> _getUniqueSubcategories(List<Category> allRootCategories) {
  final Map<String, Category> uniqueSubcategoriesMap = {};

  void findSubcategoriesRecursive(List<Category> categories) {
    for (var category in categories) {
      if (category.subcategories != null && category.subcategories!.isNotEmpty) {
        for (var subCategory in category.subcategories!) {
          uniqueSubcategoriesMap[subCategory.id] = subCategory;
        }
        findSubcategoriesRecursive(category.subcategories!);
      }
    }
  }

  findSubcategoriesRecursive(allRootCategories);
  List<Category> sortedSubcategories = uniqueSubcategoriesMap.values.toList();
  sortedSubcategories.sort((a, b) => a.name.compareTo(b.name));
  return sortedSubcategories;
}

bool _hasProductsForCategory(String categoryId, List<Product> allProducts, List<Category> allCategories, bool isSearchModeActive) {
  final applicableIds = _getApplicableCategoryIds(categoryId, allCategories);
  return allProducts.any((product) => applicableIds.contains(product.categoryId));
}

String getMessageForNotProduct(String selectedCategoryId, Category selectedFullCategoryObject, Category? currentParentCategory, List<Product> mainProductsGrid, bool isSearchModeActive) {
  // selectedFullCategoryObject is non-nullable.
  if (mainProductsGrid.isNotEmpty && !isSearchModeActive) {
    return 'Showing products for "${selectedFullCategoryObject.name}".';
  }

  if (currentParentCategory != null &&
      currentParentCategory.subcategories != null &&
      currentParentCategory.subcategories!.any((sub) => sub.id == selectedCategoryId)) {
    return 'No products found for the subcategory "${selectedFullCategoryObject.name}".';
  }

  if (selectedCategoryId == MockData.allProductsCategoryId) {
    return 'No products available.';
  }
  // This message applies if the grid is empty for the selected category/subcategory.
  return 'No products found for the category "${selectedFullCategoryObject.name}".';
}

// --- HomeTabPageContent Widget ---
class HomeTabPageContent extends ConsumerStatefulWidget {
  const HomeTabPageContent({super.key});

  @override
  ConsumerState<HomeTabPageContent> createState() => _HomeTabPageContentState();
}

class _HomeTabPageContentState extends ConsumerState<HomeTabPageContent> {
  late ValueNotifier<String> _searchTermNotifier;
  bool _isSearchMode = false; // Instance variable for search mode state
  String? _activelySelectedChipId;
  late ScrollController _chipScrollController; // Added ScrollController
  final Map<String, GlobalKey> _chipKeys = {}; // Map to store GlobalKeys for chips

  @override
  void initState() {
    super.initState();
    _searchTermNotifier = ValueNotifier<String>('');
    _searchTermNotifier.addListener(_onSearchTermChanged);
    _chipScrollController = ScrollController(); // Initialize ScrollController

    // Initialize keys for all categories (including 'All Products')
    // This is important to ensure keys exist before trying to scroll to them.
    _chipKeys['all_products_chip'] = GlobalKey();
    for (var cat in MockData.mockCategories) {
      _chipKeys[cat.id] = GlobalKey();
      if (cat.subcategories != null) {
        for (var sub in cat.subcategories!) {
          _chipKeys[sub.id] = GlobalKey();
        }
      }
    }

    if (_isSearchMode) {
      _activelySelectedChipId = 'all_products_chip';
    }
  }

  @override
  void dispose() {
    _searchTermNotifier.removeListener(_onSearchTermChanged);
    _searchTermNotifier.dispose();
    _chipScrollController.dispose(); // Dispose ScrollController
    super.dispose();
  }

  // Method to scroll to a specific chip
  void _scrollToChip(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      // Use addPostFrameCallback to ensure the widget is laid out before scrolling
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);

        // Calculate the desired scroll offset.
        // This aims to bring the chip into view on the left side, with some padding.
        final double offset = _chipScrollController.offset + position.dx - 16.0; // 16.0 for horizontal padding

        _chipScrollController.animateTo(
          offset.clamp(_chipScrollController.position.minScrollExtent, _chipScrollController.position.maxScrollExtent), // Clamp to prevent overscrolling
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _onSearchTermChanged() {
    if (!mounted) return;
    final term = _searchTermNotifier.value;
    if (!_isSearchMode && term.isNotEmpty) {
      _onSearchModeChanged(true);
    } else if (_isSearchMode && term.isEmpty && _activelySelectedChipId != 'all_products_chip') {
       setState(() {
         _activelySelectedChipId = 'all_products_chip';
         // Scroll to 'All Products' chip when search term is cleared
         _scrollToChip(_chipKeys['all_products_chip']!);
       });
    } else {
      setState(() {});
    }
  }

  void _onSearchModeChanged(bool isSearching) {
    if (!mounted) return;
    setState(() {
      _isSearchMode = isSearching; // Sets instance variable
      if (!isSearching) {
        _searchTermNotifier.value = '';
        _activelySelectedChipId = null;
      } else {
        if (_searchTermNotifier.value.isEmpty) {
            _searchTermNotifier.value = '';
        }
        _activelySelectedChipId = 'all_products_chip';
        // Scroll to 'All Products' chip when entering search mode
        _scrollToChip(_chipKeys['all_products_chip']!);
      }
    });
  }

  Widget _buildHomeSkeleton() {
    return const HomeSkeletonLoader();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);
    final selectedCategoryNotifier = ref.read(selectedCategoryProvider.notifier);
    final currentParentCategory = ref.watch(currentParentCategoryProvider);

    ref.listen<String>(selectedCategoryProvider, (previousId, newId) {
      final allCategoriesStructure = MockData.mockCategories;
      // Ensure selectedFullCategoryObjectOnUpdate is non-null or handle null explicitly
      Category? foundCategory = _findCategoryRecursive(allCategoriesStructure, newId);
      final Category selectedFullCategoryObjectOnUpdate = foundCategory ??
          allCategoriesStructure.firstWhere(
            (cat) => cat.id == MockData.allProductsCategoryId,
            // orElse: () => Category(id: "fallback", name: "All Products", imageUrl: "") // Should not be needed if MockData is correct
          );

      Category? effectiveParentCategory;
      if (newId == MockData.allProductsCategoryId) {
        effectiveParentCategory = null;
      } else {
        if (allCategoriesStructure.any((cat) => cat.id == newId)) {
          effectiveParentCategory = selectedFullCategoryObjectOnUpdate;
        } else {
          effectiveParentCategory = _findParentCategory(allCategoriesStructure, newId);
        }
      }
      if (mounted) {
        ref.read(currentParentCategoryProvider.notifier).state = effectiveParentCategory;
      }
    });

    final mockUser = MockData().mockUser;
    final currentUserDisplayName = mockUser.userMetadata?['display_name'] ?? 'Guest';
    final currentUserAvatarUrl = mockUser.userMetadata?['avatar_url'] as String?;

    final allCategoriesStructure = MockData.mockCategories;
    // Ensure selectedFullCategoryObject is non-null.
    final Category selectedFullCategoryObject = _findCategoryRecursive(allCategoriesStructure, selectedCategoryId) ??
        allCategoriesStructure.firstWhere(
          (cat) => cat.id == MockData.allProductsCategoryId,
        );


    List<Product> allMockProducts = MockData.mockProducts;
    List<Product> mainProductsGrid;
    final String currentSearchTerm = _searchTermNotifier.value;
    final String currentSearchTermLower = currentSearchTerm.toLowerCase();

    final List<Category> uniqueSubcategoriesForChips = _getUniqueSubcategories(allCategoriesStructure);

    // Ensure _chipKeys are updated for dynamically fetched subcategories if any are new
    for (var subcat in uniqueSubcategoriesForChips) {
      if (!_chipKeys.containsKey(subcat.id)) {
        _chipKeys[subcat.id] = GlobalKey();
      }
    }


    if (_isSearchMode) {
      if (currentSearchTermLower.isEmpty) {
        mainProductsGrid = allMockProducts;
      } else {
        Category? subcategoryMatchingSearchTerm = FirstWhereOrNullExtension(uniqueSubcategoriesForChips).firstWhereOrNull(
          (sub) => sub.name.toLowerCase() == currentSearchTermLower,
        );

        if (subcategoryMatchingSearchTerm != null) {
          final applicableIds = _getApplicableCategoryIds(subcategoryMatchingSearchTerm.id, allCategoriesStructure);
          mainProductsGrid = allMockProducts.where((product) => applicableIds.contains(product.categoryId)).toList();
        } else {
          mainProductsGrid = allMockProducts.where((product) {
            final productNameLower = product.name.toLowerCase();
            final productDescriptionLower = product.description?.toLowerCase() ?? '';
            return productNameLower.contains(currentSearchTermLower) ||
                   productDescriptionLower.contains(currentSearchTermLower);
          }).toList();
        }
      }
    } else {
      if (selectedCategoryId == MockData.allProductsCategoryId) {
        mainProductsGrid = allMockProducts;
      } else {
        final applicableIds = _getApplicableCategoryIds(selectedCategoryId, allCategoriesStructure);
        mainProductsGrid = allMockProducts
            .where((product) => applicableIds.contains(product.categoryId))
            .toList();
      }
      if (currentSearchTermLower.isNotEmpty) {
         mainProductsGrid = mainProductsGrid
            .where((product) =>
                product.name.toLowerCase().contains(currentSearchTermLower) ||
                (product.description?.toLowerCase().contains(currentSearchTermLower) ?? false))
            .toList();
      }
    }

    String? chipIdToHighlightInUI = _activelySelectedChipId;

    // Logic to determine which chip should be highlighted and scroll to it
    if (_isSearchMode) {
        if (currentSearchTermLower.isEmpty) {
            chipIdToHighlightInUI = 'all_products_chip';
            if (_chipKeys['all_products_chip'] != null) {
                _scrollToChip(_chipKeys['all_products_chip']!);
            }
        } else {
            Category? subcategoryMatchingSearchTerm = FirstWhereOrNullExtension(uniqueSubcategoriesForChips).firstWhereOrNull(
                (sub) => sub.name.toLowerCase() == currentSearchTermLower,
            );

            if (subcategoryMatchingSearchTerm != null) {
                chipIdToHighlightInUI = subcategoryMatchingSearchTerm.id;
                if (_chipKeys[subcategoryMatchingSearchTerm.id] != null) {
                    _scrollToChip(_chipKeys[subcategoryMatchingSearchTerm.id]!);
                }
            } else {
                if (mainProductsGrid.isNotEmpty) {
                    final firstProduct = mainProductsGrid.first;
                    Category? subcategoryOfFirstProduct;
                    if (uniqueSubcategoriesForChips.isNotEmpty) {
                        subcategoryOfFirstProduct = FirstWhereOrNullExtension(uniqueSubcategoriesForChips).firstWhereOrNull(
                            (sub) => sub.id == firstProduct.categoryId,
                        );
                        if (subcategoryOfFirstProduct == null) {
                            subcategoryOfFirstProduct = FirstWhereOrNullExtension(uniqueSubcategoriesForChips).firstWhereOrNull(
                                (sub) => _getApplicableCategoryIds(sub.id, allCategoriesStructure).contains(firstProduct.categoryId),
                            );
                        }
                    }
                    if (subcategoryOfFirstProduct != null) {
                        chipIdToHighlightInUI = subcategoryOfFirstProduct.id;
                        if (_chipKeys[subcategoryOfFirstProduct.id] != null) {
                            _scrollToChip(_chipKeys[subcategoryOfFirstProduct.id]!);
                        }
                    } else {
                        chipIdToHighlightInUI = null;
                    }
                } else {
                    chipIdToHighlightInUI = null;
                }
            }
        }
    }


    List<Product> discountedProducts = MockData.mockProducts.where((p) => p.discountedPrice != null).toList();
    if (currentSearchTermLower.isNotEmpty) {
      discountedProducts = discountedProducts
          .where((product) =>
              product.name.toLowerCase().contains(currentSearchTermLower) ||
              (product.description?.toLowerCase().contains(currentSearchTermLower) ?? false))
          .toList();
    }

    final String productSectionMessageVal = getMessageForNotProduct(selectedCategoryId, selectedFullCategoryObject, currentParentCategory, mainProductsGrid, _isSearchMode);
    final bool showProductSectionMessageOnly = !_isSearchMode && mainProductsGrid.isEmpty &&
        ((currentParentCategory != null &&
          currentParentCategory.subcategories != null &&
          currentParentCategory.subcategories!.any((sub) => sub.id == selectedCategoryId)) ||
         selectedCategoryId == MockData.allProductsCategoryId ||
         (!_hasProductsForCategory(selectedCategoryId, MockData.mockProducts, allCategoriesStructure, _isSearchMode) && (selectedFullCategoryObject.subcategories == null || selectedFullCategoryObject.subcategories!.isEmpty) ));

    final displayedMainProducts = mainProductsGrid.isNotEmpty && !_isSearchMode ? mainProductsGrid.take(4).toList() : mainProductsGrid;
    final displayedMainProductsDiscounted = discountedProducts.isNotEmpty ? discountedProducts.take(4).toList() : [];
    final showDisplayTextForNoProductsDiscounted = discountedProducts.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
                    onBackgroundImageError: (exception, stackTrace) {},
                  ),
                ],),
        actions:  const [
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
                              ],),
                            const SizedBox(height: 24),
                            SearchInputWidget(
                              searchTermNotifier: _searchTermNotifier,
                              onSearchModeChanged: _onSearchModeChanged,
                              initialIsSearching: _isSearchMode, // Uses instance _isSearchMode
                              isShowCancelButton: _isSearchMode, // Uses instance _isSearchMode
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_isSearchMode) ...[ // Uses instance _isSearchMode
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filter by:',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 40,
                                child: SingleChildScrollView(
                                  controller: _chipScrollController, // Assign the ScrollController
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      Padding(
                                        key: _chipKeys['all_products_chip'], // Assign GlobalKey
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: FilterChip(
                                          label: const Text('All Products'),
                                          selected: chipIdToHighlightInUI == 'all_products_chip',
                                          onSelected: (selected) {
                                            if (selected) {
                                              _searchTermNotifier.value = '';
                                              if (mounted) {
                                                setState(() { _activelySelectedChipId = 'all_products_chip'; });
                                                _scrollToChip(_chipKeys['all_products_chip']!); // Scroll to it
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                      ...uniqueSubcategoriesForChips.map((subcat) {
                                        return Padding(
                                          key: _chipKeys[subcat.id], // Assign GlobalKey
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: FilterChip(
                                            label: Text(subcat.name),
                                            selected: chipIdToHighlightInUI == subcat.id,
                                            onSelected: (selectedChip) {
                                              if (selectedChip) {
                                                _searchTermNotifier.value = subcat.name;
                                                 if (mounted) {
                                                  setState(() { _activelySelectedChipId = subcat.id; });
                                                  _scrollToChip(_chipKeys[subcat.id]!); // Scroll to it
                                                 }
                                              } else {
                                                  if (chipIdToHighlightInUI == subcat.id) {
                                                       _searchTermNotifier.value = '';
                                                       if (mounted) {
                                                        setState(() { _activelySelectedChipId = 'all_products_chip'; });
                                                        _scrollToChip(_chipKeys['all_products_chip']!); // Scroll back to All Products
                                                       }
                                                  }
                                              }
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (currentSearchTermLower.isNotEmpty && mainProductsGrid.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text('No products found matching "$currentSearchTerm".', style: TextStyle(fontSize: 16, color: Colors.grey[700]),),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                              childAspectRatio: 0.7,
                            ),
                            itemCount: mainProductsGrid.length,
                            itemBuilder: (context, index) {
                              final product = mainProductsGrid[index];
                              return ProductCard(
                                product: product,
                                onTap: () => context.go('/product/${product.id}'),
                              );
                            },
                          ),
                        const SizedBox(height: 24),

                      ] else ...[
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
                                      'categoryName': selectedFullCategoryObject.name,
                                    },
                                  );
                                },
                                child: const Text('View More'),
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
                            itemCount: allCategoriesStructure.length,
                            itemBuilder: (context, index) {
                              final category = allCategoriesStructure[index];
                              final bool isSelected = (currentParentCategory != null && category.id == currentParentCategory.id) ||
                                  (category.id == MockData.allProductsCategoryId && selectedCategoryId == MockData.allProductsCategoryId && currentParentCategory == null);

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
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        if (currentParentCategory != null &&
                            currentParentCategory.subcategories != null &&
                            currentParentCategory.subcategories!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'Subcategories in ${currentParentCategory.name}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 90,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    itemCount: currentParentCategory.subcategories!.length,
                                    itemBuilder: (context, index) {
                                      final subCategory = currentParentCategory.subcategories![index];
                                      final isSubSelected = selectedCategoryId == subCategory.id;
                                      return GestureDetector(
                                        onTap: () {
                                          selectedCategoryNotifier.state = subCategory.id;
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
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                        const SizedBox(height: 24),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            selectedFullCategoryObject.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (showProductSectionMessageOnly)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(productSectionMessageVal),
                              ),
                            )
                        else
                          GridView.builder(
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
                                  onTap: () => context.go('/product/${product.id}'),
                                );
                              },
                            ),
                        const SizedBox(height: 24),

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
                                      'categoryId': MockData.discountedProductsCategoryId,
                                      'categoryName': 'Discounted Products',
                                    },
                                  );
                                },
                                child: const Text('See all'),
                              ),
                            ],
                          ),),
                        const SizedBox(height: 16),
                        showDisplayTextForNoProductsDiscounted
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Text('No products found for discounted items.'),
                                ),)
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
                                itemCount: displayedMainProductsDiscounted.length,
                                itemBuilder: (context, index) {
                                  final product = displayedMainProductsDiscounted[index];
                                  return ProductCard(
                                    product: product,
                                    onTap: () {
                                      context.go('/product/${product.id}');
                                    },
                                  );
                                },),
                        const SizedBox(height: 24),

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
                          ),),
                        const SizedBox(height: 45),
                      ],
                    ],
                  ),
                ),
    );
  }
}

// Helper extension for .firstWhereOrNull (if not already part of your Dart SDK or a utility package)
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}