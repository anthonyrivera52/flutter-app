// lib/view/order_detail_screen.dart
// Pantalla de detalle de un pedido específico

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:delivery_app_mvvm/core/providers/delivery_provider.dart';

class OrderDetailScreen extends StatelessWidget {
  final dynamic order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mapa con la ruta
            SizedBox(
              height: 200,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    order.restaurantLocation.latitude,
                    order.restaurantLocation.longitude,
                  ),
                  zoom: 14,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('restaurant'),
                    position: LatLng(
                      order.restaurantLocation.latitude,
                      order.restaurantLocation.longitude,
                    ),
                    infoWindow: InfoWindow(
                      title: 'Restaurante',
                      snippet: order.restaurantName,
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                  ),
                  Marker(
                    markerId: const MarkerId('customer'),
                    position: LatLng(
                      order.customerLocation.latitude,
                      order.customerLocation.longitude,
                    ),
                    infoWindow: InfoWindow(
                      title: 'Cliente',
                      snippet: order.customerName,
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange,
                    ),
                  ),
                },
                polylines: {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: [
                      LatLng(
                        order.restaurantLocation.latitude,
                        order.restaurantLocation.longitude,
                      ),
                      LatLng(
                        order.customerLocation.latitude,
                        order.customerLocation.longitude,
                      ),
                    ],
                    color: Colors.blue,
                    width: 4,
                  ),
                },
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                zoomGesturesEnabled: false,
              ),
            ),

            // Estado del pedido
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _getStatusColor(order.status).withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStatusIcon(order.status),
                    color: _getStatusColor(order.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(order.status),
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del restaurante
                  _buildSection(
                    title: 'Restaurante',
                    icon: Icons.store,
                    children: [
                      _buildInfoRow('Nombre', order.restaurantName),
                      _buildInfoRow('Dirección', order.restaurantAddress),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Información del cliente
                  _buildSection(
                    title: 'Cliente',
                    icon: Icons.person,
                    children: [
                      _buildInfoRow('Nombre', order.customerName),
                      _buildInfoRow('Teléfono', order.customerPhone),
                      _buildInfoRow('Dirección', order.customerAddress),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Detalles del pedido
                  _buildSection(
                    title: 'Detalles del Pedido',
                    icon: Icons.receipt_long,
                    children: [
                      _buildInfoRow(
                        'Distancia',
                        '${order.distanceKm.toStringAsFixed(2)} km',
                      ),
                      _buildInfoRow(
                        'Tiempo estimado',
                        '~${order.estimatedTimeMinutes} min',
                      ),
                      _buildInfoRow(
                        'Total pedido',
                        '\$${order.totalAmount.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Ganancias
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Tu Ganancia',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${order.estimatedEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Código de entrega: ${order.deliveryCode ?? "N/A"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Código de verificación
                  if (order.pickupCode != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Código de recogida',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.pickupCode!,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Fecha y hora
                  _buildSection(
                    title: 'Información',
                    icon: Icons.info,
                    children: [
                      _buildInfoRow(
                        'Fecha',
                        _formatDate(order.createdAt),
                      ),
                      _buildInfoRow(
                        'ID Pedido',
                        order.id.substring(0, 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'arrived_at_restaurant':
        return Colors.blue;
      case 'picking_up':
      case 'picked_up':
        return Colors.purple;
      case 'delivering':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check_circle;
      case 'arrived_at_restaurant':
        return Icons.location_on;
      case 'picking_up':
      case 'picked_up':
        return Icons.shopping_bag;
      case 'delivering':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptado';
      case 'arrived_at_restaurant':
        return 'Llegando al restaurante';
      case 'picking_up':
        return 'Recogiendo pedido';
      case 'picked_up':
        return 'Pedido recogido';
      case 'delivering':
        return 'En camino';
      case 'delivered':
        return 'Entregado';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} a las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
