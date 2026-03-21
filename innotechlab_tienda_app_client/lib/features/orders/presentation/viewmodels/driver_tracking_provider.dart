import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final driverTrackingProvider = StreamProvider.autoDispose
    .family<LatLng, String>((ref, driverId) {
      final supabase = Supabase.instance.client;
      final channelName = 'driver:$driverId';
      final channel = supabase.channel(channelName);

      final controller = StreamController<LatLng>();

      channel
          .onBroadcast(
            event: 'location_update',
            callback: (payload) {
              final data = payload as Map<String, dynamic>?;
              if (data != null) {
                final lat = (data['lat'] as num?)?.toDouble();
                final lng = (data['lng'] as num?)?.toDouble();
                if (lat != null && lng != null) {
                  controller.add(LatLng(lat, lng));
                }
              }
            },
          )
          .subscribe();

      ref.onDispose(() {
        supabase.removeChannel(channel);
        controller.close();
      });

      return controller.stream;
    });
