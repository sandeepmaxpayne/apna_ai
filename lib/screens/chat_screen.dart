import 'package:apna_ai/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
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

  bool _isDrawerOpen = false;
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

  void _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final msg = ChatMessage(sender: MessageSender.user, text: text);
    setState(() => _messages.add(msg));
    _controller.clear();

    final aiMsg =
        ChatMessage(sender: MessageSender.ai, text: "", streaming: true);
    setState(() => _messages.add(aiMsg));

    await for (final chunk in widget.apiService.streamQuery(text)) {
      setState(() => aiMsg.text += chunk);
    }
    setState(() => aiMsg.streaming = false);
  }

  void _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final aiMsg = ChatMessage(
        sender: MessageSender.ai, text: "Uploading image...", streaming: true);
    setState(() => _messages.add(aiMsg));

    final resp = await widget.apiService.uploadImage(picked.path);
    setState(() {
      aiMsg.text = resp;
      aiMsg.streaming = false;
    });
  }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg.text,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Subscription Drawer
          SubscriptionDrawer(onClose: _toggleDrawer),

          // Main Chat with oval animation
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
                title: const Text("Mistral Chat"),
                leading: IconButton(
                  icon: const Icon(Icons.person, size: 28),
                  onPressed: _toggleDrawer,
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _buildMessage(_messages[i]),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                          onPressed: _sendImage, icon: const Icon(Icons.image)),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration:
                              const InputDecoration(hintText: "Type a message"),
                        ),
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

/// Custom clipper for oval animation
class OvalRightClipper extends CustomClipper<Path> {
  final double progress;
  OvalRightClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    double curve = 60 * progress; // oval curve
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
