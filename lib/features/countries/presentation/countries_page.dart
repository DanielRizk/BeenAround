import 'package:flutter/material.dart';

class CountriesPage extends StatelessWidget {
  const CountriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock list (later replace with real data + search + filters)
    final countries = const [
      'Germany',
      'Egypt',
      'France',
      'Japan',
      'Brazil',
      'Canada',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Countries')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: countries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final name = countries[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(name),
              subtitle: const Text('Mock: tap later to open country details'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mock: selected $name')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
