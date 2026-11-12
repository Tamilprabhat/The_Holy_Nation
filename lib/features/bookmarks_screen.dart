import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import 'bible_reading_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllBookmarks();
    if (mounted) {
      setState(() {
        _bookmarks = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeBookmark(int bookId, int chapter, int verse) async {
    await DatabaseHelper.instance.toggleBookmark(bookId, chapter, verse);
    _loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A24),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bookmarks (சேமித்த வசனங்கள்)',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.indigoAccent),
            )
          : _bookmarks.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'இதுவரை எந்த வசனமும் புக்மார்க் செய்யப்படவில்லை.\nவசனங்களைப் படிக்கும்போது Bookmark ஐகானை அழுத்திச் சேமிக்கலாம்.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookmarks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _bookmarks[index];
                    final nameTa = item['name_ta'] ?? '';
                    final nameEn = item['name_en'] ?? '';
                    final ch = item['chapter'] ?? 1;
                    final v = item['verse'] ?? 1;
                    final textTa = item['text_ta'] ?? '';
                    final textEn = item['text_en'] ?? '';

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BibleReadingScreen(
                              book: {
                                'id': item['book_id'],
                                'name_ta': nameTa,
                                'name_en': nameEn,
                                'testament': item['testament'],
                                'chapters_count': item['chapters_count'],
                              },
                              initialChapter: ch,
                              highlightVerse: v,
                            ),
                          ),
                        );
                        _loadBookmarks();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$nameTa ($nameEn) $ch:$v',
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _removeBookmark(item['book_id'], ch, v),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (textTa.isNotEmpty)
                              Text(
                                textTa,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            if (textEn.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                textEn,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
