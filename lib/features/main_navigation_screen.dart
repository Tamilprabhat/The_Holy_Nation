import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'bible_reading_screen.dart';
import 'pas_d_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  static const Map<String, dynamic> _defaultBook = {
    'id': 1,
    'name_ta': 'ஆதியாகமம்',
    'name_en': 'Genesis',
    'testament': 'OT',
    'chapters_count': 50,
  };

  final List<Widget> _screens = [
    const HomeScreen(),
    const BibleReadingScreen(book: _defaultBook),
    const PasDScreen(),
    const _ComingSoonScreen(
      title: 'Holy Community',
      subtitle: 'Praise God & Heart Tells சமூகப் பகிர்வு பகுதி (Phase 5)',
      icon: Icons.forum_rounded,
    ),
    const _ComingSoonScreen(
      title: 'Profile & Settings',
      subtitle: 'உங்கள் கணக்கு மற்றும் அமைப்புகள் (Phase 8 & 9)',
      icon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const cardDark = Color(0xFF1A1D24);
    const goldAccent = Color(0xFFD4AF37);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: cardDark,
        selectedItemColor: goldAccent,
        unselectedItemColor: Colors.white54,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Bible',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Pas D',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ComingSoonScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0F1115);
    const goldAccent = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: goldAccent),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
