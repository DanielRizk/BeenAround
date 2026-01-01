import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _showVisitedOnMap = true;
  bool _enableHaptics = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Dark mode (mock)'),
              subtitle: const Text('Hook to Theme later'),
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Show visited countries on map'),
              subtitle: const Text('Mock toggle for future map coloring'),
              value: _showVisitedOnMap,
              onChanged: (v) => setState(() => _showVisitedOnMap = v),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Haptics'),
              subtitle: const Text('Mock toggle'),
              value: _enableHaptics,
              onChanged: (v) => setState(() => _enableHaptics = v),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              subtitle: const Text('Mock: show app info'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Been Around',
                  applicationVersion: '0.0.1',
                  applicationLegalese: 'Mock app shell',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
