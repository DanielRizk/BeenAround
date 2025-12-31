import 'package:flutter/material.dart';
import '../../shared/widgets/home_shell.dart';
import '../../core/visited/visited_countries_store.dart';

void main() {
  runApp(const BeenAroundApp());
}

class BeenAroundApp extends StatefulWidget {
  const BeenAroundApp({super.key});

  @override
  State<BeenAroundApp> createState() => _MyAppState();
}

class _MyAppState extends State<BeenAroundApp> {
  final visitedStore = VisitedCountriesStore();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: visitedStore,
      builder: (context, _) {
        return VisitedCountriesProvider(
          store: visitedStore,
          child: MaterialApp(
            home: const HomeShell(),
          ),
        );
      },
    );
  }
}

/// Tiny InheritedWidget provider (so we don’t need provider package)
class VisitedCountriesProvider extends InheritedWidget {
  final VisitedCountriesStore store;

  const VisitedCountriesProvider({
    super.key,
    required this.store,
    required super.child,
  });

  static VisitedCountriesStore of(BuildContext context) {
    final p = context.dependOnInheritedWidgetOfExactType<VisitedCountriesProvider>();
    assert(p != null, 'VisitedCountriesProvider not found above in the tree.');
    return p!.store;
  }

  @override
  bool updateShouldNotify(covariant VisitedCountriesProvider oldWidget) {
    return oldWidget.store != store;
  }
}
