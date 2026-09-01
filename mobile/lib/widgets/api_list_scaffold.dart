import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';

/// A reusable scaffold body for pages that fetch a list from the API.
///
/// Wraps the loading / error / empty states and exposes the data via a
/// [builder] that receives the loaded items.
class ApiListScaffold<T extends ChangeNotifier> extends StatefulWidget {
  final T provider;
  final Future<void> Function() onRefresh;
  final List<dynamic> Function(T) itemsGetter;
  final Widget Function(BuildContext, List<dynamic>) itemBuilder;
  final String emptyMessage;
  final EdgeInsets padding;

  const ApiListScaffold({
    super.key,
    required this.provider,
    required this.onRefresh,
    required this.itemsGetter,
    required this.itemBuilder,
    this.emptyMessage = 'No items found',
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<ApiListScaffold<T>> createState() => _ApiListScaffoldState<T>();
}

class _ApiListScaffoldState<T extends ChangeNotifier> extends State<ApiListScaffold<T>> {
  @override
  void initState() {
    super.initState();
    // Fetch data on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(
      builder: (context, provider, child) {
        final loading = (provider as dynamic).loading as bool;
        final error = (provider as dynamic).error as String?;
        final items = widget.itemsGetter(provider);

        if (loading && items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (error != null && items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: DomendraTheme.danger),
                  const SizedBox(height: 16),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: DomendraTheme.onSurfaceMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: widget.onRefresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    widget.emptyMessage,
                    style: const TextStyle(color: DomendraTheme.onSurfaceMuted, fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: ListView.builder(
            padding: widget.padding,
            itemCount: items.length + (loading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return widget.itemBuilder(context, items);
            },
          ),
        );
      },
    );
  }
}
