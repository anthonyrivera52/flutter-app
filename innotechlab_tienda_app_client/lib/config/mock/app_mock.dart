import 'package:flutter_app/domain/entities/cartItem.dart';
import 'package:flutter_app/domain/entities/category.dart';
import 'package:flutter_app/domain/entities/order.dart';
import 'package:flutter_app/domain/entities/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Para generar IDs únicos

// Instancia de Uuid para generar IDs
const Uuid uuid = Uuid();

/// Provides mock data for the grocery application.
class MockData {
  // IDs especiales para categorías
  static final String allProductsCategoryId = 'all_products_category_id';
  static final String discountedProductsCategoryId = 'discounted_products_category_id';

  // IDs para categorías principales
  static final String vegetablesId = 'vegetables_category_id';
  static final String fruitsId = 'fruits_category_id';
  static final String meatId = 'meat_category_id';
  static final String drinksId = 'drinks_category_id';
  static final String dairyId = 'dairy_category_id';
  static final String bakeryId = 'bakery_category_id';

  // IDs para subcategorías
  static final String tomatoesId = 'tomatoes_subcategory_id';
  static final String leafyGreensId = 'leafy_greens_subcategory_id';
  static final String rootVegetablesId = 'root_vegetables_subcategory_id';
  static final String peppersId = 'peppers_subcategory_id';
  static final String broccoliCauliflowerId = 'broccoli_cauliflower_subcategory_id';
  static final String applesId = 'apples_subcategory_id';
  static final String bananasId = 'bananas_subcategory_id';
  static final String berriesId = 'berries_subcategory_id';
  static final String beefId = 'beef_subcategory_id';
  static final String poultryId = 'poultry_subcategory_id';
  static final String sodasId = 'sodas_subcategory_id';
  static final String juicesId = 'juices_subcategory_id';
  static final String waterId = 'water_subcategory_id';
  static final String milkId = 'milk_subcategory_id';
  static final String cheeseId = 'cheese_subcategory_id';
  static final String yogurtId = 'yogurt_subcategory_id';
  static final String breadId = 'bread_subcategory_id';
  static final String pastriesId = 'pastries_subcategory_id';

  // Initialize mockCategories once
  static final List<Category> mockCategories = _initMockCategories();

  static List<Category> _initMockCategories() {
    return [
      Category(id: allProductsCategoryId, name: 'All Products', imageUrl: 'https://placehold.co/100x100/CCCCCC/000000?text=All'),
      Category(
        id: vegetablesId,
        name: 'Vegetables',
        imageUrl: 'https://placehold.co/100x100/A7D9B1/000000?text=V',
        subcategories: [
          Category(
            id: tomatoesId,
            name: 'Tomatoes',
            imageUrl: 'https://placehold.co/100x100/FF6347/FFFFFF?text=T',
            parentId: vegetablesId,
          ),
          Category(
            id: leafyGreensId,
            name: 'Leafy Greens',
            imageUrl: 'https://placehold.co/100x100/38761D/FFFFFF?text=LG',
            parentId: vegetablesId,
          ),
          Category(
            id: rootVegetablesId,
            name: 'Root Vegetables',
            imageUrl: 'https://placehold.co/100x100/B45F06/FFFFFF?text=RV',
            parentId: vegetablesId,
          ),
          Category(
            id: peppersId,
            name: 'Peppers',
            imageUrl: 'https://placehold.co/100x100/FF5722/FFFFFF?text=P',
            parentId: vegetablesId,
          ),
          Category(
            id: broccoliCauliflowerId,
            name: 'Broccoli & Cauliflower',
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
            id: applesId,
            name: 'Apples',
            imageUrl: 'https://placehold.co/100x100/FF0000/FFFFFF?text=Apls',
            parentId: fruitsId,
          ),
          Category(
            id: bananasId,
            name: 'Bananas',
            imageUrl: 'https://placehold.co/100x100/FFFF00/000000?text=Bana',
            parentId: fruitsId,
          ),
          Category(
            id: berriesId,
            name: 'Berries',
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
            id: beefId,
            name: 'Beef',
            imageUrl: 'https://placehold.co/100x100/8B4513/FFFFFF?text=Beef',
            parentId: meatId,
          ),
          Category(
            id: poultryId,
            name: 'Poultry',
            imageUrl: 'https://placehold.co/100x100/D2B48C/000000?text=Pltry',
            parentId: meatId,
          ),
        ],
      ),
      Category(
        id: drinksId,
        name: 'Drinks',
        imageUrl: 'https://placehold.co/100x100/87CEEB/000000?text=Beer',
        subcategories: [
          Category(
            id: sodasId,
            name: 'Sodas',
            imageUrl: 'https://placehold.co/100x100/000000/FFFFFF?text=Sod',
            parentId: drinksId,
          ),
          Category(
            id: juicesId,
            name: 'Juices',
            imageUrl: 'https://placehold.co/100x100/FFEB3B/000000?text=Juice',
            parentId: drinksId,
          ),
          Category(
            id: waterId,
            name: 'Water',
            imageUrl: 'https://placehold.co/100x100/ADD8E6/000000?text=Wtr',
            parentId: drinksId,
          ),
        ],
      ),
      Category(
        id: dairyId,
        name: 'Dairy',
        imageUrl: 'https://placehold.co/100x100/F0E68C/000000?text=Da',
        subcategories: [
          Category(
            id: milkId,
            name: 'Milk',
            imageUrl: 'https://placehold.co/100x100/FFFFFF/000000?text=Milk',
            parentId: dairyId,
          ),
          Category(
            id: cheeseId,
            name: 'Cheese',
            imageUrl: 'https://placehold.co/100x100/FFA500/000000?text=Chse',
            parentId: dairyId,
          ),
          Category(
            id: yogurtId,
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
            id: breadId,
            name: 'Bread',
            imageUrl: 'https://placehold.co/100x100/DEB887/000000?text=Brd',
            parentId: bakeryId,
          ),
          Category(
            id: pastriesId,
            name: 'Pastries',
            imageUrl: 'https://placehold.co/100x100/FFE4B5/000000?text=Pstry',
            parentId: bakeryId,
          ),
        ],
      ),
    ];
  }

  // Initialize mockProducts once
  static final List<Product> mockProducts = _initMockProducts();

  static List<Product> _initMockProducts() {
    final categoriesWithSubcategories = mockCategories;
    final Map<String, String> categoryMap = {};

    void extractCategoryIds(List<Category> cats, String? parentId) {
      for (var cat in cats) {
        categoryMap[cat.name] = cat.id;
        if (cat.subcategories != null) {
          extractCategoryIds(cat.subcategories!, cat.id);
        }
      }
    }
    extractCategoryIds(categoriesWithSubcategories, null);
    // print('Category Map: $categoryMap'); // Debug: You can keep this if needed for development

    return [
      Product(
        id: uuid.v4(),
        name: 'Red Tomatoes',
        description: 'Fresh red tomatoes, great for salads.',
        price: 3.24,
        imageUrl: 'https://placehold.co/150x150/FF6347/FFFFFF?text=Tomato1',
        unit: '300g (Pkt)',
        categoryId: categoryMap['Tomatoes']!,
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
        description: 'Healthy hot broccoli.',
        price: 25.00,
        discountedPrice: 20.00,
        imageUrl: 'https://placehold.co/150x150/4CAF50/FFFFFF?text=Broccoli',
        unit: 'Broccoli',
        categoryId: categoryMap['Broccoli & Cauliflower']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Organic Carrots',
        description: 'Sweet and crunchy carrots.',
        price: 2.50,
        discountedPrice: 2.00,
        imageUrl: 'https://placehold.co/150x150/FF8C00/FFFFFF?text=Carrots',
        unit: '1kg',
        categoryId: categoryMap['Root Vegetables']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Red Peppers',
        description: 'Vibrant red peppers.',
        price: 2.80,
        discountedPrice: 2.30,
        imageUrl: 'https://placehold.co/150x150/FF5722/FFFFFF?text=RedPepper',
        unit: '230g (Packet)',
        categoryId: categoryMap['Peppers']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Fritz-Kola 0.25 L',
        description: 'Refreshing cola drink.',
        price: 1.25,
        discountedPrice: 0.95,
        imageUrl: 'https://placehold.co/150x150/000000/FFFFFF?text=FritzKola',
        unit: '0.25 L',
        categoryId: categoryMap['Sodas']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Coca Cola 0.33 L',
        description: 'Classic Coca Cola.',
        price: 1.25,
        discountedPrice: 0.85,
        imageUrl: 'https://placehold.co/150x150/FF000/FFFFFF?text=CocaCola',
        unit: '0.33 L',
        categoryId: categoryMap['Sodas']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Bravo TL Lorem',
        description: 'A refreshing fruit juice.',
        price: 1.80,
        imageUrl: 'https://placehold.co/150x150/FFEB3B/000000?text=Bravo',
        unit: '1 L',
        categoryId: categoryMap['Juices']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Red Apple Text',
        description: 'Crisp red apples.',
        price: 1.35,
        discountedPrice: 1.25,
        imageUrl: 'https://placehold.co/150x150/FF0000/FFFFFF?text=RedApple',
        unit: '900g',
        categoryId: categoryMap['Apples']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Yellow Apple',
        description: 'Sweet yellow apples.',
        price: 1.80,
        discountedPrice: 1.35,
        imageUrl: 'https://placehold.co/150x150/FFEB3B/000000?text=YellowApple',
        unit: '500g',
        categoryId: categoryMap['Apples']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Banana Text',
        description: 'Fresh bananas.',
        price: 4.50,
        discountedPrice: 4.80,
        imageUrl: 'https://placehold.co/150x150/FFFF00/000000?text=Banana',
        unit: '500g',
        categoryId: categoryMap['Bananas']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Rinderfiletspitzen',
        description: 'Premium beef tenderloin tips.',
        price: 5.45,
        discountedPrice: 4.90,
        imageUrl: 'https://placehold.co/150x150/8B4513/000000?text=TBeef',
        unit: '400g',
        categoryId: categoryMap['Beef']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Rinderfiletsteak',
        description: 'Juicy beef tenderloin steak.',
        price: 4.20,
        discountedPrice: 3.15,
        imageUrl: 'https://placehold.co/150/150/A0522D/D',
        unit: '200g',
        categoryId: categoryMap['Beef']!,
      ),
      Product(
        id: uuid.v4(),
        name: 'Rewe Bio Beeren',
        description: 'Organic berries.',
        price: 12.25,
        discountedPrice: 8.10,
        imageUrl: 'https://placehold.co/150x150/8B0080/FFFFFF?text=Berries',
        unit: '500g',
        categoryId: categoryMap['Berries']!,
      ),
    ];
  }

  // Initialize mockCartItems once
  static final List<CartItem> mockCartItems = _initMockCartItems();

  static List<CartItem> _initMockCartItems() {
    final products = mockProducts; // Use the already initialized mockProducts
    if (products.isEmpty) return [];
    return [
      CartItem(
        productId: products[0].id, // Red Tomatoes
        name: products[0].name,
        imageUrl: products[0].imageUrl,
        price: products[0].price,
        unit: products[0].unit,
        quantity: 2,
      ),
      CartItem(
        productId: products[1].id, // Cherry Tomatoes
        name: products[1].name,
        imageUrl: products[1].imageUrl,
        price: products[1].price,
        unit: products[1].unit,
        quantity: 1,
      ),
      CartItem(
        productId: products[3].id, // Spanish VIP Tomatoes
        name: products[3].name,
        imageUrl: products[3].imageUrl,
        price: products[3].price,
        unit: products[3].unit,
        quantity: 3,
      ),
    ];
  }

  // Initialize mockOrders once
  static final List<Order> mockOrders = _initMockOrders();

  static List<Order> _initMockOrders() {
    final cartItems = mockCartItems; // Use the already initialized mockCartItems
    final products = mockProducts; // Use the already initialized mockProducts
    if (products.length < 7) return [];
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
            price: products[4].discountedPrice ?? products[4].price,
            unit: products[4].unit,
            quantity: 2,
          ),
          CartItem(
            productId: products[6].id, // Red Peppers
            name: products[6].name,
            imageUrl: products[6].imageUrl,
            price: products[6].discountedPrice ?? products[6].price,
            unit: products[6].unit,
            quantity: 4,
          ),
        ],
        totalAmount: ((products[4].discountedPrice ?? products[4].price) * 2) +
                     ((products[6].discountedPrice ?? products[6].price) * 4),
        status: 'Processing',
        deliveryAddress: 'Avenida Siempre Viva 742, Springfield',
      ),
    ];
  }

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