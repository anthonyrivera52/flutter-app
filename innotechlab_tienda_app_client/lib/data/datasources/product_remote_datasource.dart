import 'package:mi_tienda/data/models/product_moles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      if (response == null) {
        throw ServerException('No products found.');
      }
      return (response as List).map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await supabaseClient.from('products').select().eq('id', id).single();
      if (response == null) {
        throw ServerException('Product with ID $id not found.');
      }
      return ProductModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}