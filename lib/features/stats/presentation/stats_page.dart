import 'package:flutter/material.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock stats
    const visited = 12;
    const wishlist = 8;
    const friends = 3;

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            _StatCard(title: 'Visited Countries', value: '$visited'),
            SizedBox(height: 12),
            _StatCard(title: 'Wishlist Countries', value: '$wishlist'),
            SizedBox(height: 12),
            _StatCard(title: 'Friends', value: '$friends'),
            SizedBox(height: 24),
            Text(
              'Mock page: later you can add charts, history, streaks, etc.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.insights),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
