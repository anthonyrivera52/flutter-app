// lib/service/real_location_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:delivery_app_mvvm/model/location_data.dart';
import 'package:delivery_app_mvvm/service/location_service.dart';
import 'package:flutter/material.dart'; // Para debugPrint

class RealLocationService implements LocationService {
  StreamController<LocationData>? _locationController;
  StreamSubscription<Position>? _positionSubscription;

  RealLocationService() {
    _locationController = StreamController<LocationData>.broadcast();
    _initLocationStream();
  }

  Future<void> _initLocationStream() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _locationController!.addError('Los servicios de ubicación están deshabilitados.');
      debugPrint('RealLocationService: Los servicios de ubicación están deshabilitados.');
      return Future.error('Los servicios de ubicación están deshabilitados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _locationController!.addError('Los permisos de ubicación fueron denegados.');
        debugPrint('RealLocationService: Los permisos de ubicación fueron denegados.');
        return Future.error('Los permisos de ubicación fueron denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _locationController!.addError('Los permisos de ubicación fueron denegados permanentemente.');
      debugPrint('RealLocationService: Los permisos de ubicación fueron denegados permanentemente.');
      return Future.error('Los permisos de ubicación fueron denegados permanentemente, no podemos solicitar permisos.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualiza cada 10 metros de cambio de posición
      ),
    ).listen((Position position) {
      _locationController!.add(LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
      ));
      // debugPrint('RealLocationService: Ubicación emitida: Lat ${position.latitude}, Lon ${position.longitude}');
    }, onError: (e) {
      _locationController!.addError('Error en el stream de Geolocator: $e');
      debugPrint('RealLocationService: Error en el stream de Geolocator: $e');
    });
  }

  @override
  Future<LocationData> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Los servicios de ubicación están deshabilitados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Los permisos de ubicación fueron denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Los permisos de ubicación fueron denegados permanentemente, no podemos solicitar permisos.');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
    );
  }

  @override
  Stream<LocationData> getLocationStream() {
    return _locationController!.stream;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _locationController?.close();
    debugPrint('RealLocationService: Recursos liberados.');
  }
}