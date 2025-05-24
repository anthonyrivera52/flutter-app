import 'package:flutter_app/core/constants/flavors.dart';
import 'package:flutter_app/core/constants/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class SupabaseService {
  static Future<void> init(Flavor flavor) async {
    late String url;
    late String anonKey;

    switch (flavor) {
      case Flavor.CLIENT:
        url = SupabaseKeys.clientUrl;
        anonKey = SupabaseKeys.clientAnonKey;
        break;
      case Flavor.DELIVERY:
        url = SupabaseKeys.deliveryUrl;
        anonKey = SupabaseKeys.deliveryAnonKey;
        break;
      case Flavor.ADMIN:
        url = SupabaseKeys.adminUrl;
        anonKey = SupabaseKeys.adminAnonKey;
        break;
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
