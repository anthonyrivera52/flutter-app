import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/connectivity_provider.dart';

/// Breakpoints basados en Material 3 Design
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 840;
  static const double desktop = 1200;

  Breakpoints._();
}

enum DeviceType { mobile, tablet, desktop }

enum WindowType { compact, medium, expanded }

extension DeviceTypeExtension on DeviceType {
  bool get isMobile => this == DeviceType.mobile;
  bool get isTablet => this == DeviceType.tablet;
  bool get isDesktop => this == DeviceType.desktop;

  String get label {
    switch (this) {
      case DeviceType.mobile:
        return 'Mobile';
      case DeviceType.tablet:
        return 'Tablet';
      case DeviceType.desktop:
        return 'Desktop';
    }
  }
}

extension WindowTypeExtension on WindowType {
  bool get isCompact => this == WindowType.compact;
  bool get isMedium => this == WindowType.medium;
  bool get isExpanded => this == WindowType.expanded;
}

/// Banner that shows when device is offline
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityStatusProvider);

    if (connectivityStatus == ConnectivityStatus.connected) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: connectivityStatus == ConnectivityStatus.disconnected ? 40 : 0,
      color: Colors.orange.shade800,
      child: connectivityStatus == ConnectivityStatus.disconnected
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Sin conexión a internet',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    ref
                        .read(connectivityStatusProvider.notifier)
                        .checkConnection();
                  },
                  child: const Text(
                    'Reintentar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Responsive builder for adaptive layouts
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final deviceType = getDeviceType(context);
    return builder(context, deviceType);
  }

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < Breakpoints.mobile) {
      return DeviceType.mobile;
    } else if (width < Breakpoints.tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  static WindowType getWindowType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < Breakpoints.mobile) {
      return WindowType.compact;
    } else if (width < Breakpoints.tablet) {
      return WindowType.medium;
    } else {
      return WindowType.expanded;
    }
  }
}

/// Extension to easily access device type in any BuildContext
extension DeviceContext on BuildContext {
  DeviceType get deviceType => ResponsiveBuilder.getDeviceType(this);
  WindowType get windowType => ResponsiveBuilder.getWindowType(this);

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  bool get isCompact => windowType == WindowType.compact;
  bool get isMedium => windowType == WindowType.medium;
  bool get isExpanded => windowType == WindowType.expanded;

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;
  bool get isPortrait => MediaQuery.orientationOf(this) == Orientation.portrait;
}

/// Responsive layout widget with breakpoint callbacks
class AdaptiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context)? mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;
  final Widget Function(BuildContext context)? compact;
  final Widget Function(BuildContext context)? medium;
  final Widget Function(BuildContext context)? expanded;
  final Widget Function(BuildContext context)? fallback;

  const AdaptiveLayout({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.compact,
    this.medium,
    this.expanded,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveBuilder.getDeviceType(context);
    final windowType = ResponsiveBuilder.getWindowType(context);

    if (windowType == WindowType.expanded && expanded != null) {
      return expanded!(context);
    }
    if (windowType == WindowType.medium && medium != null) {
      return medium!(context);
    }
    if (windowType == WindowType.compact && compact != null) {
      return compact!(context);
    }

    if (deviceType == DeviceType.desktop && desktop != null) {
      return desktop!(context);
    }
    if (deviceType == DeviceType.tablet && tablet != null) {
      return tablet!(context);
    }
    if (deviceType == DeviceType.mobile && mobile != null) {
      return mobile!(context);
    }

    return fallback?.call(context) ?? const SizedBox.shrink();
  }
}

/// Responsive grid that adapts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.childAspectRatio = 0.7,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        int crossAxisCount;
        switch (deviceType) {
          case DeviceType.mobile:
            crossAxisCount = 2;
            break;
          case DeviceType.tablet:
            crossAxisCount = 3;
            break;
          case DeviceType.desktop:
            crossAxisCount = 4;
            break;
        }

        return GridView.builder(
          controller: controller,
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Responsive padding
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double? mobile;
  final double? tablet;
  final double? desktop;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        double padding;
        switch (deviceType) {
          case DeviceType.mobile:
            padding = mobile ?? 16;
            break;
          case DeviceType.tablet:
            padding = tablet ?? 24;
            break;
          case DeviceType.desktop:
            padding = desktop ?? 32;
            break;
        }
        return Padding(padding: EdgeInsets.all(padding), child: child);
      },
    );
  }
}

/// Responsive width constraint
class ResponsiveConstrainedBox extends StatelessWidget {
  final Widget child;
  final double? maxWidthMobile;
  final double? maxWidthTablet;
  final double? maxWidthDesktop;
  final double? minWidthMobile;
  final double? minWidthTablet;
  final double? minWidthDesktop;

  const ResponsiveConstrainedBox({
    super.key,
    required this.child,
    this.maxWidthMobile,
    this.maxWidthTablet,
    this.maxWidthDesktop,
    this.minWidthMobile,
    this.minWidthTablet,
    this.minWidthDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        BoxConstraints constraints;
        switch (deviceType) {
          case DeviceType.mobile:
            constraints = BoxConstraints(
              minWidth: minWidthMobile ?? 0,
              maxWidth: maxWidthMobile ?? double.infinity,
            );
            break;
          case DeviceType.tablet:
            constraints = BoxConstraints(
              minWidth: minWidthTablet ?? 0,
              maxWidth: maxWidthTablet ?? double.infinity,
            );
            break;
          case DeviceType.desktop:
            constraints = BoxConstraints(
              minWidth: minWidthDesktop ?? 0,
              maxWidth: maxWidthDesktop ?? double.infinity,
            );
            break;
        }
        return ConstrainedBox(constraints: constraints, child: child);
      },
    );
  }
}

/// Centered container with max width
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double? maxWidthMobile;
  final double? maxWidthTablet;
  final double? maxWidthDesktop;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidthMobile,
    this.maxWidthTablet,
    this.maxWidthDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        double? maxWidth;
        switch (deviceType) {
          case DeviceType.mobile:
            maxWidth = maxWidthMobile;
            break;
          case DeviceType.tablet:
            maxWidth = maxWidthTablet;
            break;
          case DeviceType.desktop:
            maxWidth = maxWidthDesktop;
            break;
        }

        if (maxWidth == null) {
          return child;
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}

/// Layout builder with device type
class AdaptiveLayoutBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    DeviceType deviceType,
  )
  builder;

  const AdaptiveLayoutBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveBuilder.getDeviceType(context);
        return builder(context, constraints, deviceType);
      },
    );
  }
}
