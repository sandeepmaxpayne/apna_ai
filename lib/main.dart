import 'package:apna_ai/models/theme_color.dart';
import 'package:apna_ai/offer/offer_screen.dart';
import 'package:apna_ai/screens/chat_screen.dart';
import 'package:apna_ai/screens/discover_page.dart';
import 'package:apna_ai/screens/library_screen.dart';
import 'package:apna_ai/screens/specs_page.dart';
import 'package:apna_ai/services/api_service.dart';
import 'package:apna_ai/widgets/bottom_taskbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          //Color(0xFFF3EFFF), // pastel purple or match your theme
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
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
        return const DiscoverScreen(key: ValueKey('discover'));
      case '/spaces':
        return const SpacesPage(key: ValueKey('spaces'));
      case '/library':
        return LibraryScreen(
            key: const ValueKey('library'), apiService: _apiService);
      case '/offer':
        return const OfferPage(key: ValueKey('offer'));
      default:
        return ChatScreen(
          key: const ValueKey('chat'),
          apiService: _apiService,
        );
    }
  }
}
