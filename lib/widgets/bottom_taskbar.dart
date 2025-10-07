import 'package:apna_ai/models/theme_color.dart';
import 'package:flutter/material.dart';

class BuildBottomTaskbar extends StatefulWidget {
  final String currentRoute;
  final ValueChanged<String> onTabSelected;

  const BuildBottomTaskbar({
    super.key,
    required this.currentRoute,
    required this.onTabSelected,
  });

  @override
  State<BuildBottomTaskbar> createState() => _BuildBottomTaskbarState();
}

class _BuildBottomTaskbarState extends State<BuildBottomTaskbar>
    with TickerProviderStateMixin {
  late AnimationController _taskbarController;

  final List<Map<String, dynamic>> _tabs = [
    {'icon': Icons.chat_bubble_outline, 'label': 'Chat', 'route': '/chat'},
    {'icon': Icons.explore_outlined, 'label': 'Discover', 'route': '/discover'},
    {'icon': Icons.groups_2_outlined, 'label': 'Spaces', 'route': '/spaces'},
    {
      'icon': Icons.library_books_outlined,
      'label': 'Library',
      'route': '/library'
    },
  ];

  @override
  void initState() {
    super.initState();
    _taskbarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1,
    );
  }

  @override
  void dispose() {
    _taskbarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _taskbarController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _taskbarController,
          curve: Curves.easeOut,
        )),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              final isActive = widget.currentRoute == tab['route'];

              return GestureDetector(
                onTap: () => widget.onTabSelected(tab['route'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent, // ⬅ removed highlight background
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isActive ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          tab['icon'] as IconData,
                          color: isActive ? AppColors.primary : Colors.grey,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          color: isActive ? AppColors.primary : Colors.grey,
                          fontSize: isActive ? 13 : 12,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                        child: Text(tab['label'] as String),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
