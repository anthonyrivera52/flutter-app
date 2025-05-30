// Mock de información de usuario para visualización
import 'package:flutter_app/domain/entities/cartItem.dart';
import 'package:flutter_app/domain/entities/category.dart';
import 'package:flutter_app/domain/entities/order.dart';
import 'package:flutter_app/domain/entities/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Para generar IDs únicos

// Instancia de Uuid para generar IDs
const Uuid uuid = Uuid();

class MockData {
  static List<Category> get mockCategories => [
        Category(id: uuid.v4(), name: 'Frutas y Verduras', imageUrl: 'https://placehold.co/100x100/A7D9B1/000000?text=FV'),
        Category(id: uuid.v4(), name: 'Lácteos y Huevos', imageUrl: 'https://placehold.co/100x100/F0E68C/000000?text=LH'),
        Category(id: uuid.v4(), name: 'Carnes y Pescados', imageUrl: 'https://placehold.co/100x100/FF6347/FFFFFF?text=CP'),
        Category(id: uuid.v4(), name: 'Panadería y Pastelería', imageUrl: 'https://placehold.co/100x100/D2B48C/000000?text=PP'),
        Category(id: uuid.v4(), name: 'Bebidas', imageUrl: 'https://placehold.co/100x100/87CEEB/000000?text=BB'),
        Category(id: uuid.v4(), name: 'Snacks y Dulces', imageUrl: 'https://placehold.co/100x100/FFD700/000000?text=SD'),
      ];

  static List<Product> get mockProducts {
    final categories = mockCategories;
    final Map<String, String> categoryMap = {
      'Frutas y Verduras': categories[0].id,
      'Lácteos y Huevos': categories[1].id,
      'Carnes y Pescados': categories[2].id,
      'Panadería y Pastelería': categories[3].id,
      'Bebidas': categories[4].id,
      'Snacks y Dulces': categories[5].id,
    };

    return [
      Product(
        id: uuid.v4(),
        name: 'Manzanas Rojas',
        description: 'Manzanas frescas y crujientes, ideales para un snack saludable.',
        price: 2.50,
        imageUrl: 'https://placehold.co/150x150/FF0000/FFFFFF?text=Manzanas',
        unit: 'kg',
        categoryId: categoryMap['Frutas y Verduras']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Leche Entera',
        description: 'Leche de vaca pasteurizada, rica en calcio.',
        price: 1.20,
        imageUrl: 'https://placehold.co/150x150/ADD8E6/000000?text=Leche',
        unit: 'litro',
        categoryId: categoryMap['Lácteos y Huevos']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Pechuga de Pollo',
        description: 'Pechuga de pollo fresca, ideal para asar o cocinar.',
        price: 8.99,
        imageUrl: 'https://placehold.co/150x150/FFDAB9/000000?text=Pollo',
        unit: 'kg',
        categoryId: categoryMap['Carnes y Pescados']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Pan Integral',
        description: 'Pan horneado diariamente con granos integrales.',
        price: 3.00,
        imageUrl: 'https://placehold.co/150x150/DEB887/000000?text=Pan',
        unit: 'unidad',
        categoryId: categoryMap['Panadería y Pastelería']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Jugo de Naranja',
        description: 'Jugo 100% natural de naranjas recién exprimidas.',
        price: 2.80,
        imageUrl: 'https://placehold.co/150x150/FFA500/FFFFFF?text=Jugo',
        unit: 'litro',
        categoryId: categoryMap['Bebidas']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Galletas de Chocolate',
        description: 'Deliciosas galletas con trozos de chocolate.',
        price: 1.95,
        imageUrl: 'https://placehold.co/150x150/D2691E/FFFFFF?text=Galletas',
        unit: 'paquete',
        categoryId: categoryMap['Snacks y Dulces']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Plátanos',
        description: 'Plátanos maduros, fuente de energía y potasio.',
        price: 1.80,
        imageUrl: 'https://placehold.co/150x150/FFFF00/000000?text=Platanos',
        unit: 'kg',
        categoryId: categoryMap['Frutas y Verduras']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Yogurt Natural',
        description: 'Yogurt cremoso sin azúcares añadidos.',
        price: 1.50,
        imageUrl: 'https://placehold.co/150x150/F0F8FF/000000?text=Yogurt',
        unit: 'unidad',
        categoryId: categoryMap['Lácteos y Huevos']!,
      ),
    ];
  }

  static List<CartItem> get mockCartItems {
    final products = mockProducts;
    return [
      CartItem(
        productId: products[0].id,
        name: products[0].name,
        imageUrl: products[0].imageUrl,
        price: products[0].price,
        unit: products[0].unit,
        quantity: 2,
      ),
      CartItem(
        productId: products[1].id,
        name: products[1].name,
        imageUrl: products[1].imageUrl,
        price: products[1].price,
        unit: products[1].unit,
        quantity: 1,
      ),
      CartItem(
        productId: products[3].id,
        name: products[3].name,
        imageUrl: products[3].imageUrl,
        price: products[3].price,
        unit: products[3].unit,
        quantity: 3,
      ),
    ];
  }

  static List<Order> get mockOrders {
    final cartItems = mockCartItems;
    return [
      Order(
        id: uuid.v4(),
        userId: 'user_123',
        orderDate: DateTime.now().subtract(const Duration(days: 5)),
        items: cartItems,
        totalAmount: cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity)),
        status: 'Delivered',
        deliveryAddress: 'Calle Falsa 123, Ciudad Ficticia',
      ),
      Order(
        id: uuid.v4(),
        userId: 'user_123',
        orderDate: DateTime.now().subtract(const Duration(days: 1)),
        items: [
          CartItem(
            productId: mockProducts[4].id,
            name: mockProducts[4].name,
            imageUrl: mockProducts[4].imageUrl,
            price: mockProducts[4].price,
            unit: mockProducts[4].unit,
            quantity: 2,
          ),
          CartItem(
            productId: mockProducts[6].id,
            name: mockProducts[6].name,
            imageUrl: mockProducts[6].imageUrl,
            price: mockProducts[6].price,
            unit: mockProducts[6].unit,
            quantity: 4,
          ),
        ],
        totalAmount: (mockProducts[4].price * 2) + (mockProducts[6].price * 4),
        status: 'Processing',
        deliveryAddress: 'Avenida Siempre Viva 742, Springfield',
      ),
    ];
  }

  final mockUser = User(
    id: 'mock_user_id',
    email: 'admin.mock@example.com',
    appMetadata: const {},
    userMetadata: const {
      'display_name': 'Usuario de Prueba',
      'avatar_url': 'https://placehold.co/100x100/007bff/ffffff?text=U', // Imagen de placeholder
    },
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
  );

}
