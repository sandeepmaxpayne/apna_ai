import 'package:flutter/material.dart';

class BuildBottomTaskbar extends StatefulWidget {
  const BuildBottomTaskbar({super.key});

  @override
  State<BuildBottomTaskbar> createState() => _BuildBottomTaskbarState();
}

class _BuildBottomTaskbarState extends State<BuildBottomTaskbar>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  late AnimationController _taskbarController;

  @override
  void initState() {
    super.initState();
    _taskbarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1, // visible initially
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.chat_bubble_outline, 'label': 'Chat'},
      {'icon': Icons.explore_outlined, 'label': 'Discover'},
      {'icon': Icons.groups_2_outlined, 'label': 'Spaces'},
      {'icon': Icons.library_books_outlined, 'label': 'Library'},
    ];

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
            children: List.generate(items.length, (index) {
              final isActive = _selectedTab == index;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedTab = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.blue.withOpacity(
                            0.12) // Replace with AppColors.primary if defined
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isActive ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          items[index]['icon'] as IconData,
                          color: isActive ? Colors.blue : Colors.grey,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          color: isActive ? Colors.blue : Colors.grey,
                          fontSize: isActive ? 13 : 12,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                        child: Text(items[index]['label'] as String),
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
