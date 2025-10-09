import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../database/chat_database.dart';
import '../models/chat_session.dart';
import '../services/api_service.dart';
import 'chat_screen.dart'; // your existing chat screen

class LibraryScreen extends StatefulWidget {
  final ApiService apiService;
  const LibraryScreen({super.key, required this.apiService});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<ChatSession> _sessions = [];
  String _query = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final data = _query.isEmpty
        ? await ChatDatabase.instance.fetchAllSessions()
        : await ChatDatabase.instance.searchSessions(_query);

    if (mounted) {
      setState(() => _sessions = data);
    }
  }

  void _startSearch() {
    setState(() => _isSearching = !_isSearching);
    if (!_isSearching) {
      _query = '';
      _searchController.clear();
      _loadSessions();
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value);
      _loadSessions();
    });
  }

  void _openChat(ChatSession session) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => ChatScreen(
          previousSession: session,
          apiService:
              widget.apiService, // modify your ChatScreen to handle null
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF0A657E),
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 350),
                pageBuilder: (_, __, ___) => ChatScreen(
                  startNewSession: true,
                  apiService: widget.apiService,
                ),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta! > 25) {
              Navigator.pop(context);
            }
          },
          child: Stack(
            children: [
              /// 🧊 Frosted glass background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.8),
                        const Color(0xFFF3EFFF).withOpacity(0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              /// 🌈 Main content
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Library",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isSearching ? Icons.close : Icons.search,
                              color: Colors.black87,
                            ),
                            onPressed: _startSearch,
                          ),
                        ],
                      ),

                      // Search field
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isSearching
                            ? Padding(
                                key: const ValueKey('searchField'),
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  onChanged: _onSearchChanged,
                                  decoration: InputDecoration(
                                    hintText: "Search your chats...",
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // List of sessions
                      Expanded(
                        child: _sessions.isEmpty
                            ? const Center(
                                child: Text(
                                  "No chat sessions yet.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: _sessions.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 24,
                                  color: Colors.black12,
                                ),
                                itemBuilder: (context, index) {
                                  final s = _sessions[index];
                                  return GestureDetector(
                                    onTap: () => _openChat(s),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            s.message,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.lock_outline,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                s.timestamp,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
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
            ],
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('❌ Error building LibraryScreen: $e\n$st');
      return const Scaffold(
        body: Center(child: Text("Error loading Library Screen")),
      );
    }
  }
}
