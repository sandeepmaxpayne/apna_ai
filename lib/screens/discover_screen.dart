import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

import '../models/theme_color.dart';
import 'news_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _articles = [];

  final String apiUrl =
      "https://script.google.com/macros/s/AKfycbzfr9cjtPHTya1jfUmZUyxyzrI5ST9Lb0T0LoJkUuB7ydcELv2JtUxD8NR8SfEOcDSA/exec";

  @override
  void initState() {
    super.initState();
    fetchTechNews();
  }

  Future<void> fetchTechNews() async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> articlesList =
            decoded is List ? decoded : (decoded['articles'] ?? []);

        final cleaned = articlesList.map<Map<String, dynamic>>((e) {
          final map = e.map((k, v) => MapEntry(k.toString().toLowerCase(), v));
          return {
            "title": map["title"] ?? "Untitled",
            "description": map["description"] ?? "",
            "image": _proxyImage(_sanitizeImageUrl(map["image"] ?? "")),
            "date": map["publishedat"] ?? map["date"] ?? "",
            "link": map["url"] ?? map["link"] ?? "",
          };
        }).toList();

        setState(() {
          _articles = cleaned;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed with status: ${response.statusCode}");
      }
    } on TimeoutException {
      debugPrint("⏰ Timeout — retrying...");
      await Future.delayed(const Duration(seconds: 2));
      return fetchTechNews();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Discover", style: AppTextStyles.heading),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildShimmerList()
          : _articles.isEmpty
              ? const Center(
                  child: Text("No news available", style: AppTextStyles.body),
                )
              : RefreshIndicator(
                  onRefresh: fetchTechNews,
                  color: AppColors.primary,
                  child: ListView.builder(
                    itemCount: _articles.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final article = _articles[index];
                      final title = article["title"];
                      final description = article["description"];
                      final image = article["image"];
                      final date = article["date"];
                      final link = article["link"];

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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: Colors.white,
                          elevation: 2,
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
                                    Text(
                                      title,
                                      style: AppTextStyles.subheading.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.small,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      date,
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
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
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Shimmer.fromColors(
          baseColor: AppColors.secondary.withOpacity(0.5),
          highlightColor: AppColors.accent.withOpacity(0.6),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl, String tag) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 180,
        color: AppColors.accent,
        child: const Icon(Icons.image_not_supported,
            size: 48, color: AppColors.textSecondary),
      );
    }

    return Hero(
      tag: tag,
      child: Image.network(
        imageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        headers: const {"User-Agent": "Mozilla/5.0"},
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Shimmer.fromColors(
            baseColor: AppColors.secondary.withOpacity(0.5),
            highlightColor: AppColors.accent.withOpacity(0.6),
            child: Container(height: 180, color: AppColors.secondary),
          );
        },
        errorBuilder: (_, error, ___) {
          debugPrint("🚫 Image load failed: $error");
          return Container(
            height: 180,
            color: AppColors.accent,
            child: const Icon(Icons.broken_image,
                size: 48, color: AppColors.textSecondary),
          );
        },
      ),
    );
  }
}
