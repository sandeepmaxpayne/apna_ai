import 'package:flutter/material.dart';

import '../models/theme_color.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      {'title': 'AI Resume Builder', 'desc': 'Create your resume instantly'},
      {'title': 'AI Logo Generator', 'desc': 'Design logos in seconds'},
      {'title': 'Chat Summarizer', 'desc': 'Summarize long chats easily'},
      {'title': 'Skill Recommender', 'desc': 'Get personalized skill paths'},
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "🌍 Discover",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          ...tools.map((t) => Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading:
                      const Icon(Icons.auto_awesome, color: AppColors.primary),
                  title: Text(t['title']!),
                  subtitle: Text(t['desc']!),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                ),
              )),
        ],
      ),
    );
  }
}
