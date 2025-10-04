enum MessageSender { user, ai }

class Source {
  final String title;
  final String url;
  final String snippet;

  Source({required this.title, required this.url, required this.snippet});
}

class Message {
  String text;
  final MessageSender sender;
  final List<Source> sources;
  bool streaming; // whether this message is being streamed (partial content)

  Message({
    required this.text,
    required this.sender,
    this.sources = const [],
    this.streaming = false,
  });
}
