import 'package:apna_ai/screens/chat_screen.dart';
import 'package:apna_ai/services/api_service.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService("aoyjVhnWuymvHgglWQSHlAja9DOnJDKA");
    return MaterialApp(
      home: ChatScreen(apiService: apiService),
    );
  }
}
