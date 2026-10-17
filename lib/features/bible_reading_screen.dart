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
  bool _isTamilPrimary = true; // தமிழ் முதன்மை அல்லது ஆங்கிலம் முதன்மை என்பதைக் கட்டுப்படுத்தும் நிலை
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
        _totalChapters = count > 0 ? count : (widget.book['chapters_count'] ?? 1);
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
    // முதன்மை மொழிக்கு ஏற்ப தலைப்பு பெயர் மாறும்
    final bookName = _isTamilPrimary
        ? (widget.book['name_ta'] ?? widget.book['name'] ?? '')
        : (widget.book['name_en'] ?? widget.book['name_ta'] ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFF12141D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A24),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$bookName ($_selectedChapter)',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 19),
        ),
        centerTitle: true,
        actions: [
          // மொழி முன்னுரிமையை மாற்றும் பட்டன் (TA / EN Switcher)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                _isTamilPrimary = !_isTamilPrimary;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E6B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.indigoAccent),
              ),
              child: Row(
                children: [
                  const Icon(Icons.translate, size: 16, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    _isTamilPrimary ? 'TA' : 'EN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // அதிகாரங்களை மாற்றும் கிடைமட்ட வரிசை (Horizontal Chapter Selector)
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _totalChapters,
              itemBuilder: (context, index) {
                final ch = index + 1;
                final isSelected = ch == _selectedChapter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() => _selectedChapter = ch);
                      _loadVerses();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2C3E6B) : const Color(0xFF1C1E2A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.indigoAccent : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '$ch',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.white12),

          // வசனங்கள் பட்டியல்
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _verses.length,
                    separatorBuilder: (context, index) => const Divider(height: 28, color: Colors.white10),
                    itemBuilder: (context, index) {
                      final verse = _verses[index];
                      final taText = verse['text_ta'] ?? verse['text'] ?? '';
                      final enText = verse['text_en'] ?? '';

                      // பயனர் தேர்வுக்கேற்ப முதன்மை மற்றும் துணை உரையைத் தீர்மானித்தல்
                      final primaryText = _isTamilPrimary ? taText : enText;
                      final secondaryText = _isTamilPrimary ? enText : taText;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // முதன்மை வசனம் (பெரிய எழுத்து)
                          Text(
                            '${verse['verse']}. $primaryText',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                          if (secondaryText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            // துணை வசனம் (சிறிய எழுத்து)
                            Text(
                              secondaryText,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                                fontStyle: _isTamilPrimary ? FontStyle.italic : FontStyle.normal,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
