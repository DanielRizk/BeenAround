import 'package:flutter/material.dart';

import '../../../shared/backend/auth_controller.dart';
import '../../../shared/ui_kit/app_cards.dart';
import '../../../shared/ui_kit/app_dialogs.dart';
import '../../../shared/ui_kit/app_scaffold.dart';

class MyDataPage extends StatelessWidget {
  final Future<void> Function() onResetAll;

  const MyDataPage({
    super.key,
    required this.onResetAll,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthController.currentUser;

    if (user == null) {
      return const AppScaffold(
        title: 'My Data',
        child: Center(child: Text('Not logged in')),
      );
    }

    return AppScaffold(
      title: 'My Data',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          SectionCard(
            title: 'Profile',
            child: Column(
              children: [
                MotionTile(
                  icon: Icons.badge_outlined,
                  title: 'First name',
                  subtitle: user.firstName,
                  showChevron: false,
                  onTap: () {},
                ),
                const SoftDivider(),
                MotionTile(
                  icon: Icons.badge_outlined,
                  title: 'Last name',
                  subtitle: user.lastName,
                  showChevron: false,
                  onTap: () {},
                ),
                const SoftDivider(),
                MotionTile(
                  icon: Icons.alternate_email_rounded,
                  title: 'Username',
                  subtitle: user.username,
                  showChevron: false,
                  onTap: () {},
                ),
                const SoftDivider(),
                MotionTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: user.email,
                  showChevron: false,
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SectionCard(
            title: 'Security',
            child: Column(
              children: [
                MotionTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change password',
                  subtitle: 'Coming soon',
                  showChevron: false, // interactive later, but not a subpage
                  onTap: () {
                    // TODO: implement change password flow
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SectionCard(
            title: 'Danger zone',
            tone: CardTone.danger,
            child: Column(
              children: [
                MotionTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete account',
                  subtitle:
                  'Permanently delete your account.',
                  tone: TileTone.danger,
                  showChevron: false, // destructive action, not navigation
                  onTap: () async {
                    final ok = await AppDialogs.showConfirmDialog(
                      context: context,
                      title: 'Delete account',
                      message:
                      'This action is permanent. Do you want to continue?',
                      cancelLabel: 'Cancel',
                      confirmLabel: 'Delete',
                      tone: AppDialogTone.danger,
                    );

                    if (!ok) return;

                    await AuthController.deleteAccount();
                    if (!context.mounted) return;

                    Navigator.pop(context);
                    await onResetAll();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}