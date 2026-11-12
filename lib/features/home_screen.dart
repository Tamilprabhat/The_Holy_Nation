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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDevotionTab = 0;

  dynamic _promiseVerse;
  dynamic _confessionVerse;
  List _posters = [];
  List _trendingPosts = [];
  int _totalChaptersRead = 0;
  dynamic _lastReadBook;
  bool _isLoading = true;

  final List _promiseList = [
    {'book_id': 23, 'chapter': 41, 'verse': 10}, // ஏசாயா 41:10
    {'book_id': 6, 'chapter': 1, 'verse': 9},   // யோசுவா 1:9
    {'book_id': 43, 'chapter': 14, 'verse': 27}, // யோவான் 14:27
    {'book_id': 24, 'chapter': 29, 'verse': 11}, // எரேமியா 29:11
    {'book_id': 50, 'chapter': 4, 'verse': 19},  // பிலிப்பியர் 4:19
    {'book_id': 40, 'chapter': 11, 'verse': 28}, // மத்தேயு 11:28
    {'book_id': 19, 'chapter': 91, 'verse': 11}, // சங்கீதம் 91:11
  ];

  final List _confessionList = [
    {'book_id': 50, 'chapter': 4, 'verse': 13},  // என்னைப் பெலப்படுத்துகிற கிறிஸ்துவினாலே...
    {'book_id': 19, 'chapter': 138, 'verse': 8}, // கர்த்தர் எனக்காக யாவையும் செய்து முடிப்பார்
    {'book_id': 50, 'chapter': 1, 'verse': 6},   // உங்களில் நற்கிரியையைத் தொடங்கினவர்...
    {'book_id': 19, 'chapter': 23, 'verse': 1},  // கர்த்தர் என் மேய்ப்பராயிருக்கிறார்
    {'book_id': 45, 'chapter': 8, 'verse': 37},  // முற்றும் ஜெயங்கொள்ளுகிறவர்களாயிருக்கிறோமே
    {'book_id': 19, 'chapter': 27, 'verse': 1},  // கர்த்தர் என் வெளிச்சமும் என் இரட்சிப்புமானவர்
    {'book_id': 19, 'chapter': 118, 'verse': 6}, // கர்த்தர் என் பட்சத்தில் இருக்கிறார், நான் பயப்படேன்
  ];

  final List _topicKeys = [
    '#அன்பு (Love)',
    '#விசுவாசம் (Faith)',
    '#ஜெபம் (Prayer)',
    '#சமாதானம் (Peace)',
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
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
    final activeCategory = _selectedDevotionTab == 0 ? 'promise' : 'confession';
    final postersData =
        await DatabaseHelper.instance.getPostersByCategory(activeCategory);

    // ஒவ்வொரு ட்ரெண்டிங் டாபிக்கிலும் அதிக Likes பெற்ற முதன்மைக் கருத்தை எடுத்தல்
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

  Future<void> _switchDevotionTab(int tabIndex) async {
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
        '$titleLabel — $ref\n\n${verseData['text_ta']}\n\n${verseData['text_en']}\n\n— THE HOLY NATION';
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

  Future<void> _openPosterCreator(dynamic verseData) async {
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
      {'name': 'எஸ்தர் (Esther)', 'chapters': 65},
      {'name': 'தாவீது (David)', 'chapters': 30},
      {'name': 'ரூத் (Ruth)', 'chapters': 12},
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.indigoAccent),
      );
    }

    final bool isPromise = _selectedDevotionTab == 0;
    final activeVerse = isPromise ? _promiseVerse : _confessionVerse;
    final rankInfo = _calculateRankInfo(_totalChaptersRead);

    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. மையப்படுத்தப்பட்ட 2 Pill பொத்தான்கள்
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchDevotionTab(0),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isPromise
                            ? const Color(0xFF283593)
                            : const Color(0xFF1B1D28),
                        borderRadius: BorderRadius.circular(25),
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
                          color: isPromise ? Colors.white : Colors.white60,
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
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !isPromise
                            ? const Color(0xFF1B4332)
                            : const Color(0xFF1B1D28),
                        borderRadius: BorderRadius.circular(25),
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
                          color: !isPromise ? Colors.white : Colors.white60,
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

            // 2. சிம்பிளான பிளைன் பேக்ரவுண்டில் நேர்த்தியான வசன அட்டை
            if (activeVerse != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1C26),
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
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
                            icon: const Icon(Icons.copy_rounded, size: 16),
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
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => _openPosterCreator(activeVerse),
                            icon: const Icon(Icons.add_photo_alternate_outlined,
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

            // 3. பயனர்கள் உருவாக்கிய போஸ்டர்கள் (Gallery Photo + Gradient Support)
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
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _posters.length,
                itemBuilder: (context, index) {
                  final poster = _posters[index];
                  final bool liked = (poster['is_liked'] ?? 0) == 1;
                  final String? imgPath = poster['image_path'];
                  final bool hasImage =
                      imgPath != null && imgPath.isNotEmpty && File(imgPath).existsSync();

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 260,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Color(poster['bg_color'] ?? 0xFF1E2A4A),
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
                            ? Colors.black.withValues(alpha: 0.48)
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
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () async {
                                    await DatabaseHelper.instance
                                        .togglePosterLike(
                                      poster['id'],
                                      poster['likes_count'] ?? 0,
                                      poster['is_liked'] ?? 0,
                                    );
                                    _switchDevotionTab(_selectedDevotionTab);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: liked
                                          ? Colors.amber.withValues(alpha: 0.25)
                                          : Colors.black38,
                                      borderRadius: BorderRadius.circular(20),
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

            const SizedBox(height: 22),

            // 4. தொடர்ந்து வாசிக்க & தரவரிசை Notification Bar
            const Text(
              'தொடர்ந்து வாசிக்க (Continue Reading)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1D28),
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
                          color: Colors.indigoAccent.withValues(alpha: 0.2),
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
                            const SizedBox(height: 4),
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
                                  'testament': _lastReadBook['testament'],
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
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25293A),
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

            const SizedBox(height: 22),

            // 5. ட்ரெண்டிங் டாபிக் (கிளிக் செய்தால் Community Chat பக்கத்திற்குச் செல்லும்)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Expanded(
                  child: Text(
                    'ட்ரெண்டிங் டாபிக் (Trending Topics)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Tap to Chat →',
                  style: TextStyle(color: Colors.indigoAccent, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 190,
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
                          builder: (_) => TopicChatScreen(topicKey: topicKey),
                        ),
                      );
                      _loadHomeData();
                    },
                    child: Container(
                      width: 270,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1D28),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.indigoAccent
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '#${index + 1} $topicKey',
                                  style: const TextStyle(
                                    color: Colors.indigoAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 15,
                                color: Colors.white54,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Text(
                              item['message_text'] ?? '',
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item['author_name'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () async {
                                  await DatabaseHelper.instance
                                      .toggleTopicMessageLike(
                                    item['id'],
                                    item['likes_count'] ?? 0,
                                    item['is_liked'] ?? 0,
                                  );
                                  _loadHomeData();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLiked
                                        ? Colors.indigoAccent
                                            .withValues(alpha: 0.3)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLiked
                                            ? Icons.thumb_up
                                            : Icons.thumb_up_outlined,
                                        size: 13,
                                        color: isLiked
                                            ? Colors.amberAccent
                                            : Colors.white70,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Praise God (${item['likes_count']})',
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
