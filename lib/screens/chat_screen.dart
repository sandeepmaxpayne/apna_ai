import 'dart:io';

import 'package:apna_ai/models/format_message.dart';
import 'package:apna_ai/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/message.dart';
import '../services/api_service.dart';
import '../services/music_service.dart';
import '../widgets/inline_link_row.dart';
import '../widgets/tired_bot_animation.dart';

// --- THEME COLORS ---
const Color _kPrimaryColor = Color(0xFF6B4EEA);
const Color _kBackgroundColor = Color(0xFFF3EFFF);
const Color _kInputFillColor = Color(0xFFD9CCFF);
const Color _kAIChatBubbleStart = Color(0xFFEBE3FF);
const Color _kAIChatBubbleEnd = Color(0xFFD9CCFF);
const Color _kUserChatBubbleColor = Color(0xFFF0F0F0);

class ChatScreen extends StatefulWidget {
  final ApiService apiService;
  const ChatScreen({super.key, required this.apiService});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final _record = AudioRecorder();
  final _musicService = MusicService();

  bool _isDrawerOpen = false;
  bool _isTyping = false;
  late AnimationController _drawerController;
  late AnimationController _wobbleController;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        setState(() {});
      });

    // Create wobble controller but DO NOT start it automatically.
    // We'll call _wobbleController.repeat(...) only when a msg becomes tired.
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: -0.05,
      upperBound: 0.05,
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    // DO NOT call _record.dispose() — Record doesn't expose dispose. Stop if recording.
    _wobbleController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      if (_isDrawerOpen) {
        _drawerController.forward();
      } else {
        _drawerController.reverse();
      }
    });
  }

  Future<void> _rechargeBot(ChatMessage msg) async {
    final lastUserMsg = _messages.lastWhere(
      (m) => m.sender == MessageSender.user,
      orElse: () => ChatMessage(sender: MessageSender.user, text: ""),
    );

    if (lastUserMsg.text.isEmpty) return;

    setState(() {
      msg.rechargeRequested = true;
      msg.text = "⚡ Waking up the bot...";
      if (!_wobbleController.isAnimating) {
        _wobbleController.repeat(reverse: true);
      }
    });

    await Future.delayed(const Duration(seconds: 1));

    try {
      await for (final chunk
          in widget.apiService.streamQuery(lastUserMsg.text)) {
        if (chunk.contains("streaming unavailable") ||
            chunk.contains("error")) {
          setState(() {
            msg.text = "😴 Still tired... please try again later!";
            msg.streaming = false;
            msg.isTired = true;
            msg.rechargeRequested = false;
            if (!_wobbleController.isAnimating) {
              _wobbleController.repeat(reverse: true);
            }
          });
          return;
        }
        setState(() {
          msg.text += chunk;
          msg.streaming = true;
        });
      }

      setState(() {
        msg.streaming = false;
        msg.isTired = false;
        msg.rechargeRequested = false;
        if (_wobbleController.isAnimating) {
          _wobbleController.stop();
          _wobbleController.value = 0;
        }
      });
    } catch (e) {
      setState(() {
        msg.text = "🤖 Bot couldn't recharge: $e";
        msg.rechargeRequested = false;
        msg.isTired = true;
        if (!_wobbleController.isAnimating) {
          _wobbleController.repeat(reverse: true);
        }
      });
    }
  }

  /// 🎵 Music Recognition
  Future<void> _startMusicRecognition() async {
    try {
      if (!await _record.hasPermission()) {
        setState(() {
          _messages.add(ChatMessage(
            sender: MessageSender.ai,
            text: "⚠️ Please grant microphone permission to recognize music.",
          ));
        });
        return;
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/recorded_song.m4a';

      // start recording (Record package signatures vary; this is a common usage)
      await _record.start(
        const RecordConfig(),
        path: path,
      );

      setState(() {
        _messages.add(ChatMessage(
          sender: MessageSender.ai,
          text: "🎧 Listening... Please wait for 8 seconds 🎶",
        ));
      });

      await Future.delayed(const Duration(seconds: 8));
      final recordedPath = await _record.stop();

      if (recordedPath == null || !await File(recordedPath).exists()) {
        setState(() {
          _messages.add(ChatMessage(
            sender: MessageSender.ai,
            text: "❌ Recording failed or was cancelled.",
          ));
        });
        return;
      }

      final result = await _musicService.recognizeSong(File(recordedPath));
      if (result != null) {
        final title = result['title'] ?? 'Unknown';
        final artist = result['artist'] ?? 'Unknown';
        final spotify = result['spotify']?['external_urls']?['spotify'];
        final jiosaavn =
            "https://www.jiosaavn.com/search/${Uri.encodeComponent("$title $artist")}";

        setState(() {
          _messages.add(ChatMessage(
            sender: MessageSender.ai,
            text:
                "🎵 *$title* by *$artist*\n\n[🎧 Open on Spotify]($spotify)\n[🎵 Listen on JioSaavn]($jiosaavn)",
          ));
        });

        if (spotify != null) {
          launchUrl(Uri.parse(spotify), mode: LaunchMode.externalApplication);
        }
      } else {
        setState(() {
          _messages.add(ChatMessage(
            sender: MessageSender.ai,
            text: "❌ Sorry, I couldn’t recognize that song.",
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          sender: MessageSender.ai,
          text: "⚠️ Error recognizing music: $e",
        ));
      });
    }
  }

  /// 🧠 Send Text
  void _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userMsg = ChatMessage(sender: MessageSender.user, text: text);
    setState(() => _messages.add(userMsg));
    _controller.clear();

    final aiMsg =
        ChatMessage(sender: MessageSender.ai, text: "", streaming: true);
    setState(() {
      _messages.add(aiMsg);
      _isTyping = true;
    });

    try {
      await for (final chunk in widget.apiService.streamQuery(text)) {
        if (chunk.toLowerCase().contains("streaming unavailable") ||
            chunk.toLowerCase().contains("error") ||
            chunk.toLowerCase().contains("json")) {
          setState(() {
            aiMsg.text =
                "🤖 *Bot is a little tired right now… please try again in a moment!* 😴";
            aiMsg.isTired = true; // ⚡ mark bot as tired
            if (!_wobbleController.isAnimating) {
              _wobbleController.repeat(reverse: true); // start wobble
            }
          });
          break;
        } else {
          setState(() => aiMsg.text += chunk);
        }
      }
    } catch (e) {
      setState(() {
        aiMsg.text =
            "🤖 *Bot is feeling a bit broken right now.* Please try again later 🛠️";
        aiMsg.isTired = true; // ⚡ mark bot as tired
        if (!_wobbleController.isAnimating) {
          _wobbleController.repeat(reverse: true); // start wobble
        }
      });
    } finally {
      setState(() {
        aiMsg.streaming = false;
        _isTyping = false;
      });
    }
  }

  /// 🖼️ Send Image
  void _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final aiMsg = ChatMessage(
        sender: MessageSender.ai,
        text: "📤 Uploading image...",
        streaming: true);
    setState(() => _messages.add(aiMsg));

    final resp = await widget.apiService.uploadImage(picked.path);
    setState(() {
      aiMsg.text = resp;
      aiMsg.streaming = false;
    });
  }

  /// 💬 Build message bubble with robot, gradient & links
  Widget _buildMessage(ChatMessage msg) {
    final urls = extractUrlsFromMessage(msg.text);
    final isUser = msg.sender == MessageSender.user;

    if (isUser) {
      // User bubble remains same
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: _kUserChatBubbleColor,
            borderRadius: BorderRadius.circular(20).copyWith(
              topRight: const Radius.circular(5),
              bottomRight: const Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: formatMessageText(msg.text,
              baseStyle: const TextStyle(color: Colors.black87, fontSize: 16)),
        ),
      );
    } else {
      // AI bubble
      return Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kAIChatBubbleStart, _kAIChatBubbleEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20).copyWith(
                  topLeft: const Radius.circular(5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipOval(
                          child: msg.isTired
                              ? const TiredBotAnimation()
                              : Image.asset(
                                  'assets/robot_icon.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.smart_toy,
                                          color: _kPrimaryColor, size: 24),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!msg.isTired)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              topLeft: const Radius.circular(5),
                              bottomLeft: const Radius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Thinking...",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 800),
                    child: formatMessageText(
                      msg.text,
                      baseStyle: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  if (urls.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    InlineLinkRow(urls: urls),
                  ],
                  // 👇 Recharge button if tired
                  if (msg.isTired)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // 👇 Animated robot icon wobbling (small)
                          AnimatedBuilder(
                            animation: _wobbleController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _wobbleController.value,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kPrimaryColor.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/robot_tired.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.smart_toy,
                                    color: _kPrimaryColor,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "🤖 Bot is tired... needs a recharge!",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // ⚡ Recharge Button (with spinner)
                                ElevatedButton.icon(
                                  onPressed: msg.rechargeRequested
                                      ? null
                                      : () => _rechargeBot(msg),
                                  icon: msg.rechargeRequested
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.bolt,
                                          size: 18, color: Colors.white),
                                  label: Text(
                                    msg.rechargeRequested
                                        ? "Recharging..."
                                        : "Recharge Bot",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6B4EEA),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  List<String> extractUrlsFromMessage(String text) {
    final urlRegex = RegExp(r'https?:\/\/[^\s]+');
    return urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// ✨ Typing indicator
  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(
          3,
          (i) => AnimatedContainer(
            duration: Duration(milliseconds: 300 + (i * 100)),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 8,
            width: 8,
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  /// 🏗 Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: Stack(
        children: [
          SubscriptionDrawer(onClose: _toggleDrawer),
          AnimatedBuilder(
            animation: _drawerController,
            builder: (context, child) {
              double slide = MediaQuery.of(context).size.width *
                  0.65 *
                  _drawerController.value;
              double scale = 1 - (_drawerController.value * 0.2);

              return Transform(
                transform: Matrix4.identity()
                  ..translate(slide)
                  ..scale(scale),
                alignment: Alignment.center,
                child: ClipPath(
                  clipper: OvalRightClipper(_drawerController.value),
                  child: Scaffold(
                    backgroundColor: _kBackgroundColor,
                    appBar: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      centerTitle: true,
                      title: const Text(
                        "Apna AI",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black),
                        onPressed: _toggleDrawer,
                      ),
                    ),
                    body: SafeArea(
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              itemCount: _messages.length + (_isTyping ? 1 : 0),
                              itemBuilder: (_, i) {
                                final index = _messages.length - 1 - i;
                                if (index >= 0) {
                                  return _buildMessage(_messages[index]);
                                } else {
                                  return _typingIndicator();
                                }
                              },
                            ),
                          ),

                          // ---- INPUT FIELD WITH MUSIC & SEND ----
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: _kInputFillColor,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.camera,
                                      color: _kPrimaryColor,
                                    ),
                                    onPressed: _sendImage,
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      decoration: const InputDecoration(
                                        hintText: "Ask me anything?",
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (_) => _sendText(),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.music_note,
                                      color: _kPrimaryColor,
                                    ),
                                    onPressed: _startMusicRecognition,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_upward,
                                      color: _kPrimaryColor,
                                    ),
                                    onPressed: _sendText,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Oval Drawer Animation
class OvalRightClipper extends CustomClipper<Path> {
  final double progress;
  OvalRightClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    double curve = 60 * progress;
    path.moveTo(0, 0);
    path.lineTo(size.width - curve, 0);
    path.quadraticBezierTo(
        size.width, size.height / 2, size.width - curve, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(OvalRightClipper oldClipper) =>
      oldClipper.progress != progress;
}
