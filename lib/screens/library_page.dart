import 'package:flutter/material.dart';

import '../models/theme_color.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = [
      {'title': 'AI for Small Businesses', 'type': 'Article'},
      {'title': 'Flutter State Management', 'type': 'Guide'},
      {'title': 'ChatGPT Custom Prompts', 'type': 'Notes'},
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "📚 Library",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          ...saved.map((i) => Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const Icon(Icons.bookmark, color: AppColors.primary),
                  title: Text(i['title']!),
                  subtitle: Text(i['type']!),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                ),
              )),
        ],
      ),
    );
  }
}
