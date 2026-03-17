import 'package:flutter/material.dart';
import 'package:flutter_app/features/cart/presentation/viewmodels/cart_viewmodel.dart';
import 'package:flutter_app/presentation/pages/cart/cart_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;

class HomeAppBarActions extends ConsumerWidget {
  const HomeAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalQuantity = ref.watch(cartProvider.select((s) => s.totalQuantity));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () => context.go('/notifications'),
        ),
        badges.Badge(
          showBadge: totalQuantity > 0,
          badgeContent: Text(
            totalQuantity.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          position: badges.BadgePosition.topEnd(top: 0, end: 3),
          badgeStyle: const badges.BadgeStyle(
            badgeColor: Colors.red,
            padding: EdgeInsets.all(5),
          ),
          child: IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext context) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.75,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (_, __) => const CartModalContent(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
