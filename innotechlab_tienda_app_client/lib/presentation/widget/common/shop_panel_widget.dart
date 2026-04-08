import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/products/domain/models/product_entity.dart';
import 'package:flutter_app/features/products/domain/models/shop_entity.dart';
import 'package:flutter_app/features/products/domain/models/category_entity.dart';
import 'package:flutter_app/features/products/domain/models/location_hour.dart';
import 'package:flutter_app/features/cart/presentation/viewmodels/cart_viewmodel.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/widget/common/schedule_dialog.dart';
import 'package:flutter_app/presentation/widget/common/price_display.dart';
import 'package:go_router/go_router.dart';

class ShopPanelWidget extends ConsumerStatefulWidget {
  final Shop shop;
  final List<Product> products;
  final List<String> categoryIds;
  final List<Category> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onClose;
  final VoidCallback onChangeShop;
  final List<LocationHour> shopHours;
  final bool isLoadingHours;
  final bool isLoadingProducts;
  final bool isViewOnly;

  const ShopPanelWidget({
    super.key,
    required this.shop,
    required this.products,
    required this.categoryIds,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onClose,
    required this.onChangeShop,
    this.shopHours = const [],
    this.isLoadingHours = false,
    this.isLoadingProducts = false,
    this.isViewOnly = false,
  });

  @override
  ConsumerState<ShopPanelWidget> createState() => _ShopPanelWidgetState();
}

class _ShopPanelWidgetState extends ConsumerState<ShopPanelWidget> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();
  static const double _minSize = 0.25;
  static const double _maxSize = 0.85;
  static const double _initSize = 0.50;

  @override
  Widget build(BuildContext context) {
    final filteredProducts = widget.selectedCategoryId == 'all'
        ? widget.products
        : widget.products
              .where((p) => p.categoryId == widget.selectedCategoryId)
              .toList();

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: _initSize,
      minChildSize: _minSize,
      maxChildSize: _maxSize,
      snap: true,
      snapSizes: const [_minSize, _initSize, _maxSize],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(),
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      _buildCategories(),
                      if (widget.isLoadingProducts)
                        _buildLoadingSkeleton()
                      else if (filteredProducts.isEmpty)
                        _buildEmptyState()
                      else
                        _buildProductsGrid(filteredProducts),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return GestureDetector(
      onTap: () {
        if (_controller.size > _initSize - 0.05) {
          _controller.animateTo(
            _minSize,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _controller.animateTo(
            _initSize,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.shop.logoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.shop.logoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Icon(Icons.store, color: Colors.grey.shade400),
                        )
                      : Icon(Icons.store, color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.shop.organizationName != null)
                      Text(
                        widget.shop.organizationName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    Text(
                      widget.shop.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusBadge(),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '15-25 min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // IconButton(
              //   onPressed: widget.onChangeShop,
              //   icon: Icon(Icons.swap_horiz, color: Colors.grey.shade600),
              //   tooltip: 'Cambiar comercio',
              // ),
              IconButton(
                onPressed: widget.onClose,
                icon: Icon(Icons.close, color: Colors.grey.shade600),
                tooltip: 'Cerrar',
              ),
            ],
          ),
          _buildChannelsRow(),
          _buildChannelsWarning(),
        ],
      ),
    );
  }

  Widget _buildChannelsWarning() {
    if (widget.shop.isOpen) {
      final hasActiveDelivery =
          widget.shop.deliveryStatus == ShopDeliveryStatus.active ||
          widget.shop.deliveryStatus == ShopDeliveryStatus.waiting;
      final hasActivePickup =
          widget.shop.pickupStatus == ShopDeliveryStatus.active ||
          widget.shop.pickupStatus == ShopDeliveryStatus.waiting;

      if (!hasActiveDelivery && !hasActivePickup) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: Colors.amber.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'El delivery y pickup están cerrados actualmente.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildChannelsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildChannelChip(
              icon: Icons.local_shipping_outlined,
              label: 'Delivery',
              status: widget.shop.deliveryStatus,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildChannelChip(
              icon: Icons.storefront_outlined,
              label: 'Pickup',
              status: widget.shop.pickupStatus,
            ),
          ),
          const SizedBox(width: 8),
          // _buildScheduleButton(),
        ],
      ),
    );
  }

  Widget _buildChannelChip({
    required IconData icon,
    required String label,
    required ShopDeliveryStatus? status,
  }) {
    final isActive = status == ShopDeliveryStatus.active;
    final isWaiting = status == ShopDeliveryStatus.waiting;

    Color bgColor;
    Color textColor;
    Color iconColor;
    String statusText;

    if (isActive) {
      textColor = Colors.green.shade700;
      bgColor = textColor.withValues(alpha: 0.1);
      iconColor = Colors.green;
      statusText = 'Activo';
    } else if (isWaiting) {
      textColor = Colors.amber.shade700;
      bgColor = textColor.withValues(alpha: 0.1);
      iconColor = Colors.amber;
      statusText = 'Alta demanda';
    } else {
      textColor = Colors.grey.shade600;
      bgColor = textColor.withValues(alpha: 0.1);
      iconColor = Colors.grey;
      statusText = 'No disponible';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleButton() {
    return GestureDetector(
      onTap: () {
        ScheduleDialog.show(
          context,
          hours: widget.shopHours,
          locationName: widget.shop.name,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 18, color: AppColors.primaryColor),
            const SizedBox(width: 6),
            Text(
              'Horarios',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    if (widget.shop.deliveryStatus == ShopDeliveryStatus.waiting) {
      textColor = Colors.amber.shade800;
      bgColor = textColor.withValues(alpha: 0.1);
      text = 'Alta demanda';
      icon = Icons.warning_amber_rounded;
    } else if (widget.shop.isOpen) {
      textColor = Colors.green.shade700;
      bgColor = textColor.withValues(alpha: 0.1);
      text = 'Abierto';
      icon = Icons.check_circle;
    } else {
      textColor = Colors.red.shade700;
      bgColor = textColor.withValues(alpha: 0.1);
      text = 'Cerrado';
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.categoryIds.length,
        itemBuilder: (context, index) {
          final categoryId = widget.categoryIds[index];
          final category = index > 0 && index - 1 < widget.categories.length
              ? widget.categories[index - 1]
              : null;
          final isSelected = categoryId == widget.selectedCategoryId;
          final displayName = categoryId == 'all'
              ? 'Todos'
              : (category?.name ?? categoryId);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => widget.onCategorySelected(categoryId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fastfood_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No hay productos en esta categoría',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _SkeletonCard();
      },
    );
  }

  Widget _buildProductsGrid(List<Product> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(
          product: product,
          ref: ref,
          onTap: () {
            final validation = CartNotifier.validateShopForCart(widget.shop);

            if (widget.isViewOnly) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Selecciona este comercio en el inicio para comprar',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (!validation.canAddToCart) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(validation.message),
                  backgroundColor: Colors.orange.shade800,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else {
              context.go('/product/${product.id}');
            }
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final WidgetRef ref;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        product.discountedPrice != null &&
        product.discountedPrice! < product.price;

    final cartItems = ref.watch(cartProvider).items;
    final cartItem = cartItems
        .where((i) => i.productId == product.id)
        .firstOrNull;
    final quantity = cartItem?.quantity ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: quantity > 0 ? AppColors.primaryColor : Colors.grey.shade200,
            width: quantity > 0 ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: product.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (_, __, ___) => Icon(
                                Icons.fastfood,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                            )
                          : Icon(
                              Icons.fastfood,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${((1 - product.discountedPrice! / product.price) * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasDiscount)
                                PriceText(
                                  price: product.discountedPrice!,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                )
                              else
                                PriceText(
                                  price: product.price,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              if (hasDiscount)
                                PriceText(
                                  price: product.price,
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              Text(
                                product.unit,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        quantity == 0
                            ? GestureDetector(
                                onTap: () {
                                  ref
                                      .read(cartProvider.notifier)
                                      .addItem(product);
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (quantity > 1) {
                                          ref
                                              .read(cartProvider.notifier)
                                              .updateQuantity(
                                                product.id,
                                                quantity - 1,
                                              );
                                        } else {
                                          ref
                                              .read(cartProvider.notifier)
                                              .removeItem(product.id);
                                        }
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.remove,
                                          color: quantity > 1
                                              ? Colors.grey.shade700
                                              : Colors.red,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 22,
                                      alignment: Alignment.center,
                                      child: Text(
                                        quantity.toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .updateQuantity(
                                              product.id,
                                              quantity + 1,
                                            );
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.add,
                                          color: AppColors.primaryColor,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 14,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
