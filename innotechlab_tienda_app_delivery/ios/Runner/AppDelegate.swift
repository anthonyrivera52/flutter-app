import Flutter
import UIKit
import GoogleMaps
import flutter_local_notifications // <-- Añade esta importación

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDrWqz0DKgTxKGqkVolbfme9mPsNfPB2R8")
    GeneratedPluginRegistrant.register(with: self)
    // IMPORTANTE: Registra el manejador de notificaciones en segundo plano
    // Esto permite que tu app responda a taps de notificaciones cuando está cerrada.
    // FlutterLocalNotificationsPlugin.setMethodCallHandler(_flutterLocalNotificationsPluginHandleMethodCall); // Esta línea es un ejemplo, no la añadas si no sabes qué hace.
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
