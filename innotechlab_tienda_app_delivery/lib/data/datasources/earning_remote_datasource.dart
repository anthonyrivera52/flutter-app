import 'package:delivery_app_mvvm/core/error/exceptions.dart';
import 'package:delivery_app_mvvm/model/earning_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class EarningRemoteDataSource {
  Future<List<EarningModel>> getEarnings(DateTime startDate, DateTime endDate);
  Future<List<DailyEarningModel>> getDailyEarnings(DateTime startDate, DateTime endDate);
}

class EarningRemoteDataSourceImpl implements EarningRemoteDataSource {
  final SupabaseClient supabaseClient;

  EarningRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<EarningModel>> getEarnings(DateTime startDate, DateTime endDate) async {
    try {
      final String userId = supabaseClient.auth.currentUser?.id ?? '';
      if (userId.isEmpty) {
        throw ServerException(message: 'User not authenticated.');
      }

      final response = await supabaseClient
          .from('earnings')
          .select()
          .eq('driver_id', userId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: true);

      if (response is List) {
        return response.map((json) => EarningModel.fromJson(json)).toList();
      } else {
        throw ServerException(message: 'Invalid response format for earnings.');
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<DailyEarningModel>> getDailyEarnings(DateTime startDate, DateTime endDate) async {
    try {
      final String userId = supabaseClient.auth.currentUser?.id ?? '';
      if (userId.isEmpty) {
        throw ServerException(message: 'User not authenticated.');
      }

      // This assumes you have a table named 'daily_earnings' or a view that aggregates this data.
      // For a more robust solution, you might perform an aggregation query directly in Supabase
      // or retrieve raw order data and process it in your application.
      final response = await supabaseClient
          .from('daily_earnings_view') // Or actual table 'daily_earnings'
          .select('date, amount')
          .eq('driver_id', userId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: true);

      if (response is List) {
        return response.map((json) => DailyEarningModel.fromJson(json)).toList();
      } else {
        throw const ServerException(message: 'Invalid response format for daily earnings.');
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}