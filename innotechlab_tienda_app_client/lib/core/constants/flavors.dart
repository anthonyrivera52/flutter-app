enum Flavor {
  ADMIN,
  CLIENT,
  DELIVERY,
}

class F {
  static Flavor? appFlavor;

  static String get title {
    switch (appFlavor) {
      case Flavor.ADMIN:
        return 'App Admin';
      case Flavor.CLIENT:
        return 'App Client';
      case Flavor.DELIVERY:
        return 'App Delivery';
      default:
        return 'App';
    }
  }

  static String get role {
    switch (appFlavor) {
      case Flavor.ADMIN:
        return 'admin';
      case Flavor.CLIENT:
        return 'client';
      case Flavor.DELIVERY:
        return 'delivery';
      default:
        return 'unknown';
    }
  }
}