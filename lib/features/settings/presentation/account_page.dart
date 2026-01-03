import 'package:flutter/material.dart';

import '../../../shared/i18n/app_strings.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.t(context, 'settings_account'))),
      body: const Center(
        child: Text(
          'Account page (placeholder)\n\n'
              'Later: login, sync, cloud backup, etc.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
