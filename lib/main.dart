import 'package:apna_ai/screens/chat_screen.dart';
import 'package:apna_ai/screens/login_screen.dart';
import 'package:apna_ai/services/api_service.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _selectedTier = "free";
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService("aoyjVhnWuymvHgglWQSHlAja9DOnJDKA");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mistral Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      navigatorKey: navigatorKey,
      initialRoute: '/chat',
      routes: {
        '/': (_) => const LoginScreen(),
        '/chat': (_) => ChatScreen(apiService: _apiService),
      },
    );
  }
}
