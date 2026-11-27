import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import 'home_screen.dart';
import 'bible_reading_screen.dart';
import 'pas_d_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';
import 'onboarding_verification_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State {
  int _currentIndex = 0;
  bool _checkingVerification = true;
  bool _isVerified = false;

  static const _defaultBook = {
    'id': 1,
    'name_ta': 'ஆதியாகமம்',
    'name_en': 'Genesis',
    'testament': 'OT',
    'chapters_count': 50,
  };

  final _screens = [
    const HomeScreen(),
    const BibleReadingScreen(book: _defaultBook),
    const PasDScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUserVerification();
  }

  Future _checkUserVerification() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profile (
          id INTEGER PRIMARY KEY,
          user_name TEXT NOT NULL,
          new_name TEXT NOT NULL DEFAULT '',
          church_city TEXT NOT NULL,
          church_type TEXT NOT NULL DEFAULT '',
          life_verse TEXT NOT NULL,
          favorite_book TEXT NOT NULL DEFAULT '',
          favorite_song TEXT NOT NULL DEFAULT '',
          spiritual_category TEXT NOT NULL DEFAULT '',
          avatar_path TEXT,
          verification_selfie_path TEXT,
          is_verified INTEGER NOT NULL DEFAULT 0,
          daily_reminder INTEGER NOT NULL DEFAULT 1,
          prayer_reminder INTEGER NOT NULL DEFAULT 1
        )
      ''');
      try {
        await db.execute(
            'ALTER TABLE user_profile ADD COLUMN is_verified INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}

      final rows = await db.query('user_profile', where: 'id = 1');
      bool verified = false;
      if (rows.isNotEmpty) {
        verified = (rows.first['is_verified'] ?? 0) == 1;
      }

      if (!mounted) return;
      setState(() {
        _isVerified = verified;
        _checkingVerification = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVerified = false;
        _checkingVerification = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color cardDark = Color(0xFF181A24);
    const Color goldAccent = Color(0xFFE4AF37);

    if (_checkingVerification) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1115),
        body: Center(
          child: CircularProgressIndicator(color: goldAccent),
        ),
      );
    }

    if (!_isVerified) {
      return OnboardingVerificationScreen(
        onVerificationCompleted: () {
          setState(() {
            _isVerified = true;
          });
        },
      );
    }

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
