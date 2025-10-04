enum MessageSender { user, ai }

class Source {
  final String title;
  final String url;
  final String snippet;
  Source({required this.title, required this.url, required this.snippet});
}

class ChatMessage {
  final MessageSender sender;
  String text;
  bool streaming;
  List<Source> sources;
  ChatMessage({
    required this.sender,
    required this.text,
    this.streaming = false,
    this.sources = const [],
  });
}
