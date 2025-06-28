import 'package:delivery_app_mvvm/model/location_data.dart';

abstract class LocationService {
  // Obtiene la ubicación actual una sola vez
  Future<LocationData> getCurrentLocation();

  // Emite actualizaciones de ubicación de forma continua
  Stream<LocationData> getLocationStream();

}