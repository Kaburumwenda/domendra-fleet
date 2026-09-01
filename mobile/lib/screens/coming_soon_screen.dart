import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/app_drawer.dart';

/// Generic placeholder screen for routes that don't have a full implementation yet.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String route;

  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.route,
    this.icon = Icons.construction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(title),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
      ),
      drawer: AppDrawer(currentRoute: route),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: DomendraTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 40, color: DomendraTheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: DomendraTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This screen is being built. Check back soon!',
              style: TextStyle(fontSize: 14, color: DomendraTheme.onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }
}
