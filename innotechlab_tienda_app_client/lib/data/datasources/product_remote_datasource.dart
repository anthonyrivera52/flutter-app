import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_tienda/core/errors/exceptions.dart';
import 'package:mi_tienda/data/models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getAllProducts();
  Future<ProductModel> getProductById(String id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final SupabaseClient supabaseClient;

  ProductRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await supabaseClient.from('products').select().order('name', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      final List<dynamic> productsJson = response as List<dynamic>;
      return productsJson.map((json) => ProductModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw ServerException('Error al obtener productos: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al obtener productos: $e');
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await supabaseClient.from('products').select().eq('id', id).single();

      if (response.isEmpty) {
        throw ServerException('Producto no encontrado con ID: $id');
      }

      return ProductModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException('Error al obtener producto por ID: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al obtener producto: $e');
    }
  }
}
