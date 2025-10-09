import 'package:flutter/material.dart';

class DiscoverDetailScreen extends StatelessWidget {
  final Map<String, String> article;

  const DiscoverDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          article["title"]!,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(article["image"]!, fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),
          Text(
            article["title"]!,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "By ${article["author"]!}",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Text(
            article["subtitle"]! * 10, // placeholder for long content
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}
