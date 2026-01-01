import 'package:flutter/material.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock friends
    final friends = const [
      ('Mona', 'mona@example.com'),
      ('Ali', 'ali@example.com'),
      ('Sophie', 'sophie@example.com'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Mock: Add friend',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mock: add friend tapped')),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: friends.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final (name, email) = friends[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(name.characters.first)),
              title: Text(name),
              subtitle: Text(email),
              trailing: const Icon(Icons.more_horiz),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mock: open $name profile')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
