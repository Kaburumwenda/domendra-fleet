/// Central configuration for the DomendraFleet mobile app.
class AppConfig {
  /// Base URL for the Django REST API.
  /// When running on an Android emulator use 10.0.2.2 (maps to host localhost).
  /// When running on a physical device use the machine's LAN IP.
  static const String apiBase = 'http://10.0.2.2:8000/api';

  /// App display name
  static const String appName = 'DomendraFleet';

  /// Default tenant schema for login
  static const String defaultTenant = 'acme';

  /// Google Maps API key (from backend `.env` → `GOOGLE_MAPS_API_KEY`).
  ///
  /// Used by the Vehicle Location Map widget and geocoding helpers.
  /// On Android this must also be added to `android/app/src/main/AndroidManifest.xml`
  /// inside `<application>` as:
  ///   <meta-data
  ///     android:name="com.google.android.geo.API_KEY"
  ///     android:value="AIzaSyAhiNO62geg58-WaLGeq235Lo8gySLvs_I" />
  static const String googleMapsApiKey = 'AIzaSyAhiNO62geg58-WaLGeq235Lo8gySLvs_I';
}
