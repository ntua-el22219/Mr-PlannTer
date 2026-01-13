import 'package:flutter/material.dart';

import 'main_page_screen.dart';
import 'todo_list_screen.dart';
import 'calendar_screen.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    MainPageScreen(), // Index 0: Main Page
    TodoListScreen(), // Index 1: To-Do List
    CalendarScreen(), // Index 2: Calendar
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleSwipeLeft() {
    if (_selectedIndex < 2) {
      setState(() => _selectedIndex++);
    }
  }

  void _handleSwipeRight() {
    if (_selectedIndex > 0) {
      setState(() => _selectedIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          // Check if velocity is significant enough
          final velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() > 100) {
            if (velocity < 0) {
              // Swiped left
              _handleSwipeLeft();
            } else {
              // Swiped right
              _handleSwipeRight();
            }
          }
        },
        child: Stack(
          children: [
            // Main content
            _widgetOptions.elementAt(_selectedIndex),

          // Navigation bar overlay με transparent background
          Positioned(
            bottom: 10, // Figma: bottom: 10px
            left: 6,
            right: 6,
            child: Center(
              child: Container(
                width: 400,
                height: 45, // Figma: height: 45px
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD966),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_outlined),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade700,
                    ),
                    _buildNavItem(1, Icons.list_alt),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade700,
                    ),
                    _buildNavItem(2, Icons.calendar_month),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
        ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Icon(
        icon,
        size: 24,
        color: isSelected ? const Color(0xFF671A1A) : Colors.black54,
      ),
    );
  }
}
