import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import 'bible_reading_screen.dart'; // இதுதான் நாம் சேர்க்க வேண்டிய முக்கியமான வரி!

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  Widget _buildBibleScreen() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getAllBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading books'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No books found.'));
        }

        final books = snapshot.data!;
        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return ListTile(
              title: Text(book['name_ta'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text(book['name_en']),
              leading: CircleAvatar(
                child: Text(book['id'].toString()),
              ),
              onTap: () {
                // புத்தகத்தைத் தொட்டால் அதிகாரங்கள்/வசனங்கள் திரைக்குச் செல்லும்
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BibleReadingScreen(book: book),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<Widget> get _pages => [
    const Center(child: Text('Home Feed\n(சமூகப் பகிர்வு)', textAlign: TextAlign.center)),
    _buildBibleScreen(),
    const Center(child: Text('Pas D\n(AI Digital Pastor)', textAlign: TextAlign.center)),
    const Center(child: Text('Community\n(குழுக்கள் & உரையாடல்)', textAlign: TextAlign.center)),
    const Center(child: Text('Profile\n(பயனர் சுயவிவரம்)', textAlign: TextAlign.center)),
  ];

  final List<String> _titles = const [
    'Home',
    'Bible',
    'Pas D',
    'Community',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Bible',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'Pas D',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
