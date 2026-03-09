// lib/widget/adaptive_widgets.dart
// Widgets adaptativos para iOS y Android

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ============================================================================
// ADAPTIVE SCAFFOLD
// ============================================================================

/// Scaffold que adapta a la plataforma
class AdaptiveScaffold extends StatelessWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showCupertinoNavBar;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;

  const AdaptiveScaffold({
    super.key,
    this.title,
    this.leading,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.showCupertinoNavBar = false,
    this.backgroundColor,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS && showCupertinoNavBar) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        navigationBar: CupertinoNavigationBar(
          middle: title != null ? Text(title!) : null,
          leading: leading,
          trailing: actions != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                )
              : null,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              body,
              if (floatingActionButton != null)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: floatingActionButton!,
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              leading: leading,
              actions: actions,
              bottom: bottom,
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

// ============================================================================
// ADAPTIVE BUTTON
// ============================================================================

/// Botón que adapta su estilo a la plataforma
class AdaptiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const AdaptiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isDestructive = false,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget buttonChild = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          );

    final buttonWidget = isFullWidth
        ? SizedBox(width: double.infinity, child: _buildButton(context, buttonChild))
        : _buildButton(context, buttonChild);

    return buttonWidget;
  }

  Widget _buildButton(BuildContext context, Widget buttonChild) {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      if (!isPrimary) {
        return CupertinoButton(
          onPressed: isLoading ? null : onPressed,
          child: buttonChild,
        );
      }

      return CupertinoButton.filled(
        onPressed: isLoading ? null : onPressed,
        child: buttonChild,
      );
    }

    // Material Design
    if (isPrimary) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: isDestructive
            ? ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              )
            : null,
        child: buttonChild,
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: isDestructive
          ? OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            )
          : null,
      child: buttonChild,
    );
  }
}

// ============================================================================
// ADAPTIVE DIALOG
// ============================================================================

/// Diálogo que adapta su estilo a la plataforma
class AdaptiveDialog extends StatelessWidget {
  final String title;
  final String? message;
  final List<Widget>? actions;

  const AdaptiveDialog({
    super.key,
    required this.title,
    this.message,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: message != null ? Text(message!) : null,
        actions: actions ??
            [
              CupertinoDialogAction(
                child: const Text('Aceptar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
      );
    }

    return AlertDialog(
      title: Text(title),
      content: message != null ? Text(message!) : null,
      actions: actions ??
          [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
    );
  }

  /// Mostrar diálogo de forma adaptativa
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? message,
    List<Widget>? actions,
  }) {
    if (Platform.isIOS) {
      return showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: message != null ? Text(message!) : null,
          actions: actions ??
              [
                CupertinoDialogAction(
                  child: const Text('Aceptar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
        ),
      );
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: message != null ? Text(message!) : null,
        actions: actions ??
            [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Aceptar'),
              ),
            ],
      ),
    );
  }

  /// Mostrar diálogo de confirmación
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    String? message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool isDestructive = false,
  }) async {
    if (Platform.isIOS) {
      return await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text(title),
              content: message != null ? Text(message!) : null,
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: isDestructive,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmText),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelText),
                ),
              ],
            ),
          ) ??
          false;
    }

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: message != null ? Text(message!) : null,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: isDestructive
                    ? TextButton.styleFrom(foregroundColor: Colors.red)
                    : null,
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ============================================================================
// ADAPTIVE APP BAR
// ============================================================================

/// AppBar que adapta su estilo a la plataforma
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;

  const AdaptiveAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoNavigationBar(
        middle: Text(title),
        leading: leading,
        trailing: actions != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              )
            : null,
        backgroundColor: backgroundColor,
        automaticallyImplyLeading: automaticallyImplyLeading,
      );
    }

    return AppBar(
      title: Text(title),
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
}

// ============================================================================
// ADAPTIVE TEXT FIELD
// ============================================================================

/// Campo de texto que adapta su estilo a la plataforma
class AdaptiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final String? labelText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLines;
  final bool autofocus;

  const AdaptiveTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.labelText,
    this.keyboardType,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder ?? labelText,
        keyboardType: keyboardType,
        obscureText: obscureText,
        prefix: prefix,
        suffix: suffix,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        maxLines: maxLines,
        autofocus: autofocus,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      maxLines: maxLines,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: placeholder,
        prefixIcon: prefix,
        suffixIcon: suffix,
      ),
    );
  }
}

// ============================================================================
// ADAPTIVE LOADING INDICATOR
// ============================================================================

/// Indicador de carga adaptativo
class AdaptiveLoadingIndicator {
  static Widget show({double size = 36}) {
    if (Platform.isIOS) {
      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: const CupertinoActivityIndicator(),
        ),
      );
    }

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  static Widget showOverlay(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Platform.isIOS
            ? const CupertinoActivityIndicator(radius: 16)
            : const CircularProgressIndicator(),
      ),
    );
  }
}

// ============================================================================
// ADAPTIVE SWITCH
// ============================================================================

/// Switch adaptativo
class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: activeColor,
      );
    }

    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
    );
  }
}

// ============================================================================
// ADAPTIVE SLIDER
// ============================================================================

/// Slider adaptativo
class AdaptiveSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String? label;

  const AdaptiveSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoSlider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      );
    }

    return Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      label: label,
      onChanged: onChanged,
    );
  }
}
