import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/local/database_helper.dart';
import 'bible_reading_screen.dart';
import 'poster_creator_screen.dart';
import 'topic_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State {
  int _selectedDevotionTab = 0;

  dynamic _promiseVerse;
  dynamic _confessionVerse;
  List _posters = [];
  List _trendingPosts = [];
  int _totalChaptersRead = 0;
  dynamic _lastReadBook;
  bool _isLoading = true;

  final List _promiseList = [
    {'book_id': 23, 'chapter': 41, 'verse': 10},
    {'book_id': 6, 'chapter': 1, 'verse': 9},
    {'book_id': 43, 'chapter': 14, 'verse': 27},
    {'book_id': 24, 'chapter': 29, 'verse': 11},
    {'book_id': 50, 'chapter': 4, 'verse': 19},
    {'book_id': 19, 'chapter': 23, 'verse': 1},
    {'book_id': 19, 'chapter': 91, 'verse': 11},
  ];

  final List _confessionList = [
    {'book_id': 50, 'chapter': 4, 'verse': 13},
    {'book_id': 19, 'chapter': 138, 'verse': 8},
    {'book_id': 50, 'chapter': 1, 'verse': 6},
    {'book_id': 19, 'chapter': 23, 'verse': 1},
    {'book_id': 45, 'chapter': 8, 'verse': 37},
    {'book_id': 19, 'chapter': 27, 'verse': 1},
    {'book_id': 19, 'chapter': 118, 'verse': 6},
  ];

  final List _topicKeys = [
    'அன்பு (Love)',
    'விசுவாசம் (Faith)',
    'ஜெபம் (Prayer)',
    'சமாதானம் (Peace)',
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future _loadHomeData() async {
    final dayIndex = DateTime.now().day;
    final pCoord = _promiseList[dayIndex % _promiseList.length];
    final cCoord = _confessionList[dayIndex % _confessionList.length];

    final pVerse = await DatabaseHelper.instance.getSingleVerse(
      pCoord['book_id'],
      pCoord['chapter'],
      pCoord['verse'],
    );
    final cVerse = await DatabaseHelper.instance.getSingleVerse(
      cCoord['book_id'],
      cCoord['chapter'],
      cCoord['verse'],
    );

    final summary = await DatabaseHelper.instance.getReadingSummary();
    final activeCategory =
        _selectedDevotionTab == 0 ? 'promise' : 'confession';
    final postersData =
        await DatabaseHelper.instance.getPostersByCategory(activeCategory);

    final List topTopicCards = [];
    for (final key in _topicKeys) {
      final msgs = await DatabaseHelper.instance.getTopicMessages(key);
      if (msgs.isNotEmpty) {
        topTopicCards.add(msgs.first);
      }
    }
    topTopicCards.sort((a, b) =>
        (b['likes_count'] as int).compareTo(a['likes_count'] as int));

    if (mounted) {
      setState(() {
        _promiseVerse = pVerse;
        _confessionVerse = cVerse;
        _totalChaptersRead = summary['total_read'] ?? 0;
        _lastReadBook = summary['last_read'];
        _posters = postersData;
        _trendingPosts = topTopicCards;
        _isLoading = false;
      });
    }
  }

  Future _switchDevotionTab(int tabIndex) async {
    setState(() => _selectedDevotionTab = tabIndex);
    final category = tabIndex == 0 ? 'promise' : 'confession';
    final postersData =
        await DatabaseHelper.instance.getPostersByCategory(category);
    if (mounted) {
      setState(() => _posters = postersData);
    }
  }

  void _copyActiveVerse(dynamic verseData, String titleLabel) {
    if (verseData == null) return;
    final ref =
        '${verseData['name_ta']} (${verseData['name_en']}) ${verseData['chapter']}:${verseData['verse']}';
    final text =
        '$titleLabel - $ref\n\n${verseData['text_ta']}\n\n${verseData['text_en']}\n\n— THE HOLY NATION';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('வசனம் நகலெடுக்கப்பட்டது! இப்போது போஸ்டர் உருவாக்கலாம்.'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Future _openPosterCreator(dynamic verseData) async {
    if (verseData == null) return;
    final ref =
        '${verseData['name_ta']} (${verseData['name_en']}) ${verseData['chapter']}:${verseData['verse']}';
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PosterCreatorScreen(
          category: _selectedDevotionTab == 0 ? 'promise' : 'confession',
          initialRef: ref,
          initialText: verseData['text_ta'] ?? '',
        ),
      ),
    );
    if (created == true) {
      _switchDevotionTab(_selectedDevotionTab);
    }
  }

  Map _calculateRankInfo(int readCount) {
    final List leaderboard = [
      {'name': 'பவுல் (Paul)', 'chapters': 120},
      {'name': 'எஸ்தர் (Esther)', 'chapters': 80},
      {'name': 'தாவீது (David)', 'chapters': 45},
      {'name': 'ரூத் (Ruth)', 'chapters': 15},
      {'name': 'யோசேப்பு (Joseph)', 'chapters': 4},
    ];

    int rank = 1;
    String nextTargetName = '';
    int chaptersNeeded = 0;

    for (int i = 0; i < leaderboard.length; i++) {
      if (readCount < leaderboard[i]['chapters']) {
        rank = i + 2;
        nextTargetName = leaderboard[i]['name'];
        chaptersNeeded = (leaderboard[i]['chapters'] as int) - readCount + 1;
      }
    }

    return {
      'rank': rank,
      'nextName': nextTargetName,
      'needed': chaptersNeeded,
    };
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F1115);
    const Color cardDark = Color(0xFF181A24);
    const Color goldAccent = Color(0xFFE4AF37);

    final bool isPromise = _selectedDevotionTab == 0;
    final activeVerse = isPromise ? _promiseVerse : _confessionVerse;
    final rankInfo = _calculateRankInfo(_totalChaptersRead);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: cardDark,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: goldAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.church_rounded,
                color: goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'THE HOLY NATION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'பரிசுத்த ஜாதி • Spiritual Companion',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.indigoAccent),
            )
          : RefreshIndicator(
              onRefresh: _loadHomeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchDevotionTab(0),
                            child: Container(
                              height: 44,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isPromise
                                    ? const Color(0xFF283593)
                                    : const Color(0xFF1E1E2C),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isPromise
                                      ? Colors.indigoAccent
                                      : Colors.white12,
                                ),
                              ),
                              child: Text(
                                'இன்றைய வாக்குத்தத்தம்',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      isPromise ? Colors.white : Colors.white60,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchDevotionTab(1),
                            child: Container(
                              height: 44,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !isPromise
                                    ? const Color(0xFF1B4332)
                                    : const Color(0xFF1E1E2C),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: !isPromise
                                      ? Colors.tealAccent
                                      : Colors.white12,
                                ),
                              ),
                              child: Text(
                                'இன்றைய விசுவாச அறிக்கை',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !isPromise
                                      ? Colors.white
                                      : Colors.white60,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (activeVerse != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E222D),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              isPromise
                                  ? 'தேவனின் வாக்குத்தத்தம்'
                                  : 'விசுவாச அறிக்கை',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isPromise
                                    ? Colors.amberAccent
                                    : Colors.tealAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${activeVerse['name_ta']} (${activeVerse['name_en']}) ${activeVerse['chapter']}:${activeVerse['verse']}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              activeVerse['text_ta'] ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              activeVerse['text_en'] ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.white24),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () => _copyActiveVerse(
                                      activeVerse,
                                      isPromise
                                          ? 'இன்றைய வாக்குத்தத்தம்'
                                          : 'இன்றைய விசுவாச அறிக்கை',
                                    ),
                                    icon: const Icon(Icons.copy_rounded,
                                        size: 16),
                                    label: const Text(
                                      'Copy (நகலெடு)',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigoAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () =>
                                        _openPosterCreator(activeVerse),
                                    icon: const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 17),
                                    label: const Text(
                                      'போஸ்டர் உருவாக்கு',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isPromise
                                ? 'வாக்குத்தத்த போஸ்டர்கள் (Top Liked)'
                                : 'விசுவாச அறிக்கை போஸ்டர்கள் (Top Liked)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text(
                          'Slide →',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _posters.length,
                        itemBuilder: (context, index) {
                          final poster = _posters[index];
                          final bool liked = (poster['is_liked'] ?? 0) == 1;
                          final String? imgPath = poster['image_path'];
                          final bool hasImage = imgPath != null &&
                              imgPath.isNotEmpty &&
                              File(imgPath).existsSync();

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Color(
                                    poster['bg_color'] ?? 0xFF1E2A4A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white12),
                                image: hasImage
                                    ? DecorationImage(
                                        image: FileImage(File(imgPath)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                color: hasImage
                                    ? Colors.black.withValues(alpha: 0.45)
                                    : Colors.transparent,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black38,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '#${index + 1} • ${poster['ref_title']}',
                                        style: const TextStyle(
                                          color: Colors.amberAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: Text(
                                        poster['verse_text'] ?? '',
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            poster['author_name'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          onTap: () async {
                                            await DatabaseHelper.instance
                                                .togglePosterLike(
                                              poster['id'],
                                              poster['likes_count'] ?? 0,
                                              poster['is_liked'] ?? 0,
                                            );
                                            _switchDevotionTab(
                                                _selectedDevotionTab);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: liked
                                                  ? Colors.amber
                                                      .withValues(alpha: 0.25)
                                                  : Colors.black38,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  liked
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  size: 14,
                                                  color: liked
                                                      ? Colors.amberAccent
                                                      : Colors.white70,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Praise God (${poster['likes_count']})',
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
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'தொடர்ந்து வாசிக்க (Continue Reading)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E222D),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.indigoAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  color: Colors.indigoAccent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _lastReadBook != null
                                          ? '${_lastReadBook['name_ta']} (${_lastReadBook['name_en']}) — அதிகாரம் ${_lastReadBook['chapter']}'
                                          : 'ஆதியாகமம் (Genesis) — அதிகாரம் 1',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'முழுமையாக வாசித்த அதிகாரங்கள்: $_totalChaptersRead / 1189',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigoAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async {
                                  final bookToOpen = _lastReadBook != null
                                      ? {
                                          'id': _lastReadBook['book_id'],
                                          'name_ta': _lastReadBook['name_ta'],
                                          'name_en': _lastReadBook['name_en'],
                                          'testament':
                                              _lastReadBook['testament'],
                                          'chapters_count':
                                              _lastReadBook['chapters_count'],
                                        }
                                      : {
                                          'id': 1,
                                          'name_ta': 'ஆதியாகமம்',
                                          'name_en': 'Genesis',
                                          'testament': 'Old Testament',
                                          'chapters_count': 50,
                                        };
                                  final ch = _lastReadBook != null
                                      ? (_lastReadBook['chapter'] as int)
                                      : 1;

                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BibleReadingScreen(
                                        book: bookToOpen,
                                        initialChapter: ch,
                                      ),
                                    ),
                                  );
                                  _loadHomeData();
                                },
                                child: const Text(
                                  'வாசி',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF252936),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.amberAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    rankInfo['rank'] == 1
                                        ? 'வாழ்த்துக்கள்! வேதாகம வாசிப்பில் நீங்கள் #1 இடத்தில் உள்ளீர்கள்!'
                                        : 'தரவரிசை #${rankInfo['rank']} • ${rankInfo['nextName']} அவர்களை முந்த இன்னும் ${rankInfo['needed']} அதிகாரங்கள் வாசியுங்கள்!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'சமூகத்தில் பிரபலமானவை (Trending Topics)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text(
                          'Tap to Chat →',
                          style: TextStyle(
                              color: Colors.indigoAccent, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _trendingPosts.length,
                        itemBuilder: (context, index) {
                          final item = _trendingPosts[index];
                          final bool isLiked = (item['is_liked'] ?? 0) == 1;
                          final String topicKey = item['topic_key'] ?? '';

                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TopicChatScreen(topicKey: topicKey),
                                ),
                              );
                              _loadHomeData();
                            },
                            child: Container(
                              width: 240,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E222D),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topicKey,
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Text(
                                      item['message_text'] ?? '',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item['sender_name'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            isLiked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            size: 13,
                                            color: isLiked
                                                ? Colors.amberAccent
                                                : Colors.white54,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${item['likes_count'] ?? 0}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
