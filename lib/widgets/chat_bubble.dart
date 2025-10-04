import 'package:flutter/material.dart';
import '../models/message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({super.key, required this.message});

  Widget _buildSources() {
    if (message.sources.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Sources', style: TextStyle(fontWeight: FontWeight.bold)),
        ...message.sources.map((s) => GestureDetector(
          onTap: () async {
            final uri = Uri.tryParse(s.url);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title, style: const TextStyle(decoration: TextDecoration.underline)),
                Text(s.snippet, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: message.text,
              selectable: true,
            ),
            _buildSources(),
          ],
        ),
      ),
    );
  }
}
