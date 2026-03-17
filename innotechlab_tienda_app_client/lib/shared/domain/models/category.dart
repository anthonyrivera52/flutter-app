import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

class Category {
  final String id;
  final String name;
  final String? imageUrl;
  final List<Category>? subcategories;
  final String? parentId;

  Category({
    String? id,
    required this.name,
    this.imageUrl,
    this.subcategories,
    this.parentId,
  }) : id = id ?? _uuid.v4();

  Category copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<Category>? subcategories,
    String? parentId,
    bool clearSubcategories = false,
    bool clearImageUrl = false,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      subcategories:
          clearSubcategories ? null : (subcategories ?? this.subcategories),
      parentId: parentId ?? this.parentId,
    );
  }
}
