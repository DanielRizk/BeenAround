import 'package:flutter/material.dart';

import '../../../shared/ui_kit/app_scaffold.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Friends',
      child: Center(child: Text('Friends (placeholder)')),
    );
  }
}
