import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/region_provider.dart';

class PriceDisplay extends ConsumerWidget {
  final double price;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;

  const PriceDisplay({
    super.key,
    required this.price,
    this.style,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regionConfig = ref.watch(currentRegionConfigProvider);

    final formattedPrice = regionConfig.formatPrice(price);
    final displayText = '${prefix ?? ''}$formattedPrice${suffix ?? ''}';

    return Text(displayText, style: style);
  }
}

class PriceText extends ConsumerWidget {
  final double price;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;

  const PriceText({
    super.key,
    required this.price,
    this.color,
    this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regionConfig = ref.watch(currentRegionConfigProvider);

    return Text(
      regionConfig.formatPrice(price),
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}
