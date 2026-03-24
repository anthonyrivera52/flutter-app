import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/services/payments/bold_payment_service.dart';

class BoldPaymentResult {
  final bool success;
  final String orderId;
  final String status;
  final String? error;

  const BoldPaymentResult({
    required this.success,
    required this.orderId,
    required this.status,
    this.error,
  });
}

Future<BoldPaymentResult?> showBoldPaymentSheet({
  required BuildContext context,
  required BoldCheckoutData checkoutData,
}) {
  return showModalBottomSheet<BoldPaymentResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _BoldPaymentSheetContent(checkoutData: checkoutData),
  );
}

class _BoldPaymentSheetContent extends StatefulWidget {
  final BoldCheckoutData checkoutData;

  const _BoldPaymentSheetContent({required this.checkoutData});

  @override
  State<_BoldPaymentSheetContent> createState() =>
      _BoldPaymentSheetContentState();
}

class _BoldPaymentSheetContentState extends State<_BoldPaymentSheetContent> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final d = widget.checkoutData;

    final html =
        '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <script src="https://checkout.bold.co/library/boldPaymentButton.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background: #f8f9fa;
      font-family: -apple-system, BlinkMacSystemFont, sans-serif;
    }
  </style>
</head>
<body>
  <script
    data-bold-button
    data-render-mode="embedded"
    data-api-key="${d.apiKey}"
    data-order-id="${d.orderId}"
    data-currency="${d.currency}"
    data-amount="${d.amount}"
    data-integrity-signature="${d.integritySignature}"
    data-redirection-url="${d.redirectionUrl}"
    data-description="${d.description}"
  ></script>
</body>
</html>
''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF8F9FA))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                uri.queryParameters.containsKey('bold-tx-status')) {
              _handlePaymentResult(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(html);
  }

  void _handlePaymentResult(Uri uri) {
    if (_hasCompleted) return;
    _hasCompleted = true;

    final status = uri.queryParameters['bold-tx-status'] ?? 'unknown';
    final orderId =
        uri.queryParameters['bold-order-id'] ?? widget.checkoutData.orderId;

    final success = status.toLowerCase() == 'approved';

    if (mounted) {
      Navigator.of(context).pop(
        BoldPaymentResult(
          success: success,
          orderId: orderId,
          status: status,
          error: success ? null : 'El pago fue $status',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              if (_isLoading) const LinearProgressIndicator(),
              Expanded(child: WebViewWidget(controller: _controller)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  'Pago seguro',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop(
                  const BoldPaymentResult(
                    success: false,
                    orderId: '',
                    status: 'cancelled',
                    error: 'Pago cancelado por el usuario',
                  ),
                );
              }
            },
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cancelar pago',
          ),
        ],
      ),
    );
  }
}
