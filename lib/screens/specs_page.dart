import 'package:flutter/material.dart';

import '../models/theme_color.dart';

class SpacesPage extends StatelessWidget {
  const SpacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spaces = [
      {'name': 'Flutter Devs', 'members': '12k members'},
      {'name': 'AI Builders', 'members': '9.3k members'},
      {'name': 'Design Thinkers', 'members': '7.2k members'},
      {'name': 'Tech Startups', 'members': '4.5k members'},
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "👥 Spaces",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          ...spaces.map((s) => Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.group, color: Colors.white),
                  ),
                  title: Text(s['name']!),
                  subtitle: Text(s['members']!),
                  trailing: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {},
                    child: const Text("Join"),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
