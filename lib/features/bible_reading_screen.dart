import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';

class BibleReadingScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  final int initialChapter;

  const BibleReadingScreen({
    super.key,
    required this.book,
    this.initialChapter = 1,
  });

  @override
  State<BibleReadingScreen> createState() => _BibleReadingScreenState();
}

class _BibleReadingScreenState extends State<BibleReadingScreen> {
  late int _selectedChapter;
  int _totalChapters = 1;
  bool _isLoading = true;
  List<Map<String, dynamic>> _verses = [];

  @override
  void initState() {
    super.initState();
    _selectedChapter = widget.initialChapter;
    _initData();
  }

  Future<void> _initData() async {
    final count = await DatabaseHelper.instance.getChapterCount(widget.book['id']);
    if (mounted) {
      setState(() {
        _totalChapters = count > 0 ? count : 1;
      });
      _loadVerses();
    }
  }

  Future<void> _loadVerses() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getVerses(
      widget.book['id'],
      _selectedChapter,
    );
    if (mounted) {
      setState(() {
        _verses = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        title: Text(
          '${widget.book['name']} $_selectedChapter',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.list, color: Colors.white),
            tooltip: 'அதிகாரங்கள்',
            onSelected: (chapter) {
              setState(() {
                _selectedChapter = chapter;
              });
              _loadVerses();
            },
            itemBuilder: (context) {
              return List.generate(_totalChapters, (index) {
                final ch = index + 1;
                return PopupMenuItem(
                  value: ch,
                  child: Text('அதிகாரம் $ch'),
                );
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
          : _verses.isEmpty
              ? const Center(
                  child: Text(
                    'இந்த அதிகாரத்தில் வசனங்கள் இல்லை.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _verses.length,
                  itemBuilder: (context, index) {
                    final item = _verses[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.indigoAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item['verse']}',
                              style: const TextStyle(
                                color: Colors.indigoAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['text'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
