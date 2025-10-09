import 'package:flutter/material.dart';

import 'discover_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final List<String> categories = [
    "Tech & Science",
    "Finance",
    "Arts & Culture",
    "Sports",
    "World",
  ];

  int selectedCategory = 0;

  final List<Map<String, String>> articles = [
    {
      "title": "Solar sail spacecraft could boost space weather warnings",
      "subtitle":
          "University of Michigan researchers have unveiled a groundbreaking proposal for enhancing space weather warning systems.",
      "image":
          "https://cdn.mos.cms.futurecdn.net/ALJxHCx6HqVf3smAicwAUB-1200-80.jpg",
      "author": "thgths",
    },
    {
      "title": "AI revolutionizing space exploration",
      "subtitle":
          "New AI models are enabling autonomous spacecraft navigation and mission planning.",
      "image":
          "https://images.unsplash.com/photo-1543946603-0c3b76ecb3ea?auto=format&fit=crop&w=1200&q=80",
      "author": "spaceAI",
    },
    {
      "title": "Quantum computing breakthrough in 2025",
      "subtitle":
          "Researchers achieve stable qubits with reduced error rates, paving the way for real-world applications.",
      "image":
          "https://images.unsplash.com/photo-1632179288741-f2e9bcd49b26?auto=format&fit=crop&w=1200&q=80",
      "author": "qLabs",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Discover",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Category Chips
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final selected = selectedCategory == index;
                    return GestureDetector(
                      onTap: () => setState(() => selectedCategory = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFCCE4E4)
                              : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF0A657E)
                                : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Vertical Carousel
              Expanded(
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DiscoverDetailScreen(article: article),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        clipBehavior: Clip.antiAlias,
                        elevation: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            Expanded(
                              child: Image.network(
                                article["image"]!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                            // Text Section
                            Container(
                              width: double.infinity,
                              color: Colors.black.withOpacity(0.85),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article["title"]!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    article["subtitle"]!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.person,
                                              color: Colors.white70, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            article["author"]!,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Icon(Icons.bookmark_border,
                                          color: Colors.white70),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
