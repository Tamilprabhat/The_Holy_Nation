import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../data/local/database_helper.dart';
import 'bookmarks_screen.dart';
import 'bible_search_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State {
  bool _isLoading = true;

  String _userName = 'தேவ பிள்ளை (Believer)';
  String _newName = 'கர்த்தருடைய பிள்ளை';
  String _churchCity = 'The Holy Nation • India';
  String _churchType = 'பெந்தெகொஸ்தே சபை (Pentecostal / AG / TPM)';
  String _lifeVerse =
      'கர்த்தர் என் மேய்ப்பராயிருக்கிறார்; நான் தாழ்ச்சியடையேன். — சங்கீதம் 23:1';
  String _favoriteBook = 'சங்கீதம் (Psalms)';
  String _favoriteSong = 'என் இயேசுவே என் ஆத்தும நேசரே';
  String _spiritualCategory = 'ஜெபம் & பரிந்துபேசுதல் (Prayer)';
  String? _avatarPath;
  bool _isVerified = false;
  bool _dailyVerseReminder = true;
  bool _nightPrayerReminder = true;

  int _chaptersReadCount = 0;
  int _bookmarksCount = 0;
  String _lastReadTitle = 'இன்னும் வாசிப்பு தொடங்கவில்லை';

  final List _churchOptions = [
    'பெந்தெகொஸ்தே சபை (Pentecostal / AG / TPM)',
    'தென்னிந்திய திருச்சபை (CSI)',
    'பாப்டிஸ்ட் சபை (Baptist)',
    'எவாஞ்சலிக்கல் / சுயாதீன சபை (Evangelical / Independent)',
    'லூத்தரன் / மெதடிஸ்ட் சபை (Lutheran / Methodist)',
    'எந்த சபைக்கும் செல்லவில்லை (Not attending any church)',
    'புதிய ஆத்மா — இயேசுவை அறிந்துகொள்ள விரும்புகிறேன் (New Soul / Seeker)',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileAndStats();
  }

  Future _ensureProfileTable() async {
    final db = await DatabaseHelper.instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id INTEGER PRIMARY KEY,
        user_name TEXT NOT NULL,
        new_name TEXT NOT NULL DEFAULT '',
        church_city TEXT NOT NULL,
        church_type TEXT NOT NULL DEFAULT '',
        life_verse TEXT NOT NULL,
        favorite_book TEXT NOT NULL DEFAULT '',
        favorite_song TEXT NOT NULL DEFAULT '',
        spiritual_category TEXT NOT NULL DEFAULT '',
        avatar_path TEXT,
        verification_selfie_path TEXT,
        is_verified INTEGER NOT NULL DEFAULT 0,
        daily_reminder INTEGER NOT NULL DEFAULT 1,
        prayer_reminder INTEGER NOT NULL DEFAULT 1
      )
    ''');

    final alterCols = [
      "ALTER TABLE user_profile ADD COLUMN new_name TEXT NOT NULL DEFAULT ''",
      "ALTER TABLE user_profile ADD COLUMN church_type TEXT NOT NULL DEFAULT ''",
      "ALTER TABLE user_profile ADD COLUMN favorite_book TEXT NOT NULL DEFAULT ''",
      "ALTER TABLE user_profile ADD COLUMN favorite_song TEXT NOT NULL DEFAULT ''",
      "ALTER TABLE user_profile ADD COLUMN spiritual_category TEXT NOT NULL DEFAULT ''",
      "ALTER TABLE user_profile ADD COLUMN verification_selfie_path TEXT",
      "ALTER TABLE user_profile ADD COLUMN is_verified INTEGER NOT NULL DEFAULT 0",
    ];
    for (final sql in alterCols) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    final rows = await db.query('user_profile', where: 'id = 1');
    if (rows.isEmpty) {
      await db.insert('user_profile', {
        'id': 1,
        'user_name': _userName,
        'new_name': _newName,
        'church_city': _churchCity,
        'church_type': _churchType,
        'life_verse': _lifeVerse,
        'favorite_book': _favoriteBook,
        'favorite_song': _favoriteSong,
        'spiritual_category': _spiritualCategory,
        'avatar_path': null,
        'is_verified': 0,
        'daily_reminder': 1,
        'prayer_reminder': 1,
      });
    }
  }

  Future _loadProfileAndStats() async {
    setState(() => _isLoading = true);
    await _ensureProfileTable();

    final db = await DatabaseHelper.instance.database;
    final profileRows = await db.query('user_profile', where: 'id = 1');
    final readingSummary = await DatabaseHelper.instance.getReadingSummary();
    final bookmarksList = await DatabaseHelper.instance.getAllBookmarks();

    if (!mounted) return;

    if (profileRows.isNotEmpty) {
      final pRow = profileRows.first;
      _userName = pRow['user_name']?.toString() ?? _userName;
      _newName = (pRow['new_name']?.toString() ?? '').isEmpty
          ? _newName
          : pRow['new_name'].toString();
      _churchCity = pRow['church_city']?.toString() ?? _churchCity;
      final savedType = pRow['church_type']?.toString() ?? '';
      if (_churchOptions.contains(savedType)) {
        _churchType = savedType;
      }
      _lifeVerse = pRow['life_verse']?.toString() ?? _lifeVerse;
      _favoriteBook = (pRow['favorite_book']?.toString() ?? '').isEmpty
          ? _favoriteBook
          : pRow['favorite_book'].toString();
      _favoriteSong = (pRow['favorite_song']?.toString() ?? '').isEmpty
          ? _favoriteSong
          : pRow['favorite_song'].toString();
      _spiritualCategory =
          (pRow['spiritual_category']?.toString() ?? '').isEmpty
              ? _spiritualCategory
              : pRow['spiritual_category'].toString();
      _avatarPath = pRow['avatar_path']?.toString();
      _isVerified = (pRow['is_verified'] ?? 0) == 1;
      _dailyVerseReminder = (pRow['daily_reminder'] ?? 1) == 1;
      _nightPrayerReminder = (pRow['prayer_reminder'] ?? 1) == 1;
    }

    final int totalRead = (readingSummary['total_read'] as int?) ?? 0;
    final lastRead = readingSummary['last_read'];
    String lastTitle = 'இன்னும் வாசிப்பு தொடங்கவில்லை';
    if (lastRead != null) {
      final bTa = lastRead['name_ta'] ?? '';
      final ch = lastRead['chapter'] ?? 1;
      lastTitle = '$bTa — அதிகாரம் $ch';
    }

    setState(() {
      _chaptersReadCount = totalRead;
      _bookmarksCount = bookmarksList.length;
      _lastReadTitle = lastTitle;
      _isLoading = false;
    });
  }

  Future _pickPublicProfilePhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;

    final db = await DatabaseHelper.instance.database;
    await db.update(
      'user_profile',
      {'avatar_path': file.path},
      where: 'id = 1',
    );
    setState(() {
      _avatarPath = file.path;
    });
  }

  void _openEditProfileSheet() {
    final TextEditingController nameCtrl =
        TextEditingController(text: _userName);
    final TextEditingController newNameCtrl =
        TextEditingController(text: _newName);
    final TextEditingController cityCtrl =
        TextEditingController(text: _churchCity);
    final TextEditingController verseCtrl =
        TextEditingController(text: _lifeVerse);
    final TextEditingController bookCtrl =
        TextEditingController(text: _favoriteBook);
    final TextEditingController songCtrl =
        TextEditingController(text: _favoriteSong);
    String selectedType = _churchType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 22 + bottomInset),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'சுயவிவரத்தைத் திருத்து (Edit Profile)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'இயற்பெயர் (Real Name)',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: const Color(0xFF0F1115),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newNameCtrl,
                      style: const TextStyle(color: Color(0xFFE4AF37)),
                      decoration: InputDecoration(
                        labelText: 'புதிய நாமம் (Chosen New Name - ஏசா 62:2)',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: const Color(0xFF0F1115),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1115),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton(
                          value: selectedType,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF181A24),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          items: [
                            for (final ch in _churchOptions)
                              DropdownMenuItem(value: ch, child: Text(ch)),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(
                                  () => selectedType = val.toString());
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: cityCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'சபை பெயர் & ஊர்',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: const Color(0xFF0F1115),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bookCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'விருப்பமான வேதாகம புத்தகம்',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: const Color(0xFF0F1115),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: songCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'விருப்பமான பாடல் (Favorite Song)',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: const Color(0xFF0F1115),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: verseCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'விருப்பமான வசனம் (Life Verse)',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: const Color(0xFF0F1115),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE4AF37),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () async {
                          final db = await DatabaseHelper.instance.database;
                          await db.update(
                            'user_profile',
                            {
                              'user_name': nameCtrl.text.trim().isEmpty
                                  ? _userName
                                  : nameCtrl.text.trim(),
                              'new_name': newNameCtrl.text.trim().isEmpty
                                  ? _newName
                                  : newNameCtrl.text.trim(),
                              'church_type': selectedType,
                              'church_city': cityCtrl.text.trim().isEmpty
                                  ? selectedType
                                  : cityCtrl.text.trim(),
                              'favorite_book': bookCtrl.text.trim().isEmpty
                                  ? _favoriteBook
                                  : bookCtrl.text.trim(),
                              'favorite_song': songCtrl.text.trim().isEmpty
                                  ? _favoriteSong
                                  : songCtrl.text.trim(),
                              'life_verse': verseCtrl.text.trim().isEmpty
                                  ? _lifeVerse
                                  : verseCtrl.text.trim(),
                            },
                            where: 'id = 1',
                          );

                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadProfileAndStats();
                        },
                        child: const Text(
                          'சேமி (Save Changes)',
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

  Future _updateReminderSetting(String column, bool value) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'user_profile',
      {column: value ? 1 : 0},
      where: 'id = 1',
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F1115);
    const Color cardDark = Color(0xFF181A24);
    const Color goldAccent = Color(0xFFE4AF37);

    final bool hasAvatar = _avatarPath != null &&
        _avatarPath!.isNotEmpty &&
        File(_avatarPath!).existsSync();

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: cardDark,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: goldAccent),
            SizedBox(width: 8),
            Text(
              'Profile & Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: goldAccent),
            tooltip: 'சுயவிவரம் திருத்து',
            onPressed: _openEditProfileSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: goldAccent))
          : RefreshIndicator(
              onRefresh: _loadProfileAndStats,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // Profile Card with New Name & Public Photo
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E2436), Color(0xFF151822)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: goldAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor:
                                  goldAccent.withValues(alpha: 0.2),
                              backgroundImage: hasAvatar
                                  ? FileImage(File(_avatarPath!))
                                  : null,
                              child: hasAvatar
                                  ? null
                                  : const Icon(
                                      Icons.person_rounded,
                                      size: 46,
                                      color: goldAccent,
                                    ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: _pickPublicProfilePhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: goldAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.photo_library_rounded,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (_isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified,
                                  color: Colors.tealAccent, size: 18),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: goldAccent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: goldAccent.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            '✨ புதிய நாமம்: $_newName',
                            style: const TextStyle(
                              color: goldAccent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _churchCity,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '"$_lifeVerse"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '🛡️ நேரடி செல்ஃபி அடையாளம் பாதுகாப்பாகப் பதியப்பட்டுள்ளது (Private ID)',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Spiritual Preferences Card (For Smart Friend Matching)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ஆவிக்குரிய விருப்பங்கள் (Friend Matching)',
                          style: TextStyle(
                            color: goldAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPrefRow(Icons.menu_book, 'விருப்பமான புத்தகம்:',
                            _favoriteBook),
                        const SizedBox(height: 8),
                        _buildPrefRow(Icons.music_note, 'விருப்பமான பாடல்:',
                            _favoriteSong),
                        const SizedBox(height: 8),
                        _buildPrefRow(Icons.favorite_outline, 'ஆவிக்குரிய பிரிவு:',
                            _spiritualCategory),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Reading Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.auto_stories_rounded,
                                  color: Colors.tealAccent, size: 24),
                              const SizedBox(height: 6),
                              Text(
                                '$_chaptersReadCount / 1189',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'வாசித்த அதிகாரங்கள்',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BookmarksScreen(),
                              ),
                            );
                            _loadProfileAndStats();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardDark,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.bookmarks_rounded,
                                    color: goldAccent, size: 24),
                                const SizedBox(height: 6),
                                Text(
                                  '$_bookmarksCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'சேமித்த வசனங்கள்',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Card(
                    color: cardDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.bookmarks_outlined,
                              color: goldAccent),
                          title: const Text(
                            'சேமித்த வசனங்கள் (My Bookmarks)',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.white38),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BookmarksScreen(),
                              ),
                            );
                            _loadProfileAndStats();
                          },
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        ListTile(
                          leading: const Icon(Icons.search_rounded,
                              color: Colors.tealAccent),
                          title: const Text(
                            '10 மொழி வேதாகமத் தேடல் (Bible Search)',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.white38),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BibleSearchScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    color: cardDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeThumbColor: goldAccent,
                          title: const Text(
                            'தினசரி காலை வேத வாசிப்பு',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          value: _dailyVerseReminder,
                          onChanged: (val) {
                            setState(() => _dailyVerseReminder = val);
                            _updateReminderSetting('daily_reminder', val);
                          },
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        SwitchListTile(
                          activeThumbColor: goldAccent,
                          title: const Text(
                            'இரவு ஜெப நேரம் (Youth Prayer)',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          value: _nightPrayerReminder,
                          onChanged: (val) {
                            setState(() => _nightPrayerReminder = val);
                            _updateReminderSetting('prayer_reminder', val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPrefRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.tealAccent),
        const SizedBox(width: 8),
        Text(
          '$label ',
          style: const TextStyle(color: Colors.white54, fontSize: 12.5),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
