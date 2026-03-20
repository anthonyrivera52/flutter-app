import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/features/products/domain/models/product_entity.dart';
import 'package:flutter_app/features/products/domain/models/shop_entity.dart';
import 'package:flutter_app/features/products/domain/models/location_hour.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/widget/common/schedule_dialog.dart';
import 'package:go_router/go_router.dart';

class ShopPanelWidget extends StatefulWidget {
  final Shop shop;
  final List<Product> products;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onClose;
  final VoidCallback onChangeShop;
  final List<LocationHour> shopHours;
  final bool isLoadingHours;
  final bool isViewOnly;

  const ShopPanelWidget({
    super.key,
    required this.shop,
    required this.products,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onClose,
    required this.onChangeShop,
    this.shopHours = const [],
    this.isLoadingHours = false,
    this.isViewOnly = false,
  });

  @override
  State<ShopPanelWidget> createState() => _ShopPanelWidgetState();
}

class _ShopPanelWidgetState extends State<ShopPanelWidget> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();
  static const double _minSize = 0.25;
  static const double _maxSize = 0.85;
  static const double _initSize = 0.50;

  @override
  Widget build(BuildContext context) {
    final filteredProducts = widget.selectedCategory == 'all'
        ? widget.products
        : widget.products
              .where((p) => p.categoryId == widget.selectedCategory)
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
                      if (filteredProducts.isEmpty)
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
        ],
      ),
    );
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
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final isSelected = category == widget.selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => widget.onCategorySelected(category),
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
                  _formatCategoryName(category),
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

  String _formatCategoryName(String category) {
    if (category == 'all') return 'Todos';
    return category
        .replaceAll('_category_id', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
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
          onTap: () {
            final isShopOpen = widget.shop.isOpen;
            final hasActiveChannels =
                (widget.shop.deliveryStatus == ShopDeliveryStatus.active ||
                    widget.shop.deliveryStatus == ShopDeliveryStatus.waiting) ||
                (widget.shop.pickupStatus == ShopDeliveryStatus.active ||
                    widget.shop.pickupStatus == ShopDeliveryStatus.waiting);
            final canViewDetail = isShopOpen && hasActiveChannels;

            if (widget.isViewOnly) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Selecciona este comercio en el inicio para comprar',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (!canViewDetail) {
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
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        product.discountedPrice != null &&
        product.discountedPrice! < product.price;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
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
                      children: [
                        if (hasDiscount)
                          Text(
                            '\$${product.discountedPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          )
                        else
                          Text(
                            '\$${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            '\$${product.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.unit,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
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
