// Mock de información de usuario para visualización
import 'package:flutter_app/domain/entities/cartItem.dart';
import 'package:flutter_app/domain/entities/category.dart';
import 'package:flutter_app/domain/entities/order.dart';
import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_app/domain/entities/recipe.dart';
import 'package:flutter_app/domain/entities/shopt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Para generar IDs únicos

// Instancia de Uuid para generar IDs
const Uuid uuid = Uuid();

/// Provides mock data for the grocery application.
class MockData {
  // IDs especiales para categorías
  static final String allProductsCategoryId = uuid.v4();
  static final String discountedProductsCategoryId = uuid.v4();

static List<Category> get mockCategories {
    // IDs para categorías principales (puedes generarlos o definirlos estáticamente)
    final String vegetablesId = uuid.v4();
    final String fruitsId = uuid.v4();
    final String meatId = uuid.v4();
    final String drinksId = uuid.v4();
    final String dairyId = uuid.v4();
    final String bakeryId = uuid.v4();

    // IDs para subcategorías (si necesitas referenciarlas directamente)
    final String tomatoesId = uuid.v4(); // ID para la subcategoría Tomatoes

    return [
      Category(id: allProductsCategoryId, name: 'All Products', imageUrl: 'https://placehold.co/100x100/CCCCCC/000000?text=All'),
      Category(
        id: vegetablesId,
        name: 'Vegetables',
        imageUrl: 'https://placehold.co/100x100/A7D9B1/000000?text=V',
        subcategories: [
          Category(
            id: tomatoesId, // Usar el ID que definiste para Tomatoes
            name: 'Tomatoes',
            imageUrl: 'https://placehold.co/100x100/FF6347/FFFFFF?text=T',
            parentId: vegetablesId, // Referencia al padre
            // Aquí podrían ir sub-subcategorías si fuera necesario, e.g., 'Cherry Tomatoes', 'Plum Tomatoes'
          ),
          Category(
            name: 'Leafy Greens', // Nueva subcategoría
            imageUrl: 'https://placehold.co/100x100/38761D/FFFFFF?text=LG',
            parentId: vegetablesId,
          ),
          Category(
            name: 'Root Vegetables', // Nueva subcategoría (para zanahorias, etc.)
            imageUrl: 'https://placehold.co/100x100/B45F06/FFFFFF?text=RV',
            parentId: vegetablesId,
          ),
          Category(
            name: 'Peppers', // Subcategoría para 'Red Peppers'
            imageUrl: 'https://placehold.co/100x100/FF5722/FFFFFF?text=P',
            parentId: vegetablesId,
          ),
          Category(
            name: 'Broccoli & Cauliflower', // Subcategoría para 'Fresh Broccoli'
            imageUrl: 'https://placehold.co/100x100/4CAF50/FFFFFF?text=BC',
            parentId: vegetablesId,
          ),
        ],
      ),
      Category(
        id: fruitsId,
        name: 'Fruits',
        imageUrl: 'https://placehold.co/100x100/FFD700/000000?text=F',
        subcategories: [
          Category(
            name: 'Apples',
            imageUrl: 'https://placehold.co/100x100/FF0000/FFFFFF?text=Apls',
            parentId: fruitsId,
          ),
          Category(
            name: 'Bananas',
            imageUrl: 'https://placehold.co/100x100/FFFF00/000000?text=Bana',
            parentId: fruitsId,
          ),
          Category(
            name: 'Berries', // Para 'Rewe Bio Beeren'
            imageUrl: 'https://placehold.co/100x100/8B0000/FFFFFF?text=Bry',
            parentId: fruitsId,
          ),
        ],
      ),
      Category(
        id: meatId,
        name: 'Meat',
        imageUrl: 'https://placehold.co/100x100/FF0000/FFFFFF?text=M',
        subcategories: [
          Category(
            name: 'Beef', // Para 'Rinderfiletspitzen', 'Rinderfiletsteak'
            imageUrl: 'https://placehold.co/100x100/8B4513/FFFFFF?text=Beef',
            parentId: meatId,
          ),
          Category(
            name: 'Poultry',
            imageUrl: 'https://placehold.co/100x100/D2B48C/000000?text=Pltry',
            parentId: meatId,
          ),
        ],
      ),
      Category(
        id: drinksId,
        name: 'Drinks',
        imageUrl: 'https://placehold.co/100x100/87CEEB/000000?text=D',
        subcategories: [
          Category(
            name: 'Sodas', // Para 'Fritz-Kola', 'Coca Cola'
            imageUrl: 'https://placehold.co/100x100/000000/FFFFFF?text=Sod',
            parentId: drinksId,
          ),
          Category(
            name: 'Juices', // Para 'Bravo TL Lorem'
            imageUrl: 'https://placehold.co/100x100/FFEB3B/000000?text=Jce',
            parentId: drinksId,
          ),
          Category(
            name: 'Water',
            imageUrl: 'https://placehold.co/100x100/ADD8E6/000000?text=Wtr',
            parentId: drinksId,
          ),
        ],
      ),
      Category(
        id: dairyId,
        name: 'Dairy',
        imageUrl: 'https://placehold.co/100x100/F0E68C/000000?text=Da', // Cambiado el texto para diferenciar de Drinks
        subcategories: [
          Category(
            name: 'Milk',
            imageUrl: 'https://placehold.co/100x100/FFFFFF/000000?text=Milk',
            parentId: dairyId,
          ),
          Category(
            name: 'Cheese',
            imageUrl: 'https://placehold.co/100x100/FFA500/000000?text=Chse',
            parentId: dairyId,
          ),
          Category(
            name: 'Yogurt',
            imageUrl: 'https://placehold.co/100x100/F5F5DC/000000?text=Ygrt',
            parentId: dairyId,
          ),
        ],
      ),
      Category(
        id: bakeryId,
        name: 'Bakery',
        imageUrl: 'https://placehold.co/100x100/D2B48C/000000?text=B',
        subcategories: [
          Category(
            name: 'Bread',
            imageUrl: 'https://placehold.co/100x100/DEB887/000000?text=Brd',
            parentId: bakeryId,
          ),
          Category(
            name: 'Pastries',
            imageUrl: 'https://placehold.co/100x100/FFE4B5/000000?text=Pstry',
            parentId: bakeryId,
          ),
        ],
      ),
    ];
  }

 // Paso 3: Actualizar mockProducts para usar los IDs de las nuevas subcategorías
  static List<Product> get mockProducts {
    // Es crucial que los IDs de las categorías y subcategorías sean consistentes.
    // Para simplificar, obtendremos las categorías y subcategorías de la lista mockCategories reestructurada.

    final categoriesWithSubcategories = mockCategories;
    final Map<String, String> categoryMap = {};

    void extractCategoryIds(List<Category> cats, String? parentId) {
      for (var cat in cats) {
        categoryMap[cat.name] = cat.id; // Mapea el nombre de la categoría a su ID
        if (cat.subcategories != null) {
          extractCategoryIds(cat.subcategories!, cat.id);
        }
      }
    }
    extractCategoryIds(categoriesWithSubcategories, null);
    // Ahora categoryMap contendrá los IDs de todas las categorías y subcategorías por su nombre.
    // Ej: categoryMap['Tomatoes'] te dará el ID de la subcategoría 'Tomatoes'.

    return [
      Product(
        id: uuid.v4(),
        name: 'Red Tomatoes',
        description: 'Fresh red tomatoes, great for salads.',
        price: 3.24,
        imageUrl: 'https://placehold.co/150x150/FF6347/FFFFFF?text=Tomato1',
        unit: '300g (Pkt)',
        categoryId: categoryMap['Tomatoes']!, // Asegúrate que 'Tomatoes' existe en tu categoryMap
      ),
      Product(
        id: uuid.v4(),
        name: 'Cherry Tomatoes',
        description: 'Sweet cherry tomatoes, perfect for snacking.',
        price: 2.99,
        imageUrl: 'https://placehold.co/150x150/FFD700/000000?text=CherryT',
        unit: '250g (Pkt)',
        categoryId: categoryMap['Tomatoes']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Black Tomatoes',
        description: 'Unique black tomatoes, rich flavor.',
        price: 4.50,
        imageUrl: 'https://placehold.co/150x150/000000/FFFFFF?text=BlackT',
        unit: '250g (Pkt)',
        categoryId: categoryMap['Tomatoes']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Spanish VIP Tomatoes',
        description: 'Premium Spanish tomatoes.',
        price: 3.50,
        imageUrl: 'https://placehold.co/150x150/FF4500/FFFFFF?text=VIP_T',
        unit: '200g (Pkt)',
        categoryId: categoryMap['Tomatoes']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Fresh Broccoli',
        description: 'Healthy and fresh broccoli.',
        price: 4.00,
        discountedPrice: 3.40,
        imageUrl: 'https://placehold.co/150x150/4CAF50/FFFFFF?text=Broccoli',
        unit: '1kg',
        categoryId: categoryMap['Broccoli & Cauliflower']!, // Asignar a la nueva subcategoría
      ),
      Product(
        id: uuid.v4(),
        name: 'Organic Carrots',
        description: 'Sweet and crunchy organic carrots.',
        price: 2.50,
        discountedPrice: 2.00,
        imageUrl: 'https://placehold.co/150x150/FF8C00/FFFFFF?text=Carrots',
        unit: '1kg',
        categoryId: categoryMap['Root Vegetables']!, // Asignar a la nueva subcategoría
      ),
      Product(
        id: uuid.v4(),
        name: 'Red Peppers',
        description: 'Vibrant red peppers.',
        price: 2.80,
        discountedPrice: 2.30,
        imageUrl: 'https://placehold.co/150x150/FF5722/FFFFFF?text=RedPepper',
        unit: '230g (Pkt)',
        categoryId: categoryMap['Peppers']!, // Asignar a la nueva subcategoría
      ),
      Product(
        id: uuid.v4(),
        name: 'Fritz-Kola 0.25 L',
        description: 'Refreshing cola drink.',
        price: 1.25,
        discountedPrice: 0.95,
        imageUrl: 'https://placehold.co/150x150/000000/FFFFFF?text=FritzKola',
        unit: '0.25 L',
        categoryId: categoryMap['Sodas']!, // Asignar a la nueva subcategoría
      ),
      Product(
        id: uuid.v4(),
        name: 'Coca Cola 0.30 L',
        description: 'Classic Coca Cola.',
        price: 1.25,
        discountedPrice: 0.85,
        imageUrl: 'https://placehold.co/150x150/FF0000/FFFFFF?text=CocaCola',
        unit: '0.30 L',
        categoryId: categoryMap['Sodas']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Bravo TL Lorem',
        description: 'A refreshing fruit juice.',
        price: 1.80,
        discountedPrice: 1.60,
        imageUrl: 'https://placehold.co/150x150/FFEB3B/000000?text=Bravo',
        unit: '1 L',
        categoryId: categoryMap['Juices']!, // Asignar a la nueva subcategoría
      ),
      Product(
        id: uuid.v4(),
        name: 'Red Apple Text',
        description: 'Crisp red apples.',
        price: 1.35,
        discountedPrice: 1.25,
        imageUrl: 'https://placehold.co/150x150/FF0000/FFFFFF?text=RedApple',
        unit: '900g',
        categoryId: categoryMap['Apples']!, // Asignar a la nueva subcategoría
      ),
      Product(
        id: uuid.v4(),
        name: 'Yellow Apple Text',
        description: 'Sweet yellow apples.',
        price: 1.80,
        discountedPrice: 1.35,
        imageUrl: 'https://placehold.co/150x150/FFEB3B/000000?text=YellowApple',
        unit: '500g',
        categoryId: categoryMap['Apples']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Banana Text here',
        description: 'Fresh bananas.',
        price: 4.50,
        discountedPrice: 2.80,
        imageUrl: 'https://placehold.co/150x150/FFFF00/000000?text=Banana',
        unit: '500g',
        categoryId: categoryMap['Bananas']!, // Asignar a la nueva subcategoría
      ),
      Product(
        id: uuid.v4(),
        name: 'Rinderfiletspitzen',
        description: 'Premium beef tenderloin tips.',
        price: 5.40,
        discountedPrice: 4.90,
        imageUrl: 'https://placehold.co/150x150/8B4513/FFFFFF?text=BeefTips',
        unit: '400g',
        categoryId: categoryMap['Beef']!, // Asignar a la nueva subcategoría
      ),
      Product(
        id: uuid.v4(),
        name: 'Rinderfiletsteak',
        description: 'Juicy beef tenderloin steak.',
        price: 4.20,
        discountedPrice: 3.15,
        imageUrl: 'https://placehold.co/150x150/A0522D/FFFFFF?text=BeefSteak',
        unit: '200g',
        categoryId: categoryMap['Beef']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Rewe Bio Beeren',
        description: 'Organic berries.',
        price: 12.25,
        discountedPrice: 8.10,
        imageUrl: 'https://placehold.co/150x150/8B0000/FFFFFF?text=Berries',
        unit: '500g',
        categoryId: categoryMap['Berries']!, // Asignar a la nueva subcategoría
      ),
    ];
  }

static List<CartItem> get mockCartItems {
    final products = mockProducts;
    if (products.isEmpty) return []; // Guarda por si mockProducts está vacío temporalmente
    return [
      CartItem(
        productId: products[0].id, // Tomate Rojo
        name: products[0].name,
        imageUrl: products[0].imageUrl,
        price: products[0].price,
        unit: products[0].unit,
        quantity: 2,
      ),
      CartItem(
        productId: products[1].id, // Tomate Cherry
        name: products[1].name,
        imageUrl: products[1].imageUrl,
        price: products[1].price,
        unit: products[1].unit,
        quantity: 1,
      ),
      CartItem(
        productId: products[3].id, // Tomate VIP Español
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
    final products = mockProducts;
    if (products.length < 7) return []; // Guarda para evitar errores de índice

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
            productId: products[4].id, // Broccoli
            name: products[4].name,
            imageUrl: products[4].imageUrl,
            price: products[4].discountedPrice ?? products[4].price, // Usar precio con descuento si existe
            unit: products[4].unit,
            quantity: 2,
          ),
          CartItem(
            productId: products[6].id, // Pimiento Rojo
            name: products[6].name,
            imageUrl: products[6].imageUrl,
            price: products[6].discountedPrice ?? products[6].price, // Usar precio con descuento si existe
            unit: products[6].unit,
            quantity: 4,
          ),
        ],
        totalAmount: ( (products[4].discountedPrice ?? products[4].price) * 2) +
                     ( (products[6].discountedPrice ?? products[6].price) * 4),
        status: 'Processing',
        deliveryAddress: 'Avenida Siempre Viva 742, Springfield',
      ),
    ];
  }

  // Mock Recipes
  static List<Recipe> get mockRecipes => [
        Recipe(
          id: uuid.v4(),
          title: 'Spaghetti with Pesto and Tomatoes',
          description: 'A quick and delicious pasta dish.',
          imageUrl: 'https://placehold.co/150x150/8BC34A/FFFFFF?text=Recipe1',
          cookingTimeMinutes: 25,
          price: 5.90,
        ),
        Recipe(
          id: uuid.v4(),
          title: 'Avocado Toast with Poached Egg',
          description: 'Healthy breakfast or brunch option.',
          imageUrl: 'https://placehold.co/150x150/FFD700/000000?text=Recipe2',
          cookingTimeMinutes: 15,
          price: 8.45,
        ),
        Recipe(
          id: uuid.v4(),
          title: 'Chicken Curry',
          description: 'Spicy and flavorful chicken curry.',
          imageUrl: 'https://placehold.co/150x150/FF9800/FFFFFF?text=Recipe3',
          cookingTimeMinutes: 40,
          price: 12.30,
        ),
      ];

  // Mock Shops
  static List<Shop> get mockShops => [
        Shop(id: uuid.v4(), name: 'Rewe', logoUrl: 'https://placehold.co/100x50/FF0000/FFFFFF?text=Rewe'),
        Shop(id: uuid.v4(), name: 'Edeka', logoUrl: 'https://placehold.co/100x50/007AFF/FFFFFF?text=Edeka'),
        Shop(id: uuid.v4(), name: 'Lidl', logoUrl: 'https://placehold.co/100x50/00BFFF/FFFFFF?text=Lidl'),
        Shop(id: uuid.v4(), name: 'Aldi', logoUrl: 'https://placehold.co/100x50/00A86B/FFFFFF?text=Aldi'),
      ];
  // Mock User for display purposes   
  final mockUser = User(
    id: 'mock_user_id',
    email: 'admin.mock@example.com',
    appMetadata: const {},
    userMetadata: const {
        'display_name': 'Sarah', // Nombre mockeado
        'avatar_url': 'https://placehold.co/100x100/CCCCCC/000000?text=S', // Imagen de placeholder
    },
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
  );

}
