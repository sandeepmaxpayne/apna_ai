import 'dart:io';

import 'package:apna_ai/models/format_message.dart';
import 'package:apna_ai/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/message.dart';
import '../models/theme_color.dart';
import '../services/api_service.dart';
import '../services/music_service.dart';
import '../widgets/animated_typing_dot.dart';
import '../widgets/inline_link_row.dart';
import '../widgets/ovalRight_clipper.dart';
import '../widgets/tired_bot_animation.dart';

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
  bool _hasError = false;
  bool _isStreaming = false;
  bool _stopRequested = false;
  late AnimationController _pulseController;
  late AnimationController _morphController;
  bool _isDrawerOpen = false;
  bool _isTyping = false;
  late AnimationController _drawerController;
  late AnimationController _wobbleController;
  late AnimationController _taskbarController;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        setState(() {});
      });
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: -0.05,
      upperBound: 0.05,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _taskbarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1, // visible initially
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _wobbleController.dispose();
    _pulseController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  void _toggleDrawer() async {
    await Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) =>
          SubscriptionDrawer(
        onClose: () => Navigator.of(context).pop(),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 1), // slide up from bottom
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    ));
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

      await _record.start(const RecordConfig(), path: path);

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

  void _stopResponse() {
    setState(() {
      _stopRequested = true;
      _isStreaming = false;
    });
    _pulseController.stop();
    _morphController.reverse();
  }

  void _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isStreaming) return;

    final userMsg = ChatMessage(sender: MessageSender.user, text: text);
    setState(() {
      _messages.add(userMsg);
      _controller.clear();
      _isTyping = true;
      _hasError = false;
      _isStreaming = true;
      _stopRequested = false;
    });

    final aiMsg =
        ChatMessage(sender: MessageSender.ai, text: "", streaming: true);
    setState(() => _messages.add(aiMsg));

    try {
      await for (final chunk in widget.apiService.streamQuery(text)) {
        if (_stopRequested) break;

        if (chunk.toLowerCase().contains("streaming unavailable") ||
            chunk.toLowerCase().contains("error") ||
            chunk.toLowerCase().contains("json")) {
          setState(() {
            aiMsg.text =
                "🤖 *Bot is a little tired right now… please try again in a moment!* 😴";
            aiMsg.isTired = true;
            _hasError = true;
            if (!_wobbleController.isAnimating) {
              _wobbleController.repeat(reverse: true);
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
        aiMsg.isTired = true;
        _hasError = true;
        if (!_wobbleController.isAnimating) {
          _wobbleController.repeat(reverse: true);
        }
      });
    } finally {
      setState(() {
        aiMsg.streaming = false;
        _isTyping = false;
        _isStreaming = false;
      });
    }
  }

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

  Widget _buildMessage(ChatMessage msg) {
    final urls = extractUrlsFromMessage(msg.text);
    final isUser = msg.sender == MessageSender.user;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.userBubble,
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
                  colors: [AppColors.accent, AppColors.inputFill],
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
                                          color: AppColors.primary, size: 24),
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: ScaleTransition(scale: anim, child: child),
                            ),
                            child: _isStreaming
                                ? const AnimatedThinkingText(
                                    key: ValueKey('thinking_text'))
                                : const SizedBox.shrink(
                                    key: ValueKey('empty_space')),
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
                  if (msg.isTired)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
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
                                    color: AppColors.primary.withOpacity(0.3),
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
                                    color: AppColors.primary,
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
                                    backgroundColor: AppColors.primary,
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

  bool get _isKeyboardVisible => MediaQuery.of(context).viewInsets.bottom > 50;

  /// 🏗 Build UI
  @override
  Widget build(BuildContext context) {
    // Animate taskbar visibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isKeyboardVisible) {
        _taskbarController.reverse();
      } else {
        _taskbarController.forward();
      }
    });
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    backgroundColor: AppColors.background,
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
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 0),
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                reverse: true,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                itemCount:
                                    _messages.length + (_isStreaming ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_isStreaming &&
                                      index == _messages.length) {
                                    // Streaming "Thinking..." bubble
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(
                                              left: 10, right: 8, top: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: const Icon(Icons.smart_toy,
                                              color: Colors.deepPurple,
                                              size: 22),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const AnimatedThinkingText(),
                                        ),
                                      ],
                                    );
                                  }

                                  final reversedIndex =
                                      _messages.length - 1 - index;
                                  return _buildMessage(
                                      _messages[reversedIndex]);
                                },
                              ),
                            ),
                            // ---- INPUT FIELD WITH MUSIC & SEND ----
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              switchInCurve: Curves.elasticOut,
                              switchOutCurve: Curves.easeInBack,
                              transitionBuilder: (child, anim) {
                                return ScaleTransition(
                                  scale: Tween<double>(begin: 0.6, end: 1.0)
                                      .animate(anim),
                                  child: FadeTransition(
                                      opacity: anim, child: child),
                                );
                              },
                              child: _isStreaming
                                  ? Padding(
                                      key: const ValueKey('stop_button'),
                                      padding: const EdgeInsets.all(16),
                                      child: Center(
                                        child: AnimatedBuilder(
                                          animation: Listenable.merge([
                                            _pulseController,
                                            _morphController
                                          ]),
                                          builder: (_, __) {
                                            final scale = 1 +
                                                0.1 * _pulseController.value;
                                            return Transform.scale(
                                              scale: scale,
                                              child: IconButton(
                                                iconSize: 72,
                                                tooltip: "Stop Generating",
                                                icon: Container(
                                                  padding:
                                                      const EdgeInsets.all(20),
                                                  decoration: BoxDecoration(
                                                    color: Color.lerp(
                                                        AppColors.primary,
                                                        Colors.pinkAccent,
                                                        _morphController.value),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.redAccent
                                                            .withOpacity(0.5),
                                                        blurRadius: 25,
                                                        spreadRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.stop_rounded,
                                                    color: AppColors.secondary,
                                                    size: 36,
                                                  ),
                                                ),
                                                onPressed: _stopResponse,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                  : Padding(
                                      key: const ValueKey('input_bar'),
                                      padding: const EdgeInsets.all(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary,
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.camera_alt,
                                                  color: AppColors.primary),
                                              onPressed:
                                                  _hasError || _isStreaming
                                                      ? null
                                                      : _sendImage,
                                            ),
                                            Expanded(
                                              child: TextField(
                                                controller: _controller,
                                                enabled: !_hasError,
                                                decoration: InputDecoration(
                                                  hintText: _hasError
                                                      ? "⚠️ Bot error — try recharging..."
                                                      : "Ask me anything...",
                                                  border: InputBorder.none,
                                                ),
                                                onSubmitted: (_) => _sendText(),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.music_note,
                                                  color: AppColors.primary),
                                              onPressed:
                                                  _hasError || _isStreaming
                                                      ? null
                                                      : _startMusicRecognition,
                                            ),
                                            AnimatedBuilder(
                                              animation: _morphController,
                                              builder: (context, child) {
                                                final color = Color.lerp(
                                                    AppColors.primary,
                                                    Colors.pinkAccent,
                                                    _morphController.value);
                                                final icon =
                                                    _morphController.value > 0.5
                                                        ? Icons.stop_rounded
                                                        : Icons.send_rounded;
                                                return IconButton(
                                                  icon: Icon(icon,
                                                      color: color, size: 30),
                                                  onPressed: _hasError
                                                      ? null
                                                      : _isStreaming
                                                          ? _stopResponse
                                                          : _sendText,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
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
