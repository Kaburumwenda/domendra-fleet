import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/data_providers.dart';
import 'providers/vehicle_provider.dart';
import 'providers/equipment_provider.dart';
import 'providers/lessor_provider.dart';
import 'providers/tire_provider.dart';
import 'providers/battery_provider.dart';
import 'providers/issues_provider.dart';
import 'providers/services_provider.dart';
import 'providers/reminders_provider.dart';
import 'providers/inspections_provider.dart';
import 'providers/garage_provider.dart';
import 'providers/recalls_provider.dart';
import 'providers/fuel_provider.dart';
import 'providers/ifta_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/telematics_provider.dart';
import 'providers/dispatch_provider.dart';
import 'providers/accidents_provider.dart';
import 'providers/driver_hire_rates_provider.dart';
import 'providers/invoices_provider.dart';
import 'providers/billing_provider.dart';
import 'providers/expenses_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/drivers_provider.dart';
import 'providers/documents_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/vehicles_screen.dart';
import 'screens/vehicle_form_screen.dart';
import 'screens/vehicle_detail_screen.dart';
import 'screens/rentals_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/drivers_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/assets/equipments/equipment_screen.dart';
import 'screens/assets/lessors/lessors_screen.dart';
import 'screens/assets/tires/tires_screen.dart';
import 'screens/assets/batteries/batteries_screen.dart';
import 'screens/maintenance/issues/issues_screen.dart';
import 'screens/maintenance/issues/work_orders_screen.dart';
import 'screens/maintenance/services/services_screen.dart';
import 'screens/maintenance/reminders/reminders_screen.dart';
import 'screens/maintenance/inspections/inspections_screen.dart';
import 'screens/maintenance/garage/garage_screen.dart';
import 'screens/maintenance/recalls/recalls_screen.dart';
import 'screens/fuel/fuel_screen.dart';
import 'screens/ifta/ifta_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/analytics/vehicle_analytics_screen.dart';
import 'screens/analytics/fuel_energy_analytics_screen.dart';
import 'screens/analytics/rental_analytics_screen.dart';
import 'screens/operations/telematics_screen.dart';
import 'screens/operations/locations_screen.dart';
import 'screens/operations/dispatch_screen.dart';
import 'screens/operations/accidents_screen.dart';
import 'screens/operations/driver_hire_rates_screen.dart';
import 'screens/operations/invoices_screen.dart';
import 'screens/billing/billing_screen.dart';
import 'screens/expenses/expenses_screen.dart';
import 'screens/coming_soon_screen.dart';
import 'models/nav_model.dart';

void main() {
  runApp(const DomendraApp());
}

class DomendraApp extends StatelessWidget {
  const DomendraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => VehiclesProvider()),
        ChangeNotifierProvider(create: (_) => RentalsProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => EquipmentProvider()),
        ChangeNotifierProvider(create: (_) => LessorProvider()),
        ChangeNotifierProvider(create: (_) => TireProvider()),
        ChangeNotifierProvider(create: (_) => BatteryProvider()),
        ChangeNotifierProvider(create: (_) => IssuesProvider()),
        ChangeNotifierProvider(create: (_) => ServicesProvider()),
        ChangeNotifierProvider(create: (_) => RemindersProvider()),
        ChangeNotifierProvider(create: (_) => InspectionsProvider()),
        ChangeNotifierProvider(create: (_) => GarageProvider()),
        ChangeNotifierProvider(create: (_) => RecallsProvider()),
        ChangeNotifierProvider(create: (_) => FuelProvider()),
        ChangeNotifierProvider(create: (_) => IftaProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => TelematicsProvider()),
        ChangeNotifierProvider(create: (_) => DispatchProvider()),
        ChangeNotifierProvider(create: (_) => AccidentsProvider()),
        ChangeNotifierProvider(create: (_) => DriverHireRatesProvider()),
        ChangeNotifierProvider(create: (_) => InvoicesProvider()),
        ChangeNotifierProvider(create: (_) => BillingProvider()),
        ChangeNotifierProvider(create: (_) => ExpensesProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => DriversProvider()),
        ChangeNotifierProvider(create: (_) => DocumentsProvider()),
      ],
      child: MaterialApp(
        title: 'DomendraFleet',
        debugShowCheckedModeBanner: false,
        theme: DomendraTheme.light(),
        darkTheme: DomendraTheme.dark(),
        home: const _SplashGate(),
        routes: _buildRoutes(),
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  /// Builds the named-route table — the primary nav destinations have their
  /// own screens, everything else falls back to [ComingSoonScreen].
  Map<String, WidgetBuilder> _buildRoutes() {
    final routes = <String, WidgetBuilder>{
      '/login': (_) => const LoginScreen(),
      '/app': (_) => const DashboardScreen(),
      '/dashboard': (_) => const DashboardScreen(),
      '/app/vehicles': (_) => const VehiclesScreen(),
      '/vehicles': (_) => const VehiclesScreen(),
      '/equipment': (_) => const EquipmentScreen(),
      '/lessors': (_) => const LessorsScreen(),
      '/tires': (_) => const TiresScreen(),
      '/batteries': (_) => const BatteriesScreen(),
      '/issues': (_) => const IssuesScreen(),
      '/work-orders': (_) => const WorkOrdersScreen(),
      '/services': (_) => const ServicesScreen(),
      '/reminders': (_) => const RemindersScreen(),
      '/inspections': (_) => const InspectionsScreen(),
      '/garage': (_) => const GarageScreen(),
      '/recalls': (_) => const RecallsScreen(),
      '/fuel': (_) => const FuelScreen(),
      '/ifta': (_) => const IftaScreen(),
      '/rentals': (_) => const RentalsScreen(),
      '/reports': (_) => const ReportsScreen(),
      '/analytics/vehicles': (_) => const VehicleAnalyticsScreen(),
      '/analytics/fuel-energy': (_) => const FuelEnergyAnalyticsScreen(),
      '/analytics/rentals': (_) => const RentalAnalyticsScreen(),
      '/telematics': (_) => const TelematicsScreen(),
      '/locations': (_) => const LocationsScreen(),
      '/dispatch': (_) => const DispatchScreen(),
      '/driver-hire-rates': (_) => const DriverHireRatesScreen(),
      '/accidents': (_) => const AccidentsScreen(),
      '/invoices': (_) => const InvoicesScreen(),
      '/billing': (_) => const BillingScreen(),
      '/expenses': (_) => const ExpensesScreen(),
      '/contacts': (_) => const ContactsScreen(),
      '/drivers': (_) => const DriversScreen(),
      '/documents': (_) => const DocumentsScreen(),
    };

    // All other nav items → ComingSoon placeholder with appropriate icon.
    for (final item in NavModel.flat) {
      final route = item.route;
      if (route == null) continue;
      if (!routes.containsKey(route)) {
        routes[route] = (_) => ComingSoonScreen(
              title: item.label,
              icon: item.icon,
              route: route,
            );
      }
    }
    return routes;
  }

  /// Handles dynamic routes like `/vehicles/new`, `/vehicles/:id`, `/vehicles/:id/edit`.
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final segments = uri.pathSegments;

    // /app/vehicles/new → VehicleFormScreen (create)
    // /app/vehicles/:id → VehicleDetailScreen (view)
    // /app/vehicles/:id/edit → VehicleFormScreen (edit)
    // Legacy /vehicles/* routes are also supported.
    final first = segments.isNotEmpty ? segments.first : '';
    final vehicleSegments = first == 'app' && segments.length > 1 && segments[1] == 'vehicles'
        ? segments.sublist(1)
        : (first == 'vehicles' ? segments : []);
    if (vehicleSegments.isNotEmpty && vehicleSegments.first == 'vehicles') {
      if (vehicleSegments.length == 1) return null; // handled by static route
      if (vehicleSegments.length == 2 && vehicleSegments[1] == 'new') {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const VehicleFormScreen(),
        );
      }
      if (vehicleSegments.length == 2) {
        final id = int.tryParse(vehicleSegments[1]);
        if (id != null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => VehicleDetailScreen(vehicleId: id),
          );
        }
      }
      if (vehicleSegments.length == 3 && vehicleSegments[2] == 'edit') {
        final id = int.tryParse(vehicleSegments[1]);
        if (id != null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => VehicleFormScreen(vehicleId: id),
          );
        }
      }
    }
    return null;
  }
}

/// Splash / auth gate — shows a loading spinner while session is restored,
/// then routes to login or dashboard.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final auth = context.read<AuthProvider>();
    await auth.restore();
    if (mounted) setState(() => _initialised = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialised) {
      return Scaffold(
        backgroundColor: DomendraTheme.scaffoldBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  gradient: DomendraTheme.heroGradient,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'Domendra',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: DomendraTheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: DomendraTheme.primary),
            ],
          ),
        ),
      );
    }

    final auth = context.watch<AuthProvider>();
    return auth.isAuthenticated ? const DashboardScreen() : const LoginScreen();

  }
}
