import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/local/database_helper.dart';
import 'bible_search_screen.dart';
import 'bookmarks_screen.dart';

class BibleReadingScreen extends StatefulWidget {
  final dynamic book;
  final int initialChapter;
  final int? highlightVerse;
  final String? initialPrimaryLang;

  const BibleReadingScreen({
    super.key,
    required this.book,
    this.initialChapter = 1,
    this.highlightVerse,
    this.initialPrimaryLang,
  });

  @override
  State createState() => _BibleReadingScreenState();
}

class _BibleReadingScreenState extends State {
  BibleReadingScreen get _screen => widget as BibleReadingScreen;

  dynamic _currentBook;
  late int _selectedChapter;
  int? _activeHighlightVerse;
  int _totalChapters = 1;
  bool _isLoading = true;
  String _primaryLang = 'ta';
  String _secondaryLang = 'en';
  bool _showBookList = true;
  bool _isPushedRoute = false;
  bool _routeChecked = false;
  List _books = [];
  List _verses = [];
  Set _bookmarkedVerses = {};

  final List _bibleLanguages = [
    {'code': 'ta', 'short': 'TA', 'name': 'தமிழ் (Tamil)'},
    {'code': 'en', 'short': 'EN', 'name': 'English (KJV)'},
    {'code': 'hi', 'short': 'HI', 'name': 'हिन्दी (Hindi)'},
    {'code': 'ml', 'short': 'ML', 'name': 'മലയാളം (Malayalam)'},
    {'code': 'te', 'short': 'TE', 'name': 'తెలుగు (Telugu)'},
    {'code': 'kn', 'short': 'KN', 'name': 'ಕನ್ನಡ (Kannada)'},
    {'code': 'bn', 'short': 'BN', 'name': 'বাংলা (Bengali)'},
    {'code': 'mr', 'short': 'MR', 'name': 'मराठी (Marathi)'},
    {'code': 'gu', 'short': 'GU', 'name': 'ગુજરાતી (Gujarati)'},
    {'code': 'pa', 'short': 'PA', 'name': 'ਪੰਜਾਬੀ (Punjabi)'},
  ];

  final ScrollController _scrollController = ScrollController();
  Timer? _readingTimer;
  int _secondsSpent = 0;
  int _requiredSeconds = 15;
  double _maxScrollRatio = 0.0;
  bool _isChapterCounted = false;

  @override
  void initState() {
    super.initState();
    _currentBook = _screen.book;
    _selectedChapter = _screen.initialChapter;
    _activeHighlightVerse = _screen.highlightVerse;
    if (_screen.initialPrimaryLang != null &&
        _screen.initialPrimaryLang!.isNotEmpty) {
      _primaryLang = _screen.initialPrimaryLang!;
      if (_primaryLang == _secondaryLang) {
        _secondaryLang = _primaryLang == 'en' ? 'ta' : 'en';
      }
    }
    _scrollController.addListener(_onScroll);
    _initData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeChecked) {
      _routeChecked = true;
      _isPushedRoute = ModalRoute.of(context)?.canPop ?? false;
      if (_isPushedRoute || _screen.highlightVerse != null) {
        _showBookList = false;
      } else {
        _showBookList = true;
      }
    }
  }

  @override
  void dispose() {
    _readingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String _getLangBadge() {
    final pShort = _primaryLang.toUpperCase();
    if (_secondaryLang == 'none') return pShort;
    return '$pShort+${_secondaryLang.toUpperCase()}';
  }

  String _getVerseTextByCode(dynamic verse, String code) {
    if (code == 'none' || verse == null) return '';
    final key = 'text_$code';
    final val = verse[key]?.toString().trim() ?? '';
    if (val.isNotEmpty) return val;
    if (code == 'ta') return verse['text_ta']?.toString() ?? '';
    return '';
  }

  void _openLanguagePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Icon(Icons.translate, color: Colors.amberAccent),
                        SizedBox(width: 8),
                        Text(
                          'வேதாகம மொழிகளைத் தேர்ந்தெடுக்கவும்',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '1. முதன்மை மொழி (Primary Language):',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final lang in _bibleLanguages)
                          ChoiceChip(
                            selected: _primaryLang == lang['code'],
                            backgroundColor: const Color(0xFF1E222D),
                            selectedColor: Colors.indigoAccent,
                            label: Text(
                              lang['name']!,
                              style: TextStyle(
                                color: _primaryLang == lang['code']
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onSelected: (_) {
                              setModalState(() {
                                _primaryLang = lang['code']!;
                                if (_secondaryLang == _primaryLang) {
                                  _secondaryLang = 'none';
                                }
                              });
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '2. துணை மொழி (Secondary Language - கீழே காட்ட):',
                      style: TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          selected: _secondaryLang == 'none',
                          backgroundColor: const Color(0xFF1E222D),
                          selectedColor: Colors.teal.shade700,
                          label: Text(
                            'வேண்டாம் (Single)',
                            style: TextStyle(
                              color: _secondaryLang == 'none'
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onSelected: (_) {
                            setModalState(() => _secondaryLang = 'none');
                            setState(() {});
                          },
                        ),
                        for (final lang in _bibleLanguages)
                          if (lang['code'] != _primaryLang)
                            ChoiceChip(
                              selected: _secondaryLang == lang['code'],
                              backgroundColor: const Color(0xFF1E222D),
                              selectedColor: Colors.teal.shade700,
                              label: Text(
                                lang['name']!,
                                style: TextStyle(
                                  color: _secondaryLang == lang['code']
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onSelected: (_) {
                                setModalState(() {
                                  _secondaryLang = lang['code']!;
                                });
                                setState(() {});
                              },
                            ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigoAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'சரி (Apply Languages)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isChapterCounted || _showBookList) {
      return;
    }
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    if (maxScroll <= 0) {
      _maxScrollRatio = 1.0;
    } else {
      final ratio = (currentScroll / maxScroll).clamp(0.0, 1.0);
      if (ratio > _maxScrollRatio) {
        _maxScrollRatio = ratio;
      }
    }

    _evaluateReadingCompletion();
  }

  void _startReadingTracker(int verseCount, bool alreadyRead) {
    _readingTimer?.cancel();
    _secondsSpent = 0;
    _maxScrollRatio = 0.0;
    _isChapterCounted = alreadyRead;

    if (_showBookList || alreadyRead) return;

    _requiredSeconds = (verseCount * 0.7).round().clamp(12, 40);

    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _showBookList) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsSpent++;
      });

      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent <= 20) {
        _maxScrollRatio = 1.0;
      }

      _evaluateReadingCompletion();
    });
  }

  Future _evaluateReadingCompletion() async {
    if (_isChapterCounted || _showBookList) return;
    if (_secondsSpent >= _requiredSeconds && _maxScrollRatio >= 0.85) {
      _isChapterCounted = true;
      _readingTimer?.cancel();
      await DatabaseHelper.instance.recordChapterRead(
        _currentBook['id'],
        _selectedChapter,
      );
      if (mounted) {
        setState(() {});
        final bName = _currentBook['name_ta'] ?? _currentBook['name'] ?? '';
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ $bName அதிகாரம் $_selectedChapter முழுமையாக வாசித்ததாகப் பதியப்பட்டது!',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.teal.shade800,
          ),
        );
      }
    }
  }

  Future _initData() async {
    final allBooks = await DatabaseHelper.instance.getAllBooks();
    final count =
        await DatabaseHelper.instance.getChapterCount(_currentBook['id']);
    if (mounted) {
      setState(() {
        _books = allBooks;
        _totalChapters =
            count > 0 ? count : (_currentBook['chapters_count'] ?? 1);
      });
    }
    _loadVerses();
  }

  Future _loadVerses() async {
    setState(() => _isLoading = true);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    final alreadyRead = await DatabaseHelper.instance.isChapterAlreadyRead(
      _currentBook['id'],
      _selectedChapter,
    );
    final data = await DatabaseHelper.instance.getVerses(
      _currentBook['id'],
      _selectedChapter,
    );
    final bookmarks =
        await DatabaseHelper.instance.getBookmarkedVerseNumbers(
      _currentBook['id'],
      _selectedChapter,
    );

    if (mounted) {
      setState(() {
        _verses = data;
        _bookmarkedVerses = Set.from(bookmarks);
        _isLoading = false;
      });
      _startReadingTracker(data.length, alreadyRead);
    }
  }

  Future _selectBook(dynamic selectedBook) async {
    _readingTimer?.cancel();
    final count =
        await DatabaseHelper.instance.getChapterCount(selectedBook['id']);
    if (mounted) {
      setState(() {
        _currentBook = selectedBook;
        _selectedChapter = 1;
        _activeHighlightVerse = null;
        _totalChapters =
            count > 0 ? count : (selectedBook['chapters_count'] ?? 1);
        _showBookList = false;
      });
    }
    _loadVerses();
  }

  Future _openSearchScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BibleSearchScreen()),
    );
    if (!_showBookList) {
      _loadVerses();
    }
  }

  Future _openBookmarksScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookmarksScreen()),
    );
    if (!_showBookList) {
      _loadVerses();
    }
  }

  Future _onToggleBookmark(int verseNum) async {
    final added = await DatabaseHelper.instance.toggleBookmark(
      _currentBook['id'],
      _selectedChapter,
      verseNum,
    );
    if (!mounted) return;
    setState(() {
      if (added) {
        _bookmarkedVerses.add(verseNum);
      } else {
        _bookmarkedVerses.remove(verseNum);
      }
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? 'வசனம் $_selectedChapter:$verseNum புக்மார்க் செய்யப்பட்டது'
              : 'புக்மார்க் நீக்கப்பட்டது',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.indigo.shade700,
      ),
    );
  }

  void _copyVerse(dynamic verse) {
    final bookTa = _currentBook['name_ta'] ?? _currentBook['name'] ?? '';
    final bookEn = _currentBook['name_en'] ?? '';
    final vNum = verse['verse'];
    final pText = _getVerseTextByCode(verse, _primaryLang);
    final sText = _getVerseTextByCode(verse, _secondaryLang);

    final formatted = sText.isNotEmpty
        ? '$bookTa ($bookEn) $_selectedChapter:$vNum\n$pText\n$sText\n— THE HOLY NATION'
        : '$bookTa ($bookEn) $_selectedChapter:$vNum\n$pText\n— THE HOLY NATION';

    Clipboard.setData(ClipboardData(text: formatted));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('வசனம் நகலெடுக்கப்பட்டது (Copied to clipboard)'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Widget _buildBookSelectionView() {
    final oldTestament = _books.where((b) => (b['id'] ?? 0) <= 39).toList();
    final newTestament = _books.where((b) => (b['id'] ?? 0) > 39).toList();
    final bool isTamilMain = _primaryLang == 'ta';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF12141D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF181A24),
          elevation: 0,
          automaticallyImplyLeading: _isPushedRoute,
          leading: _isPushedRoute
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: const Text(
            'பரிசுத்த வேதாகமம்',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16.5,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white),
              tooltip: 'வசனங்களைத் தேடுக',
              onPressed: _openSearchScreen,
            ),
            IconButton(
              icon: const Icon(Icons.bookmarks_rounded,
                  color: Colors.amberAccent),
              tooltip: 'புக்மார்க்குகள்',
              onPressed: _openBookmarksScreen,
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _openLanguagePicker,
              child: Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF262A3B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.indigoAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.translate, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _getLangBadge(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.indigoAccent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'பழைய ஏற்பாடு (39)'),
              Tab(text: 'புதிய ஏற்பாடு (27)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookGrid(oldTestament, isTamilMain),
            _buildBookGrid(newTestament, isTamilMain),
          ],
        ),
      ),
    );
  }

  Widget _buildBookGrid(List bookList, bool isTamilMain) {
    if (bookList.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.indigoAccent),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: bookList.length,
      itemBuilder: (context, index) {
        final book = bookList[index];
        final nameTa = book['name_ta'] ?? book['name'] ?? '';
        final nameEn = book['name_en'] ?? '';
        final chaptersCount = book['chapters_count'] ?? '';

        return InkWell(
          onTap: () => _selectBook(book),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E212D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isTamilMain ? nameTa : nameEn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isTamilMain
                      ? '$nameEn • $chaptersCount அதி.'
                      : '$nameTa • $chaptersCount Ch.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleBackFromReading() {
    _readingTimer?.cancel();
    if (_isPushedRoute) {
      Navigator.pop(context);
    } else {
      setState(() {
        _showBookList = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isPushedRoute && !_showBookList,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!_showBookList) {
          _handleBackFromReading();
        }
      },
      child: _showBookList ? _buildBookSelectionView() : _buildReadingView(),
    );
  }

  Widget _buildReadingView() {
    final bookName = _primaryLang == 'ta'
        ? (_currentBook['name_ta'] ?? _currentBook['name'] ?? '')
        : (_currentBook['name_en'] ?? _currentBook['name_ta'] ?? '');

    final double timeProgress =
        (_secondsSpent / _requiredSeconds).clamp(0.0, 1.0);
    final double scrollProgress = (_maxScrollRatio / 0.85).clamp(0.0, 1.0);
    final double combinedProgress =
        _isChapterCounted ? 1.0 : ((timeProgress + scrollProgress) / 2);

    return Scaffold(
      backgroundColor: const Color(0xFF12141D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A24),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'புத்தகங்களைத் தேர்ந்தெடுக்க',
          onPressed: _handleBackFromReading,
        ),
        title: InkWell(
          onTap: () {
            _readingTimer?.cancel();
            setState(() {
              _showBookList = true;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '$bookName ($_selectedChapter)',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded,
                color: Colors.white, size: 20),
            tooltip: 'தேடுக',
            onPressed: _openSearchScreen,
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_rounded,
                color: Colors.amberAccent, size: 20),
            tooltip: 'புக்மார்க்குகள்',
            onPressed: _openBookmarksScreen,
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _openLanguagePicker,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF262A3B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.indigoAccent),
              ),
              child: Row(
                children: [
                  const Icon(Icons.translate, size: 14, color: Colors.white),
                  const SizedBox(width: 3),
                  Text(
                    _getLangBadge(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                      setState(() {
                        _selectedChapter = ch;
                        _activeHighlightVerse = null;
                      });
                      _loadVerses();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF3E50B5)
                            : const Color(0xFF1E212D),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.indigoAccent
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '$ch',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF1A1D29),
            child: Row(
              children: [
                Icon(
                  _isChapterCounted
                      ? Icons.verified_rounded
                      : Icons.auto_stories_rounded,
                  size: 15,
                  color: _isChapterCounted
                      ? Colors.tealAccent
                      : Colors.amberAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isChapterCounted
                        ? 'வாசிப்பு பதியப்பட்டது (Counted)'
                        : 'வாசிப்பு முறை: பொறுமையாக முழு அதிகாரத்தையும் வாசியுங்கள் (${(combinedProgress * 100).round()}%)',
                    style: TextStyle(
                      color: _isChapterCounted
                          ? Colors.tealAccent
                          : Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: combinedProgress,
            minHeight: 2.5,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(
              _isChapterCounted ? Colors.tealAccent : Colors.indigoAccent,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.indigoAccent),
                  )
                : _verses.isEmpty
                    ? const Center(
                        child: Text(
                          'வசனங்கள் கிடைக்கவில்லை',
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _verses.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 24, color: Colors.white10),
                        itemBuilder: (context, index) {
                          final verse = _verses[index];
                          final int verseNum = verse['verse'] ?? (index + 1);
                          final primaryText =
                              _getVerseTextByCode(verse, _primaryLang);
                          final secondaryText =
                              _getVerseTextByCode(verse, _secondaryLang);
                          final isBookmarked =
                              _bookmarkedVerses.contains(verseNum);
                          final isHighlighted =
                              _activeHighlightVerse == verseNum;

                          return Container(
                            padding: isHighlighted
                                ? const EdgeInsets.all(10)
                                : EdgeInsets.zero,
                            decoration: isHighlighted
                                ? BoxDecoration(
                                    color: Colors.indigo
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.indigoAccent
                                          .withValues(alpha: 0.5),
                                    ),
                                  )
                                : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$verseNum. $primaryText',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                                if (secondaryText.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    secondaryText,
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 14,
                                      fontStyle: _secondaryLang == 'en'
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: () => _onToggleBookmark(verseNum),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Icon(
                                          isBookmarked
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          size: 20,
                                          color: isBookmarked
                                              ? Colors.amberAccent
                                              : Colors.white38,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _copyVerse(verse),
                                      borderRadius: BorderRadius.circular(20),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Icon(
                                          Icons.copy_rounded,
                                          size: 18,
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
