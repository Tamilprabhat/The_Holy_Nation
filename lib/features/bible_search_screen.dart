import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import 'bible_reading_screen.dart';

class BibleSearchScreen extends StatefulWidget {
  const BibleSearchScreen({super.key});

  @override
  State<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends State<BibleSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final data = await DatabaseHelper.instance.searchVerses(trimmed);
    if (mounted) {
      setState(() {
        _results = data;
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
          decoration: InputDecoration(
            hintText: 'வசனங்களைத் தேடுங்கள் (தமிழ் / English)...',
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() {});
            if (val.trim().length >= 3) {
              _performSearch(val);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.indigoAccent),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _isSearching
          ? const Center(
              child: CircularProgressIndicator(color: Colors.indigoAccent),
            )
          : !_hasSearched
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'எந்தவொரு தமிழ் அல்லது ஆங்கில வார்த்தையையும் தட்டச்சு செய்து தேடுங்கள்.\n(உதா: அன்பு, சமாதானம், Love, Grace)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                )
              : _results.isEmpty
                  ? const Center(
                      child: Text(
                        'பொருத்தமான வசனங்கள் எதுவும் கிடைக்கவில்லை.',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 20, color: Colors.white10),
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        final nameTa = item['name_ta'] ?? '';
                        final nameEn = item['name_en'] ?? '';
                        final ch = item['chapter'] ?? 1;
                        final v = item['verse'] ?? 1;
                        final textTa = item['text_ta'] ?? '';
                        final textEn = item['text_en'] ?? '';

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
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
                                Text(
                                  '$nameTa ($nameEn) $ch:$v',
                                  style: const TextStyle(
                                    color: Colors.indigoAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
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
