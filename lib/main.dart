import 'package:apna_ai/models/theme_color.dart';
import 'package:apna_ai/screens/chat_screen.dart';
import 'package:apna_ai/screens/discover_page.dart';
import 'package:apna_ai/screens/library_page.dart';
import 'package:apna_ai/screens/specs_page.dart';
import 'package:apna_ai/services/api_service.dart';
import 'package:apna_ai/widgets/bottom_taskbar.dart';
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
  final String _selectedTier = "free";
  late ApiService _apiService;
  String _selectedTab = "/chat";
  int _previousTabIndex = 0;

  final List<String> _routes = ["/chat", "/discover", "/spaces", "/library"];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService("aoyjVhnWuymvHgglWQSHlAja9DOnJDKA");
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _routes.indexOf(_selectedTab);

    return MaterialApp(
      title: 'Mistral Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      navigatorKey: navigatorKey,
      home: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            final inFromRight = currentIndex > _previousTabIndex;
            final offsetAnimation = Tween<Offset>(
              begin: Offset(inFromRight ? 1 : -1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ));
            return SlideTransition(position: offsetAnimation, child: child);
          },
          child: _buildTabContent(),
        ),
        bottomNavigationBar: BuildBottomTaskbar(
          currentRoute: _selectedTab,
          onTabSelected: (route) {
            setState(() {
              _previousTabIndex = _routes.indexOf(_selectedTab);
              _selectedTab = route;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case '/discover':
        return const DiscoverPage(key: ValueKey('discover'));
      case '/spaces':
        return const SpacesPage(key: ValueKey('spaces'));
      case '/library':
        return const LibraryPage(key: ValueKey('library'));
      default:
        return ChatScreen(
          key: const ValueKey('chat'),
          apiService: _apiService,
        );
    }
  }
}
