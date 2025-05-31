import 'package:equatable/equatable.dart';

class Shop extends Equatable {
  final String id;
  final String name;
  final String logoUrl;

  const Shop({
    required this.id,
    required this.name,
    required this.logoUrl,
  });

  Shop copyWith({
    String? id,
    String? name,
    String? logoUrl,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  @override
  List<Object> get props => [id, name, logoUrl];
}