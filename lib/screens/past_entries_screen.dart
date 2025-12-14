import 'package:flutter/material.dart';

class PastEntriesScreen extends StatelessWidget {
  const PastEntriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch real entries
    final mockEntries = <Map<String, String>>[];

    return Scaffold(
      body: mockEntries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No past entries',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your journal entries will appear here',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mockEntries.length,
              itemBuilder: (context, index) {
                final entry = mockEntries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.calendar_today),
                    ),
                    title: Text(entry['date']!),
                    subtitle: Text(
                      entry['preview']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: Navigate to entry detail
                    },
                  ),
                );
              },
            ),
    );
  }
}
