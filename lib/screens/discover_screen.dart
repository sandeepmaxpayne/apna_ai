import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

import 'news_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _articles = [];
  String _selectedCategory = "Top Stories";
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  double _dragStartX = 0;

  final List<String> _categories = [
    "Top Stories",
    "Tech & Science",
    "Finance",
    "Arts & Culture",
    "Sports",
    "Entertainment"
  ];

  final String baseUrl =
      "https://script.google.com/macros/s/AKfycbxfJaoK5j6TjYAXLuctoCdsEtlhV4t6DVvh5mP9Vjbo0hv3sgi0bbO-LwGEzIHB_7PE/exec";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scrollController.addListener(_handleScroll);
    fetchNewsByCategory(_selectedCategory);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.offset > 400 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 400 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  Future<void> _scrollToTop() async {
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
    fetchNewsByCategory(category);
  }

  // Swipe gesture handling
  void _onHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final dx = details.globalPosition.dx - _dragStartX;
    if (dx < -80) {
      _selectNextCategory();
      _dragStartX = details.globalPosition.dx;
    } else if (dx > 80) {
      _selectPrevCategory();
      _dragStartX = details.globalPosition.dx;
    }
  }

  void _selectNextCategory() {
    final idx = _categories.indexOf(_selectedCategory);
    if (idx < _categories.length - 1) {
      _onCategorySelected(_categories[idx + 1]);
    }
  }

  void _selectPrevCategory() {
    final idx = _categories.indexOf(_selectedCategory);
    if (idx > 0) {
      _onCategorySelected(_categories[idx - 1]);
    }
  }

  Future<void> fetchNewsByCategory(String category) async {
    setState(() => _isLoading = true);
    _animationController.reset();

    final encodedCategory = Uri.encodeComponent(category);
    final url = "$baseUrl?category=$encodedCategory";

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> articlesList =
            decoded is List ? decoded : (decoded['articles'] ?? []);

        final cleaned = articlesList.map<Map<String, dynamic>>((e) {
          final map =
              (e as Map).map((k, v) => MapEntry(k.toString().toLowerCase(), v));
          return {
            "title": map["title"] ?? "Untitled",
            "description": map["description"] ?? "",
            "category": map["category"] ?? category,
            "image":
                _proxyImage(_sanitizeImageUrl((map["image"] ?? '').toString())),
            "date": map["publishedat"] ?? map["date"] ?? "",
            "link": map["url"] ?? map["link"] ?? "",
          };
        }).toList();

        setState(() {
          _articles = cleaned;
          _isLoading = false;
        });

        _animationController.forward();
      } else {
        throw Exception("Failed with status: ${response.statusCode}");
      }
    } on TimeoutException {
      debugPrint("⏰ Timeout — retrying...");
      await Future.delayed(const Duration(seconds: 2));
      return fetchNewsByCategory(category);
    } catch (e) {
      debugPrint("⚠️ Error fetching news: $e");
      setState(() => _isLoading = false);
    }
  }

  String _sanitizeImageUrl(String url) {
    if (url.isEmpty) return "";
    try {
      final clean = Uri.decodeFull(url)
          .replaceAll(RegExp(r'(?<=\?.*|&)(w|width|h|height)=\d+'), '')
          .replaceAll('%2C', ',')
          .replaceAll('%2520', '%20');
      return clean;
    } catch (_) {
      return url;
    }
  }

  String _proxyImage(String url) {
    if (url.isEmpty) return "";
    final encoded = Uri.encodeComponent(url);
    return "https://images.weserv.nl/?url=$encoded";
  }

  @override
  Widget build(BuildContext context) {
    final filteredArticles = _articles;

    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("Discover",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildCategoryChips(),
                Expanded(
                  child: _isLoading
                      ? _buildShimmerList()
                      : filteredArticles.isEmpty
                          ? const Center(
                              child: Text("No news available",
                                  style: TextStyle(color: Colors.white70)),
                            )
                          : RefreshIndicator(
                              onRefresh: () =>
                                  fetchNewsByCategory(_selectedCategory),
                              color: Colors.deepPurpleAccent,
                              child: AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return FadeTransition(
                                    opacity: _animationController,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                              begin: const Offset(0.02, 0.02),
                                              end: Offset.zero)
                                          .animate(_animationController),
                                      child: child,
                                    ),
                                  );
                                },
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredArticles.length,
                                  itemBuilder: (context, index) {
                                    final article = filteredArticles[index];
                                    return _buildArticleCard(article);
                                  },
                                ),
                              ),
                            ),
                ),
              ],
            ),

            // Floating Scroll-to-Top
            if (_showScrollToTop)
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton(
                  onPressed: _scrollToTop,
                  backgroundColor: Colors.deepPurpleAccent,
                  elevation: 8,
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ Original-style animated category chips
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 58,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => _onCategorySelected(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.deepPurpleAccent
                      : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.deepPurpleAccent.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade300,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              )
                  .animate(delay: (index * 100).ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.4, end: 0, curve: Curves.easeOutBack),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    final title = (article["title"] ?? '') as String;
    final description = (article["description"] ?? '') as String;
    final image = (article["image"] ?? '') as String;
    final date = (article["date"] ?? '') as String;
    final link = (article["link"] ?? '') as String;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(
              title: title,
              description: description,
              imageUrl: image,
              date: date,
              articleUrl: link,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: const Color(0xFF1E1E1E),
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(image, title),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(date,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl, String tag) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[800],
        child: const Icon(Icons.image_not_supported,
            size: 48, color: Colors.white38),
      );
    }

    return Hero(
      tag: tag,
      child: Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        headers: const {"User-Agent": "Mozilla/5.0"},
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[700]!,
            child: Container(height: 200, color: Colors.grey[850]),
          );
        },
        errorBuilder: (_, error, ___) {
          debugPrint("🚫 Image load failed: $error");
          return Container(
            height: 200,
            color: Colors.grey[850],
            child:
                const Icon(Icons.broken_image, size: 48, color: Colors.white38),
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[700]!,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}
