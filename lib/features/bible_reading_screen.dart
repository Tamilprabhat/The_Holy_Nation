import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';

class BibleReadingScreen extends StatefulWidget {
  final Map<String, dynamic> book;

  const BibleReadingScreen({super.key, required this.book});

  @override
  State<BibleReadingScreen> createState() => _BibleReadingScreenState();
}

class _BibleReadingScreenState extends State<BibleReadingScreen> {
  int _selectedChapter = 1;
  int _totalChapters = 0;
  List<Map<String, dynamic>> _verses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    final count = await DatabaseHelper.instance.getChapterCount(widget.book['id']);
    setState(() {
      _totalChapters = count;
    });
    if (count > 0) {
      _loadVerses(_selectedChapter);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVerses(int chapter) async {
    setState(() {
      _isLoading = true;
    });
    final verses = await DatabaseHelper.instance.getVerses(widget.book['id'], chapter);
    setState(() {
      _verses = verses;
      _selectedChapter = chapter;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.book['name_ta']} ($_selectedChapter)'),
      ),
      body: Column(
        children: [
          // அதிகாரங்களைத் தேர்ந்தெடுக்கும் பகுதி
          if (_totalChapters > 0)
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _totalChapters,
                itemBuilder: (context, index) {
                  final chapterNum = index + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                    child: ChoiceChip(
                      label: Text('$chapterNum'),
                      selected: _selectedChapter == chapterNum,
                      onSelected: (selected) {
                        if (selected) _loadVerses(chapterNum);
                      },
                    ),
                  );
                },
              ),
            ),
          const Divider(height: 1),
          // வசனங்களைக் காட்டும் பகுதி
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _verses.isEmpty
                    ? const Center(child: Text('வசனங்கள் கிடைக்கவில்லை'))
                    : ListView.builder(
                        itemCount: _verses.length,
                        itemBuilder: (context, index) {
                          final verse = _verses[index];
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${verse['verse']}. ',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Expanded(
                                      child: Text(
                                        verse['text_ta'],
                                        style: const TextStyle(fontSize: 18, height: 1.5),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20.0),
                                  child: Text(
                                    verse['text_en'],
                                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                                  ),
                                ),
                                const Divider(),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
