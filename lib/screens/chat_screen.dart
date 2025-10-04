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

  bool _showDrawer = false;
  late AnimationController _drawerController;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  void _toggleDrawer() {
    setState(() {
      _showDrawer = !_showDrawer;
      if (_showDrawer) {
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
      aiMsg.text = resp.toString();
      aiMsg.streaming = false;
      if (resp is List<dynamic>) {
        aiMsg.sources = (resp as List<dynamic>).map((s) {
          return Source(
            title: s['title'] ?? s['url'],
            url: s['url'] ?? '',
            snippet: s['snippet'] ?? '',
          );
        }).toList();
      }
    });
  }

  Widget _buildMessage(ChatMessage msg) {
    return Align(
      alignment: msg.sender == MessageSender.user
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color:
              msg.sender == MessageSender.user ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg.text),
            if (msg.sources.isNotEmpty)
              ...msg.sources.map((s) => Text(
                    "${s.title}: ${s.url}",
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.deepPurple),
          ),
          onPressed: _toggleDrawer,
        ),
        title: const Text("Mistral Chat"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          // Chat UI
          Column(
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
              )
            ],
          ),

          // Subscription Drawer
          if (_showDrawer)
            AnimatedBuilder(
              animation: _drawerController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                      -MediaQuery.of(context).size.width *
                          (1 - _drawerController.value),
                      0),
                  child: Opacity(
                    opacity: _drawerController.value,
                    child: SubscriptionDrawer(onClose: _toggleDrawer),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
