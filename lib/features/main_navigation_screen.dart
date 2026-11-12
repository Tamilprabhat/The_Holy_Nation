import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import 'bible_reading_screen.dart';
import 'bible_search_screen.dart';
import 'bookmarks_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _openBibleReading(dynamic book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleReadingScreen(book: book),
      ),
    );
  }

  Widget _buildHomeTab() {
    return const HomeScreen();
  }

  Widget _buildBibleTab() {
    return FutureBuilder(
      future: DatabaseHelper.instance.getAllBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.indigoAccent));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final books = (snapshot.data as List?) ?? [];
        if (books.isEmpty) {
          return const Center(
            child: Text(
              'புத்தகங்கள் எதுவும் காணப்படவில்லை',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: books.length,
          separatorBuilder: (context, index) =>
              const Divider(color: Colors.white10),
          itemBuilder: (context, index) {
            final book = books[index];

            final String nameTa = (book['name_ta'] ?? '').toString();
            final String nameEn = (book['name_en'] ?? '').toString();
            final String bookTitle = nameTa.isNotEmpty
                ? (nameEn.isNotEmpty ? '$nameTa ($nameEn)' : nameTa)
                : nameEn;

            final String rawTestament =
                (book['testament'] ?? '').toString().trim();
            final String testamentText =
                rawTestament.toLowerCase().contains('testament')
                    ? rawTestament
                    : '$rawTestament Testament';

            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: const Color(0xFF1E1E2C),
              leading: CircleAvatar(
                backgroundColor: Colors.indigoAccent,
                child: Text(
                  '${book['id']}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                bookTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                '$testamentText • ${book['chapters_count'] ?? 0} Chapters',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 16),
              onTap: () => _openBibleReading(book),
            );
          },
        );
      },
    );
  }

  Widget _buildPasDTab() {
    return const Center(
      child: Text('Pas D Screen',
          style: TextStyle(color: Colors.white70, fontSize: 18)),
    );
  }

  Widget _buildCommunityTab() {
    return const Center(
      child: Text('Community Screen',
          style: TextStyle(color: Colors.white70, fontSize: 18)),
    );
  }

  Widget _buildProfileTab() {
    return const Center(
      child: Text('Profile Screen',
          style: TextStyle(color: Colors.white70, fontSize: 18)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeTab(),
      _buildBibleTab(),
      _buildPasDTab(),
      _buildCommunityTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        title: Text(
          _currentIndex == 1 ? 'Bible' : 'THE HOLY NATION',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        centerTitle: true,
        actions: _currentIndex == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  tooltip: 'Search Verses',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BibleSearchScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.bookmarks_outlined,
                      color: Colors.amberAccent),
                  tooltip: 'Saved Bookmarks',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BookmarksScreen(),
                      ),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E2C),
        selectedItemColor: Colors.indigoAccent,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Bible'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'Pas D'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
