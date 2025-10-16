import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String date;
  final String articleUrl;

  const NewsDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.date,
    required this.articleUrl,
  });

  @override
  Widget build(BuildContext context) {
    final safeUrl = Uri.decodeFull(imageUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Article Details"),
        backgroundColor: const Color(0xFF0A657E),
      ),
      floatingActionButton: articleUrl.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final uri = Uri.parse(articleUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              backgroundColor: const Color(0xFF0A657E),
              label: const Text("Read Full Article"),
              icon: const Icon(Icons.open_in_browser),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: title,
              child: Image.network(
                safeUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, size: 60),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
