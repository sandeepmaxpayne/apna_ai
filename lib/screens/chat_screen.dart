import 'dart:io';

import 'package:apna_ai/models/format_message.dart';
import 'package:apna_ai/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../services/music_service.dart';
import '../widgets/message_model.dart';

class ChatScreen extends StatefulWidget {
  final ApiService apiService;
  const ChatScreen({super.key, required this.apiService});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final _record = AudioRecorder();
  final _musicService = MusicService();

  bool _isDrawerOpen = false;
  bool _isTyping = false;
  late AnimationController _drawerController;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _record.dispose();
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

  /// 🎵 Start music recognition
  Future<void> _startMusicRecognition() async {
    try {
      // Check microphone permission
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

      // Start recording
      await _record.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _messages.add(ChatMessage(
          sender: MessageSender.ai,
          text: "🎧 Listening... Please wait for 8 seconds 🎶",
        ));
      });

      // Record for 8 seconds
      await Future.delayed(const Duration(seconds: 8));

      // Stop recording
      final recordedPath = await _record.stop();
      if (recordedPath == null) {
        setState(() {
          _messages.add(ChatMessage(
            sender: MessageSender.ai,
            text: "❌ Recording failed or was cancelled.",
          ));
        });
        return;
      }

      // Verify file exists
      final file = File(recordedPath);
      if (!await file.exists()) {
        setState(() {
          _messages.add(ChatMessage(
            sender: MessageSender.ai,
            text: "❌ Recording file not found.",
          ));
        });
        return;
      }

      // Recognize song
      final result = await _musicService.recognizeSong(file);

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

  // 🧠 SEND TEXT
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

    await for (final chunk in widget.apiService.streamQuery(text)) {
      setState(() => aiMsg.text += chunk);
    }

    setState(() {
      aiMsg.streaming = false;
      _isTyping = false;
    });
  }

  // 🖼️ SEND IMAGE
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

  // 💬 MESSAGE BUBBLE
  Widget _buildMessage(ChatMessage msg) {
    return Align(
      alignment: msg.sender == MessageSender.user
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          gradient: msg.sender == MessageSender.user
              ? const LinearGradient(
                  colors: [Color(0xFF6D5DF6), Color(0xFF9C7DFF)])
              : const LinearGradient(
                  colors: [Color(0xFF2E335A), Color(0xFF1C1B33)]),
          borderRadius: BorderRadius.circular(18),
        ),
        // child: Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 16),
        child: formatMessageText(msg.text,
            baseStyle: TextStyle(
                color: msg.sender == MessageSender.user
                    ? Colors.white
                    : Colors.white70,
                fontSize: 16)),
      ),
    );
  }

  // ✨ TYPING INDICATOR
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
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  child: child,
                ),
              );
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Apna AI Chat"),
                leading: IconButton(
                  icon: const Icon(Icons.person, size: 28),
                  onPressed: _toggleDrawer,
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i < _messages.length) {
                          return _buildMessage(_messages[i]);
                        } else {
                          return _typingIndicator();
                        }
                      },
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                          onPressed: _sendImage, icon: const Icon(Icons.image)),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                              hintText: "Ask anything..."),
                        ),
                      ),
                      IconButton(
                        onPressed: _startMusicRecognition,
                        icon: const Icon(Icons.music_note),
                      ),
                      IconButton(
                          onPressed: _sendText, icon: const Icon(Icons.send)),
                    ],
                  ),
                ],
              ),
            ),
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
