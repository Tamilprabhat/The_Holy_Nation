import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import 'bible_reading_screen.dart';

class BibleSearchScreen extends StatefulWidget {
  const BibleSearchScreen({super.key});

  @override
  State createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends State {
  final TextEditingController _searchController = TextEditingController();
  List _allResults = [];
  List _bookStats = [];
  int? _selectedBookId;
  String _testamentFilter = 'ALL'; // ALL, OT, NT
  bool _showBookBreakdown = true;
  bool _isSearching = false;
  bool _hasSearched = false;

  Future _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _allResults = [];
        _bookStats = [];
        _selectedBookId = null;
        _testamentFilter = 'ALL';
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _selectedBookId = null;
      _testamentFilter = 'ALL';
      _showBookBreakdown = true;
    });

    final data = await DatabaseHelper.instance.searchVerses(trimmed);
    if (!mounted) return;

    final Map grouped = {};
    for (final row in data) {
      final int bId = row['book_id'] ?? 0;
      if (!grouped.containsKey(bId)) {
        grouped[bId] = {
          'book_id': bId,
          'name_ta': row['name_ta'] ?? '',
          'name_en': row['name_en'] ?? '',
          'count': 1,
        };
      } else {
        grouped[bId]['count'] = (grouped[bId]['count'] as int) + 1;
      }
    }

    final statsList = grouped.values.toList();
    statsList.sort((a, b) => (a['book_id'] as int).compareTo(b['book_id'] as int));

    setState(() {
      _allResults = data;
      _bookStats = statsList;
      _isSearching = false;
    });
  }

  List get _filteredResults {
    return _allResults.where((item) {
      final int bId = item['book_id'] ?? 0;
      if (_selectedBookId != null) {
        return bId == _selectedBookId;
      }
      if (_testamentFilter == 'OT') {
        return bId <= 39;
      }
      if (_testamentFilter == 'NT') {
        return bId > 39;
      }
      return true;
    }).toList();
  }

  int get _otCount =>
      _allResults.where((item) => (item['book_id'] ?? 0) <= 39).length;

  int get _ntCount =>
      _allResults.where((item) => (item['book_id'] ?? 0) > 39).length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleResults = _filteredResults;

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
            hintText: 'வசனங்களைத் தேடுக (தமிழ் / English)...',
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
            if (val.trim().length >= 2) {
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
                      'ஏதேனும் ஒரு தமிழ் அல்லது ஆங்கில வார்த்தையைத் தட்டச்சு செய்து தேடுங்கள்.\n(உதா: அன்பு, சமாதானம், பரிசுத்த, Peace)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                )
              : _allResults.isEmpty
                  ? const Center(
                      child: Text(
                        'பொருத்தமான வசனங்கள் எதுவும் கிடைக்கவில்லை.',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                          color: const Color(0xFF181A24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'மொத்தம் ${_allResults.length} வசனங்கள் (${_bookStats.length} புத்தகங்கள்)',
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _showBookBreakdown =
                                            !_showBookBreakdown;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF262A3B),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: Colors.indigoAccent),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _showBookBreakdown
                                                ? Icons.expand_less
                                                : Icons.menu_book_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _showBookBreakdown
                                                ? 'புத்தகப் பட்டியலை மறை'
                                                : 'புத்தகம் வாரியாகப் பார்',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip(
                                      label:
                                          'அனைத்தும் (${_allResults.length})',
                                      selected: _selectedBookId == null &&
                                          _testamentFilter == 'ALL',
                                      onTap: () {
                                        setState(() {
                                          _selectedBookId = null;
                                          _testamentFilter = 'ALL';
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _buildFilterChip(
                                      label: 'பழைய ஏற்பாடு ($_otCount)',
                                      selected: _selectedBookId == null &&
                                          _testamentFilter == 'OT',
                                      onTap: () {
                                        setState(() {
                                          _selectedBookId = null;
                                          _testamentFilter = 'OT';
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _buildFilterChip(
                                      label: 'புதிய ஏற்பாடு ($_ntCount)',
                                      selected: _selectedBookId == null &&
                                          _testamentFilter == 'NT',
                                      onTap: () {
                                        setState(() {
                                          _selectedBookId = null;
                                          _testamentFilter = 'NT';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              if (_showBookBreakdown) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 36,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _bookStats.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, idx) {
                                      final st = _bookStats[idx];
                                      final int bId = st['book_id'];
                                      final bool isSel =
                                          _selectedBookId == bId;
                                      return InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () {
                                          setState(() {
                                            _selectedBookId =
                                                isSel ? null : bId;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isSel
                                                ? Colors.amberAccent
                                                : const Color(0xFF1E222D),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: isSel
                                                  ? Colors.amberAccent
                                                  : Colors.white12,
                                            ),
                                          ),
                                          child: Text(
                                            '${st['name_ta']} (${st['count']})',
                                            style: TextStyle(
                                              color: isSel
                                                  ? Colors.black
                                                  : Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(14),
                            itemCount: visibleResults.length,
                            separatorBuilder: (context, index) =>
                                const Divider(
                                    height: 20, color: Colors.white10),
                            itemBuilder: (context, index) {
                              final item = visibleResults[index];
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
                                          'chapters_count':
                                              item['chapters_count'],
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
                                    color: const Color(0xFF1E212D),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                        ),
                      ],
                    ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3E50B5) : const Color(0xFF1E222D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.indigoAccent : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
