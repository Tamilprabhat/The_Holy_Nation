import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State with TickerProviderStateMixin {
  late TabController _tabController;
  Database? _db;
  bool _isLoading = true;

  List _stories = [];
  List _posts = [];
  List _friends = [];
  List _groups = [];
  List _recentChats = [];

  String _feedFilter = 'ALL';
  String _friendSearch = '';

  final List _cardColors = [
    0xFF1E2A4A,
    0xFF283593,
    0xFF1B4332,
    0xFF3A243B,
    0xFF4A2511,
    0xFF0D3B66,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _initSocialDatabase();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _db?.close();
    super.dispose();
  }

  Future _initSocialDatabase() async {
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'holy_nation_youth_social.db');

    _db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE stories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            author_name TEXT NOT NULL,
            verse_ref TEXT NOT NULL,
            story_text TEXT NOT NULL,
            bg_color INTEGER NOT NULL,
            image_path TEXT,
            is_viewed INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            author_name TEXT NOT NULL,
            author_role TEXT NOT NULL,
            ref_title TEXT NOT NULL,
            body_text TEXT NOT NULL,
            bg_color INTEGER NOT NULL,
            image_path TEXT,
            video_path TEXT,
            likes_count INTEGER NOT NULL DEFAULT 1,
            is_liked INTEGER NOT NULL DEFAULT 0,
            comments_count INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE post_comments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            post_id INTEGER NOT NULL,
            author_name TEXT NOT NULL,
            comment_text TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE friends (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            bio TEXT NOT NULL,
            city TEXT NOT NULL,
            status TEXT NOT NULL,
            avatar_color INTEGER NOT NULL,
            is_online INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE youth_groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT NOT NULL,
            members_text TEXT NOT NULL,
            members_count INTEGER NOT NULL DEFAULT 1,
            badge_color INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            chat_key TEXT NOT NULL,
            chat_title TEXT NOT NULL,
            is_group INTEGER NOT NULL DEFAULT 0,
            sender_name TEXT NOT NULL,
            is_me INTEGER NOT NULL DEFAULT 0,
            message_text TEXT NOT NULL,
            verse_tag TEXT,
            sent_time TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        try {
          await db.execute('ALTER TABLE posts ADD COLUMN video_path TEXT');
        } catch (_) {}
      },
    );

    try {
      await _db!.execute('ALTER TABLE posts ADD COLUMN video_path TEXT');
    } catch (_) {}

    await _seedInitialYouthData();
    await _refreshAllData();
  }

  Future _seedInitialYouthData() async {
    if (_db == null) return;
    final pCount = await _db!.rawQuery('SELECT COUNT(*) as cnt FROM posts');
    if (((pCount.first['cnt'] as int?) ?? 0) > 0) return;

    final now = DateTime.now().toIso8601String();

    await _db!.insert('stories', {
      'author_name': 'டேனியல் (Daniel)',
      'verse_ref': 'சங்கீதம் 119:9',
      'story_text':
          'வாலிபன் தன் வழியை எதினால் சுத்தம் பண்ணுவான்? உமது வசனத்தின்படி தன்னைக் காத்துக்கொள்ளுகிறதினாலேயே!',
      'bg_color': 0xFF1E2A4A,
      'image_path': null,
      'is_viewed': 0,
      'created_at': now,
    });
    await _db!.insert('stories', {
      'author_name': 'எஸ்தர் (Esther)',
      'verse_ref': '1 தீமோத்தேயு 4:12',
      'story_text':
          'உன் இளமையைக்குறித்து ஒருவனும் உன்னை அசட்டைபண்ணாதபடிக்கு, விசுவாசிகளுக்கு மாதிரியாயிரு.',
      'bg_color': 0xFF3A243B,
      'image_path': null,
      'is_viewed': 0,
      'created_at': now,
    });
    await _db!.insert('stories', {
      'author_name': 'யோசுவா (Joshua)',
      'verse_ref': 'ஏசாயா 40:31',
      'story_text':
          'கர்த்தருக்குக் காத்திருக்கிறவர்களோ புதுப்பெலன் அடைந்து, கழுகுகளைப்போலச் செட்டைகளை அடித்து எழும்புவார்கள்.',
      'bg_color': 0xFF1B4332,
      'image_path': null,
      'is_viewed': 0,
      'created_at': now,
    });

    final post1 = await _db!.insert('posts', {
      'category': 'promise',
      'author_name': 'டேனியல் (Daniel)',
      'author_role': 'Youth Leader • Chennai',
      'ref_title': 'எரேமியா (Jeremiah) 29:11',
      'body_text':
          'நீங்கள் எதிர்பார்த்திருக்கும் முடிவை உங்களுக்குக் கொடுக்கும்படிக்கு நான் உங்கள்பேரில் நினைத்திருக்கிற நினைவுகளை அறிவேன் என்று கர்த்தர் சொல்லுகிறார்; அவைகள் தீமைக்கல்ல, சமாதானத்துக்கேதுவான நினைவுகளே.',
      'bg_color': 0xFF1E2A4A,
      'image_path': null,
      'video_path': null,
      'likes_count': 42,
      'is_liked': 0,
      'comments_count': 2,
      'created_at': now,
    });

    await _db!.insert('post_comments', {
      'post_id': post1,
      'author_name': 'எஸ்தர் (Esther)',
      'comment_text': 'ஆமென்! வாலிபர்களுக்கு மிகப்பெரிய நம்பிக்கை தரும் வசனம்.',
      'created_at': now,
    });
    await _db!.insert('post_comments', {
      'post_id': post1,
      'author_name': 'சாமுவேல் (Samuel)',
      'comment_text': 'தேவனுக்கே மகிமை உண்டாவதாக!',
      'created_at': now,
    });

    await _db!.insert('posts', {
      'category': 'confession',
      'author_name': 'எஸ்தர் (Esther)',
      'author_role': 'Worship Team • Madurai',
      'ref_title': 'பிலிப்பியர் (Philippians) 4:13',
      'body_text':
          'என்னைப் பெலப்படுத்துகிற கிறிஸ்துவினாலே எல்லாவற்றையுஞ்செய்ய எனக்குப் பெலனுண்டு. இன்றைய தேர்வுகளிலும் வேலைகளிலும் கர்த்தர் எனக்கு ஜெயம் தருவார்!',
      'bg_color': 0xFF1B4332,
      'image_path': null,
      'video_path': null,
      'likes_count': 57,
      'is_liked': 1,
      'comments_count': 0,
      'created_at': now,
    });

    await _db!.insert('friends', {
      'name': 'டேனியல் (Daniel)',
      'bio': 'Youth Prayer & Music • கிறிஸ்துவுக்காக வாழ்வோம்',
      'city': 'Chennai',
      'status': 'accepted',
      'avatar_color': 0xFF3949AB,
      'is_online': 1,
    });
    await _db!.insert('friends', {
      'name': 'எஸ்தர் (Esther)',
      'bio': 'Choir & Bible Study • சங்கீதம் 23',
      'city': 'Madurai',
      'status': 'accepted',
      'avatar_color': 0xFF8E24AA,
      'is_online': 1,
    });
    await _db!.insert('friends', {
      'name': 'சாமுவேல் (Samuel)',
      'bio': 'College Youth Fellowship',
      'city': 'Coimbatore',
      'status': 'pending',
      'avatar_color': 0xFF00897B,
      'is_online': 0,
    });
    await _db!.insert('friends', {
      'name': 'ரூத் (Ruth)',
      'bio': 'Daily Bible Reader • விசுவாசமே ஜெயம்',
      'city': 'Trichy',
      'status': 'suggested',
      'avatar_color': 0xFFD84315,
      'is_online': 1,
    });
    await _db!.insert('friends', {
      'name': 'யோசுவா (Joshua)',
      'bio': 'Youth Evangelism Team',
      'city': 'Andaman',
      'status': 'suggested',
      'avatar_color': 0xFF1565C0,
      'is_online': 1,
    });

    final g1 = await _db!.insert('youth_groups', {
      'name': 'Youth Prayer Warriors 🙏',
      'category': 'ஜெபக் குழு (Prayer)',
      'description': 'தினமும் இரவு 9 மணிக்கு வாலிபர்களுக்காக இணைந்து ஜெபிக்கும் குழு.',
      'members_text': 'நீங்கள், டேனியல், எஸ்தர்',
      'members_count': 18,
      'badge_color': 0xFF283593,
      'created_at': now,
    });

    final g2 = await _db!.insert('youth_groups', {
      'name': 'Choir & Worship Youth 🎸',
      'category': 'ஆராதனை (Worship)',
      'description': 'புதிய பாடல்கள், கிறிஸ்தவ இசை மற்றும் ஆராதனை அனுபவங்களைப் பகிரும் குழு.',
      'members_text': 'நீங்கள், எஸ்தர், யோசுவா',
      'members_count': 24,
      'badge_color': 0xFF1B4332,
      'created_at': now,
    });

    await _db!.insert('chat_messages', {
      'chat_key': 'friend_1',
      'chat_title': 'டேனியல் (Daniel)',
      'is_group': 0,
      'sender_name': 'டேனியல் (Daniel)',
      'is_me': 0,
      'message_text': 'Praise the Lord! இன்றைய வேத தியானம் ரொம்ப ஆசீர்வாதமாக இருந்தது.',
      'verse_tag': 'சங்கீதம் 119:105',
      'sent_time': '09:30 AM',
    });

    await _db!.insert('chat_messages', {
      'chat_key': 'group_$g1',
      'chat_title': 'Youth Prayer Warriors 🙏',
      'is_group': 1,
      'sender_name': 'எஸ்தர் (Esther)',
      'is_me': 0,
      'message_text': 'இன்று இரவு 9 மணிக்கு நம் வாலிப நண்பர்களின் படிப்பு மற்றும் எதிர்காலத்திற்காக ஜெபிப்போம்!',
      'verse_tag': 'யாக்கோபு 5:16',
      'sent_time': '06:15 PM',
    });

    await _db!.insert('chat_messages', {
      'chat_key': 'group_$g2',
      'chat_title': 'Choir & Worship Youth 🎸',
      'is_group': 1,
      'sender_name': 'டேனியல் (Daniel)',
      'is_me': 0,
      'message_text': 'இந்த வார ஆராதனைக்கு எந்தப் பாடல் எடுக்கலாம் நண்பர்களே?',
      'verse_tag': '',
      'sent_time': '07:05 PM',
    });
  }

  Future _refreshAllData() async {
    if (_db == null) return;
    final stories = await _db!.query('stories', orderBy: 'id DESC');
    final posts = await _db!.query('posts', orderBy: 'id DESC');
    final friends = await _db!.query('friends', orderBy: 'id ASC');
    final groups = await _db!.query('youth_groups', orderBy: 'id DESC');
    final chats = await _db!.rawQuery('''
      SELECT cm.*
      FROM chat_messages cm
      INNER JOIN (
        SELECT chat_key, MAX(id) as max_id
        FROM chat_messages
        GROUP BY chat_key
      ) latest ON cm.id = latest.max_id
      ORDER BY cm.id DESC
    ''');

    if (!mounted) return;
    setState(() {
      _stories = stories;
      _posts = posts;
      _friends = friends;
      _groups = groups;
      _recentChats = chats;
      _isLoading = false;
    });
  }

  Future _togglePostLike(dynamic post) async {
    if (_db == null) return;
    final int id = post['id'];
    final bool currentlyLiked = (post['is_liked'] ?? 0) == 1;
    final int currentCount = post['likes_count'] ?? 0;
    final int nextCount =
        currentlyLiked ? (currentCount > 0 ? currentCount - 1 : 0) : currentCount + 1;

    await _db!.update(
      'posts',
      {'is_liked': currentlyLiked ? 0 : 1, 'likes_count': nextCount},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _refreshAllData();
  }

  void _openStoryViewer(dynamic story) async {
    if (_db != null) {
      await _db!.update(
        'stories',
        {'is_viewed': 1},
        where: 'id = ?',
        whereArgs: [story['id']],
      );
      _refreshAllData();
    }

    if (!mounted) return;
    final String? imgPath = story['image_path'];
    final bool hasImage =
        imgPath != null && imgPath.isNotEmpty && File(imgPath).existsSync();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(14),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.72,
            decoration: BoxDecoration(
              color: Color(story['bg_color'] ?? 0xFF1E2A4A),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE4AF37), width: 1.5),
              image: hasImage
                  ? DecorationImage(
                      image: FileImage(File(imgPath)),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.45),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFE4AF37),
                        child: Icon(Icons.person, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story['author_name'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              story['verse_ref'] ?? 'Daily Story',
                              style: const TextStyle(
                                color: Color(0xFFE4AF37),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '"${story['story_text'] ?? ''}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE4AF37),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.favorite, size: 18),
                      label: const Text(
                        'ஆமென் (Amen)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🙏 ஆமென்! உங்கள் வாழ்த்து அனுப்பப்பட்டது.'),
                            duration: Duration(seconds: 1),
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
      },
    );
  }

  void _openAddStorySheet() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController refCtrl = TextEditingController();
    final TextEditingController textCtrl = TextEditingController();
    int selectedColor = _cardColors.first;
    String? pickedImg;

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
              padding: EdgeInsets.fromLTRB(18, 14, 18, 20 + bottomInset),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'புதிய ஸ்டோரி பதிவிடு (Add Youth Story)',
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
                        hintText: 'உங்கள் பெயர்',
                        hintStyle: const TextStyle(color: Colors.white38),
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
                      controller: refCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'வேத வசனம் (உதா: சங்கீதம் 23:1)',
                        hintStyle: const TextStyle(color: Colors.white38),
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
                      controller: textCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'இன்றைய வசனம் அல்லது சாட்சியை எழுதுங்கள்...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0F1115),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final c in _cardColors)
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedColor = c;
                                pickedImg = null;
                              });
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Color(c),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (selectedColor == c && pickedImg == null)
                                      ? const Color(0xFFE4AF37)
                                      : Colors.white24,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amberAccent,
                            side: const BorderSide(color: Colors.amberAccent),
                          ),
                          icon: const Icon(Icons.photo, size: 16),
                          label: const Text('படம்'),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final file = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );
                            if (file != null) {
                              setModalState(() => pickedImg = file.path);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE4AF37),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          if (textCtrl.text.trim().isEmpty || _db == null) return;
                          await _db!.insert('stories', {
                            'author_name': nameCtrl.text.trim().isEmpty
                                ? 'நீங்கள் (You)'
                                : nameCtrl.text.trim(),
                            'verse_ref': refCtrl.text.trim().isEmpty
                                ? 'Daily Word'
                                : refCtrl.text.trim(),
                            'story_text': textCtrl.text.trim(),
                            'bg_color': selectedColor,
                            'image_path': pickedImg,
                            'is_viewed': 0,
                            'created_at': DateTime.now().toIso8601String(),
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          _refreshAllData();
                        },
                        child: const Text(
                          'ஸ்டோரி பகிர் (Share Story)',
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

  void _openCreatePostSheet() {
    final TextEditingController authorCtrl = TextEditingController();
    final TextEditingController refCtrl = TextEditingController();
    final TextEditingController bodyCtrl = TextEditingController();
    String category = 'promise';
    int selectedColor = _cardColors.first;
    String? pickedImg;
    String? pickedVideo;

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
              padding: EdgeInsets.fromLTRB(18, 14, 18, 20 + bottomInset),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'புதிய சமூகப் பதிவு (Create Post / Video)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          selected: category == 'promise',
                          selectedColor: const Color(0xFFE4AF37),
                          label: Text(
                            'வாக்குத்தத்தம்',
                            style: TextStyle(
                              color: category == 'promise'
                                  ? Colors.black
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onSelected: (_) =>
                              setModalState(() => category = 'promise'),
                        ),
                        ChoiceChip(
                          selected: category == 'confession',
                          selectedColor: const Color(0xFFE4AF37),
                          label: Text(
                            'அறிக்கை',
                            style: TextStyle(
                              color: category == 'confession'
                                  ? Colors.black
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onSelected: (_) =>
                              setModalState(() => category = 'confession'),
                        ),
                        ChoiceChip(
                          selected: category == 'testimony',
                          selectedColor: const Color(0xFFE4AF37),
                          label: Text(
                            'சாட்சி / பாடல்',
                            style: TextStyle(
                              color: category == 'testimony'
                                  ? Colors.black
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onSelected: (_) =>
                              setModalState(() => category = 'testimony'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: authorCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'உங்கள் பெயர்',
                        hintStyle: const TextStyle(color: Colors.white38),
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
                      controller: refCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'தலைப்பு / வேத ஆதாரம் (உதா: ஆராதனை பாடல் / யோவான் 3:16)',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
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
                      controller: bodyCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'வசனம் அல்லது வீடியோ குறிப்பை எழுதுங்கள்...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0F1115),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final c in _cardColors)
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedColor = c;
                                pickedImg = null;
                                pickedVideo = null;
                              });
                            },
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Color(c),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (selectedColor == c &&
                                          pickedImg == null &&
                                          pickedVideo == null)
                                      ? const Color(0xFFE4AF37)
                                      : Colors.white24,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amberAccent,
                            side: BorderSide(
                              color: pickedImg != null
                                  ? Colors.tealAccent
                                  : Colors.amberAccent,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                          ),
                          icon: const Icon(Icons.image, size: 16),
                          label: Text(
                            pickedImg != null ? 'படம் தேர்வு ✓' : 'புகைப்படம்',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final file = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );
                            if (file != null) {
                              setModalState(() {
                                pickedImg = file.path;
                                pickedVideo = null;
                              });
                            }
                          },
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.tealAccent,
                            side: BorderSide(
                              color: pickedVideo != null
                                  ? Colors.amberAccent
                                  : Colors.tealAccent,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                          ),
                          icon: const Icon(Icons.videocam_rounded, size: 17),
                          label: Text(
                            pickedVideo != null ? 'வீடியோ தேர்வு ✓' : 'வீடியோ',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final file = await picker.pickVideo(
                              source: ImageSource.gallery,
                              maxDuration: const Duration(seconds: 60),
                            );
                            if (file != null) {
                              setModalState(() {
                                pickedVideo = file.path;
                                pickedImg = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (pickedVideo != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.video_file,
                                color: Colors.tealAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.basename(pickedVideo!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white54, size: 16),
                              onPressed: () =>
                                  setModalState(() => pickedVideo = null),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                          if (bodyCtrl.text.trim().isEmpty &&
                              pickedVideo == null &&
                              pickedImg == null) {
                            return;
                          }
                          if (_db == null) return;
                          await _db!.insert('posts', {
                            'category': category,
                            'author_name': authorCtrl.text.trim().isEmpty
                                ? 'நீங்கள் (You)'
                                : authorCtrl.text.trim(),
                            'author_role': 'Youth Member • The Holy Nation',
                            'ref_title': refCtrl.text.trim().isEmpty
                                ? (pickedVideo != null
                                    ? 'Youth Worship / Testimony Video'
                                    : 'வேத தியானம்')
                                : refCtrl.text.trim(),
                            'body_text': bodyCtrl.text.trim().isEmpty
                                ? 'கிறிஸ்துவுக்குள் அன்பின் பகிர்வு!'
                                : bodyCtrl.text.trim(),
                            'bg_color': selectedColor,
                            'image_path': pickedImg,
                            'video_path': pickedVideo,
                            'likes_count': 1,
                            'is_liked': 1,
                            'comments_count': 0,
                            'created_at': DateTime.now().toIso8601String(),
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          _refreshAllData();
                        },
                        child: const Text(
                          'பதிவிடு (Publish Post)',
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

  void _openCommentsSheet(dynamic post) async {
    if (_db == null) return;
    final int postId = post['id'];
    List comments = await _db!.query(
      'post_comments',
      where: 'post_id = ?',
      whereArgs: [postId],
      orderBy: 'id ASC',
    );
    final TextEditingController commentCtrl = TextEditingController();

    if (!mounted) return;
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
              padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + bottomInset),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'கருத்துக்கள் (${comments.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.white12),
                    Expanded(
                      child: comments.isEmpty
                          ? const Center(
                              child: Text(
                                'முதல் கருத்தை நீங்களே பதிவிடுங்கள்!',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: comments.length,
                              itemBuilder: (cCtx, idx) {
                                final cm = comments[idx];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Color(0xFF283593),
                                    child: Icon(Icons.person,
                                        color: Colors.white, size: 16),
                                  ),
                                  title: Text(
                                    cm['author_name'] ?? '',
                                    style: const TextStyle(
                                      color: Color(0xFFE4AF37),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    cm['comment_text'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'கருத்தை எழுதுங்கள்...',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF0F1115),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: const Color(0xFFE4AF37),
                          child: IconButton(
                            icon: const Icon(Icons.send,
                                color: Colors.black, size: 18),
                            onPressed: () async {
                              final txt = commentCtrl.text.trim();
                              if (txt.isEmpty) return;
                              await _db!.insert('post_comments', {
                                'post_id': postId,
                                'author_name': 'நீங்கள் (You)',
                                'comment_text': txt,
                                'created_at': DateTime.now().toIso8601String(),
                              });
                              final updated = await _db!.query(
                                'post_comments',
                                where: 'post_id = ?',
                                whereArgs: [postId],
                                orderBy: 'id ASC',
                              );
                              await _db!.update(
                                'posts',
                                {'comments_count': updated.length},
                                where: 'id = ?',
                                whereArgs: [postId],
                              );
                              commentCtrl.clear();
                              setModalState(() => comments = updated);
                              _refreshAllData();
                            },
                          ),
                        ),
                      ],
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

  void _openAddFriendSheet() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController cityCtrl = TextEditingController();
    final TextEditingController bioCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 16, 18, 20 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'புதிய நண்பரை இணை (Add Youth Friend)',
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
                    hintText: 'நண்பரின் பெயர்',
                    hintStyle: const TextStyle(color: Colors.white38),
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
                  controller: cityCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ஊர் / சபை (உதா: Chennai / Mayabunder)',
                    hintStyle: const TextStyle(color: Colors.white38),
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
                  controller: bioCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'விருப்பமான வசனம் அல்லது குறிப்பு',
                    hintStyle: const TextStyle(color: Colors.white38),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty || _db == null) return;
                      await _db!.insert('friends', {
                        'name': name,
                        'city': cityCtrl.text.trim().isEmpty
                            ? 'India'
                            : cityCtrl.text.trim(),
                        'bio': bioCtrl.text.trim().isEmpty
                            ? 'The Holy Nation Youth'
                            : bioCtrl.text.trim(),
                        'status': 'accepted',
                        'avatar_color': 0xFF283593,
                        'is_online': 1,
                      });
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                      _refreshAllData();
                    },
                    child: const Text(
                      'நண்பராக இணை (Connect)',
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
  }

  void _openCreateGroupSheet() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();
    String category = 'ஜெபக் குழு (Prayer)';
    final acceptedFriends =
        _friends.where((f) => f['status'] == 'accepted').toList();
    final Set selectedMemberNames = {};

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
              padding: EdgeInsets.fromLTRB(18, 16, 18, 20 + bottomInset),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'புதிய வாலிபர் குழு உருவாக்கு (Create Group)',
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
                        hintText: 'குழுவின் பெயர் (உதா: Bible Study Youth)',
                        hintStyle: const TextStyle(color: Colors.white38),
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
                      controller: descCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'குழுவின் நோக்கம்...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0F1115),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'குழுவில் இணைக்க நண்பர்களைத் தேர்ந்தெடுங்கள்:',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 12.5),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final f in acceptedFriends)
                          FilterChip(
                            selected: selectedMemberNames.contains(f['name']),
                            selectedColor:
                                const Color(0xFFE4AF37).withValues(alpha: 0.3),
                            label: Text(
                              f['name'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            onSelected: (val) {
                              setModalState(() {
                                if (selectedMemberNames.contains(f['name'])) {
                                  selectedMemberNames.remove(f['name']);
                                } else {
                                  selectedMemberNames.add(f['name']);
                                }
                              });
                            },
                          ),
                      ],
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
                          final gName = nameCtrl.text.trim();
                          if (gName.isEmpty || _db == null) return;

                          final memberList = ['நீங்கள்', ...selectedMemberNames];
                          final gId = await _db!.insert('youth_groups', {
                            'name': gName,
                            'category': category,
                            'description': descCtrl.text.trim().isEmpty
                                ? 'கிறிஸ்துவுக்குள் வளரும் வாலிபர் குழு'
                                : descCtrl.text.trim(),
                            'members_text': memberList.join(', '),
                            'members_count': memberList.length,
                            'badge_color': 0xFF283593,
                            'created_at': DateTime.now().toIso8601String(),
                          });

                          await _db!.insert('chat_messages', {
                            'chat_key': 'group_$gId',
                            'chat_title': gName,
                            'is_group': 1,
                            'sender_name': 'நீங்கள் (You)',
                            'is_me': 1,
                            'message_text':
                                'புதிய குழு "$gName" தொடங்கப்பட்டுள்ளது! அனைவரையும் அன்புடன் வரவேற்கிறோம்.',
                            'verse_tag': 'மத்தேயு 18:20',
                            'sent_time': 'இப்போது',
                          });

                          if (ctx.mounted) Navigator.pop(ctx);
                          _refreshAllData();
                        },
                        child: const Text(
                          'குழுவை உருவாக்கு (Create Group)',
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

  Future _openChatRoom({
    required String chatKey,
    required String chatTitle,
    required bool isGroup,
    String subtitle = '',
  }) async {
    if (_db == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YouthChatRoomScreen(
          db: _db!,
          chatKey: chatKey,
          chatTitle: chatTitle,
          isGroup: isGroup,
          subtitle: subtitle,
        ),
      ),
    );
    _refreshAllData();
  }

  Widget _buildFeedAndStoriesTab() {
    final filteredPosts = _posts.where((pItem) {
      if (_feedFilter == 'ALL') return true;
      if (_feedFilter == 'VIDEO') {
        final vPath = pItem['video_path']?.toString() ?? '';
        return vPath.isNotEmpty;
      }
      return pItem['category'] == _feedFilter;
    }).toList();

    return RefreshIndicator(
      onRefresh: _refreshAllData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 85),
        children: [
          Container(
            height: 112,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: const Color(0xFF141720),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _stories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: _openAddStorySheet,
                    child: Container(
                      width: 76,
                      margin: const EdgeInsets.only(right: 10),
                      child: Column(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E222D),
                              border: Border.all(
                                color: const Color(0xFFE4AF37),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_a_photo_rounded,
                              color: Color(0xFFE4AF37),
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'உங்கள் ஸ்டோரி',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final st = _stories[index - 1];
                final bool viewed = (st['is_viewed'] ?? 0) == 1;
                return GestureDetector(
                  onTap: () => _openStoryViewer(st),
                  child: Container(
                    width: 76,
                    margin: const EdgeInsets.only(right: 10),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: viewed
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFE4AF37),
                                      Color(0xFFFF5252),
                                      Color(0xFF7C4DFF),
                                    ],
                                  ),
                            color: viewed ? Colors.white24 : null,
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                Color(st['bg_color'] ?? 0xFF1E2A4A),
                            child: const Icon(
                              Icons.auto_stories,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (st['author_name'] ?? '').toString().split(' ').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill('ALL', 'அனைத்தும்'),
                  const SizedBox(width: 8),
                  _buildFilterPill('VIDEO', '🎬 வீடியோக்கள்'),
                  const SizedBox(width: 8),
                  _buildFilterPill('promise', 'வாக்குத்தத்தங்கள்'),
                  const SizedBox(width: 8),
                  _buildFilterPill('confession', 'அறிக்கைகள்'),
                  const SizedBox(width: 8),
                  _buildFilterPill('testimony', 'சாட்சிகள்'),
                ],
              ),
            ),
          ),
          if (filteredPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'இந்தப் பிரிவில் இன்னும் பதிவுகள் இல்லை. புதிய பதிவை உருவாக்குங்கள்!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            ),
          for (final post in filteredPosts) _buildPostCard(post),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String code, String label) {
    final bool selected = _feedFilter == code;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _feedFilter = code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE4AF37) : const Color(0xFF1A1D26),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFFE4AF37) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    final bool isLiked = (post['is_liked'] ?? 0) == 1;
    final int likes = post['likes_count'] ?? 0;
    final int comments = post['comments_count'] ?? 0;
    final String? imgPath = post['image_path'];
    final String? vidPath = post['video_path'];
    final bool hasImage =
        imgPath != null && imgPath.isNotEmpty && File(imgPath).existsSync();
    final bool hasVideo =
        vidPath != null && vidPath.isNotEmpty && File(vidPath).existsSync();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF181A24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(post['bg_color'] ?? 0xFF283593),
              child: Icon(
                hasVideo ? Icons.videocam : Icons.person,
                color: Colors.white,
              ),
            ),
            title: Text(
              post['author_name'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              post['author_role'] ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 11.5),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded,
                  color: Colors.white54, size: 18),
              onPressed: () {
                final text =
                    '${post['ref_title']}\n"${post['body_text']}"\n— ${post['author_name']}';
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('பதிவு நகலெடுக்கப்பட்டது'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
          if (hasVideo) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: YouthVideoPlayerWidget(videoPath: vidPath),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(post['bg_color'] ?? 0xFF1E2A4A),
              borderRadius: BorderRadius.circular(14),
              image: hasImage
                  ? DecorationImage(
                      image: FileImage(File(imgPath)),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.45),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    post['ref_title'] ?? '',
                    style: const TextStyle(
                      color: Color(0xFFE4AF37),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  post['body_text'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _togglePostLike(post),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLiked
                          ? Colors.redAccent.withValues(alpha: 0.18)
                          : const Color(0xFF0F1115),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.redAccent : Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ஆமென் ($likes)',
                          style: TextStyle(
                            color: isLiked ? Colors.redAccent : Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _openCommentsSheet(post),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1115),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            color: Colors.white70, size: 17),
                        const SizedBox(width: 6),
                        Text(
                          'கருத்து ($comments)',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    final matching = _friends.where((f) {
      if (_friendSearch.isEmpty) return true;
      final q = _friendSearch.toLowerCase();
      return (f['name'] ?? '').toString().toLowerCase().contains(q) ||
          (f['city'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    final pending = matching.where((f) => f['status'] == 'pending').toList();
    final accepted = matching.where((f) => f['status'] == 'accepted').toList();
    final suggested =
        matching.where((f) => f['status'] == 'suggested').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 85),
      children: [
        TextField(
          style: const TextStyle(color: Colors.white),
          onChanged: (val) => setState(() => _friendSearch = val.trim()),
          decoration: InputDecoration(
            hintText: 'நண்பர்கள் அல்லது ஊரைத் தேடுங்கள்...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13.5),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF181A24),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'நண்பர் அழைப்புகள் (${pending.length})',
            style: const TextStyle(
              color: Color(0xFFE4AF37),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          for (final f in pending)
            Card(
              color: const Color(0xFF181A24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(f['avatar_color'] ?? 0xFF283593),
                  child: const Icon(Icons.person_add, color: Colors.white),
                ),
                title: Text(
                  f['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${f['city']} • ${f['bio']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () async {
                    if (_db == null) return;
                    await _db!.update(
                      'friends',
                      {'status': 'accepted'},
                      where: 'id = ?',
                      whereArgs: [f['id']],
                    );
                    _refreshAllData();
                  },
                  child: const Text(
                    'ஏற்றுக்கொள்',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text(
          'என் நண்பர்கள் (${accepted.length})',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 8),
        for (final f in accepted)
          Card(
            color: const Color(0xFF181A24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              onTap: () => _openChatRoom(
                chatKey: 'friend_${f['id']}',
                chatTitle: f['name'] ?? 'Friend',
                isGroup: false,
                subtitle: '${f['city']} • Online',
              ),
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(f['avatar_color'] ?? 0xFF3949AB),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  if ((f['is_online'] ?? 0) == 1)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.tealAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                f['name'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${f['city']} • ${f['bio']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.chat_rounded, color: Color(0xFFE4AF37)),
                tooltip: 'தனிப்பட்ட சாட்',
                onPressed: () => _openChatRoom(
                  chatKey: 'friend_${f['id']}',
                  chatTitle: f['name'] ?? 'Friend',
                  isGroup: false,
                  subtitle: '${f['city']} • Online',
                ),
              ),
            ),
          ),
        if (suggested.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'புதிய வாலிப நண்பர்கள் (Suggested)',
            style: TextStyle(
              color: Colors.tealAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          for (final f in suggested)
            Card(
              color: const Color(0xFF181A24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(f['avatar_color'] ?? 0xFFD84315),
                  child: const Icon(Icons.person_outline, color: Colors.white),
                ),
                title: Text(
                  f['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${f['city']} • ${f['bio']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                trailing: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE4AF37),
                    side: const BorderSide(color: Color(0xFFE4AF37)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () async {
                    if (_db == null) return;
                    await _db!.update(
                      'friends',
                      {'status': 'accepted'},
                      where: 'id = ?',
                      whereArgs: [f['id']],
                    );
                    _refreshAllData();
                  },
                  child: const Text(
                    '+ இணை',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildGroupsTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 85),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final grp = _groups[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF181A24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(grp['badge_color'] ?? 0xFF283593),
                      child: const Icon(Icons.groups, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            grp['name'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${grp['category']} • ${grp['members_count']} உறுப்பினர்கள்',
                            style: const TextStyle(
                              color: Color(0xFFE4AF37),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  grp['description'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'உறுப்பினர்கள்: ${grp['members_text']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE4AF37),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.forum_rounded, size: 16),
                      label: const Text(
                        'குழு சாட்',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      onPressed: () => _openChatRoom(
                        chatKey: 'group_${grp['id']}',
                        chatTitle: grp['name'] ?? 'Group',
                        isGroup: true,
                        subtitle: '${grp['members_count']} உறுப்பினர்கள்',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatsInboxTab() {
    if (_recentChats.isEmpty) {
      return const Center(
        child: Text(
          'நண்பர்கள் அல்லது குழுக்களைத் தொட்டு உரையாடலைத் தொடங்குங்கள்!',
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 85),
      itemCount: _recentChats.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        final chat = _recentChats[index];
        final bool isGroup = (chat['is_group'] ?? 0) == 1;
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          tileColor: const Color(0xFF181A24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor:
                isGroup ? const Color(0xFF1B4332) : const Color(0xFF283593),
            child: Icon(
              isGroup ? Icons.groups_rounded : Icons.person_rounded,
              color: Colors.white,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  chat['chat_title'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ),
              Text(
                chat['sent_time'] ?? '',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${chat['sender_name']}: ${chat['message_text']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 12.5),
            ),
          ),
          onTap: () => _openChatRoom(
            chatKey: chat['chat_key'] ?? '',
            chatTitle: chat['chat_title'] ?? '',
            isGroup: isGroup,
            subtitle: isGroup ? 'குழு உரையாடல்' : 'தனிப்பட்ட உரையாடல்',
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F1115);
    const Color cardDark = Color(0xFF181A24);
    const Color goldAccent = Color(0xFFE4AF37);

    String fabLabel = 'புதிய பதிவு';
    if (_tabController.index == 1) fabLabel = 'நண்பரை இணை';
    if (_tabController.index == 2) fabLabel = 'புதிய குழு';

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: cardDark,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: goldAccent),
            SizedBox(width: 8),
            Text(
              'Youth Social Hub',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: goldAccent,
          labelColor: goldAccent,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.dynamic_feed, size: 19), text: 'ஊட்டம்'),
            Tab(icon: Icon(Icons.people_alt, size: 19), text: 'நண்பர்கள்'),
            Tab(icon: Icon(Icons.groups, size: 19), text: 'குழுக்கள்'),
            Tab(icon: Icon(Icons.chat_bubble, size: 19), text: 'அரட்டை'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: goldAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFeedAndStoriesTab(),
                _buildFriendsTab(),
                _buildGroupsTab(),
                _buildChatsInboxTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 3
          ? null
          : FloatingActionButton.extended(
              backgroundColor: goldAccent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: Text(
                fabLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                if (_tabController.index == 0) {
                  _openCreatePostSheet();
                } else if (_tabController.index == 1) {
                  _openAddFriendSheet();
                } else if (_tabController.index == 2) {
                  _openCreateGroupSheet();
                }
              },
            ),
    );
  }
}

class YouthVideoPlayerWidget extends StatefulWidget {
  final String videoPath;

  const YouthVideoPlayerWidget({super.key, required this.videoPath});

  @override
  State createState() => _YouthVideoPlayerWidgetState();
}

class _YouthVideoPlayerWidgetState extends State {
  YouthVideoPlayerWidget get _w => widget as YouthVideoPlayerWidget;
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future _initVideo() async {
    final ctrl = VideoPlayerController.file(File(_w.videoPath));
    _controller = ctrl;
    try {
      await ctrl.initialize();
      await ctrl.setLooping(true);
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE4AF37)),
        ),
      );
    }

    final bool isPlaying = _controller!.value.isPlaying;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio > 0
                  ? _controller!.value.aspectRatio
                  : 16 / 9,
              child: VideoPlayer(_controller!),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: isPlaying ? 0.25 : 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFFE4AF37),
                  size: 36,
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 12,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isMuted = !_isMuted;
                    _controller!.setVolume(_isMuted ? 0.0 : 1.0);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFFE4AF37),
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class YouthChatRoomScreen extends StatefulWidget {
  final Database db;
  final String chatKey;
  final String chatTitle;
  final bool isGroup;
  final String subtitle;

  const YouthChatRoomScreen({
    super.key,
    required this.db,
    required this.chatKey,
    required this.chatTitle,
    required this.isGroup,
    this.subtitle = '',
  });

  @override
  State createState() => _YouthChatRoomScreenState();
}

class _YouthChatRoomScreenState extends State {
  YouthChatRoomScreen get _w => widget as YouthChatRoomScreen;

  final TextEditingController _msgCtrl = TextEditingController();
  final TextEditingController _verseCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List _messages = [];
  bool _showVerseBox = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _verseCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future _loadMessages() async {
    final rows = await _w.db.query(
      'chat_messages',
      where: 'chat_key = ?',
      whereArgs: [_w.chatKey],
      orderBy: 'id ASC',
    );
    if (!mounted) return;
    setState(() => _messages = rows);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  Future _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}';

    await _w.db.insert('chat_messages', {
      'chat_key': _w.chatKey,
      'chat_title': _w.chatTitle,
      'is_group': _w.isGroup ? 1 : 0,
      'sender_name': 'நீங்கள் (You)',
      'is_me': 1,
      'message_text': text,
      'verse_tag': _verseCtrl.text.trim(),
      'sent_time': timeStr,
    });

    _msgCtrl.clear();
    _verseCtrl.clear();
    setState(() => _showVerseBox = false);
    await _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F1115);
    const Color cardDark = Color(0xFF181A24);
    const Color goldAccent = Color(0xFFE4AF37);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: cardDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _w.isGroup
                  ? const Color(0xFF1B4332)
                  : const Color(0xFF283593),
              child: Icon(
                _w.isGroup ? Icons.groups : Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _w.chatTitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_w.subtitle.isNotEmpty)
                    Text(
                      _w.subtitle,
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'கிறிஸ்துவின் அன்புடன் உரையாடலைத் தொடங்குங்கள்!',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(14),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final bool isMe = (m['is_me'] ?? 0) == 1;
                      final String vTag = m['verse_tag']?.toString() ?? '';

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? goldAccent.withValues(alpha: 0.22)
                                : cardDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isMe
                                  ? goldAccent.withValues(alpha: 0.5)
                                  : Colors.white10,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe && _w.isGroup)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    m['sender_name'] ?? '',
                                    style: const TextStyle(
                                      color: goldAccent,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (vTag.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.indigo.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '📖 $vTag',
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Text(
                                m['message_text'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  m['sent_time'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_showVerseBox)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFF141720),
              child: TextField(
                controller: _verseCtrl,
                style: const TextStyle(color: Colors.amberAccent, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'வசனக் குறிப்பு இணைக்க (உதா: பிலிப்பியர் 4:13)',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 12.5),
                  prefixIcon: Icon(Icons.menu_book,
                      color: Colors.amberAccent, size: 18),
                  border: InputBorder.none,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            color: cardDark,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.menu_book_rounded,
                      color: _showVerseBox ? goldAccent : Colors.white54,
                    ),
                    tooltip: 'வேத வசனம் இணை',
                    onPressed: () =>
                        setState(() => _showVerseBox = !_showVerseBox),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'செய்தி அனுப்புங்கள்...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: bgDark,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: goldAccent,
                    child: IconButton(
                      icon:
                          const Icon(Icons.send, color: Colors.black, size: 19),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
