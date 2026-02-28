import 'package:flutter/material.dart';
import 'app_appbar.dart';
import 'app_background.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // background handled by LivingBackground
      body: LivingBackground(
        child: Column(
          children: [
            PremiumAppBar(title: title),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}