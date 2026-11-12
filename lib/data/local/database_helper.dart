import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('holy_nation.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load('assets/$filePath');
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    final db = await openDatabase(path);
    await _ensureExtraTables(db);
    return db;
  }

  Future<void> _ensureExtraTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(book_id, chapter, verse)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        read_at TEXT NOT NULL,
        UNIQUE(book_id, chapter)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_posters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        ref_title TEXT NOT NULL,
        verse_text TEXT NOT NULL,
        author_name TEXT NOT NULL,
        bg_color INTEGER NOT NULL,
        image_path TEXT,
        likes_count INTEGER NOT NULL DEFAULT 1,
        is_liked INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // பழைய டேபிளில் image_path இல்லையென்றால் பாதுகாப்பாகச் சேர்த்தல்
    try {
      await db.execute('ALTER TABLE user_posters ADD COLUMN image_path TEXT');
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS topic_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_key TEXT NOT NULL,
        author_name TEXT NOT NULL,
        message_text TEXT NOT NULL,
        verse_ref TEXT,
        likes_count INTEGER NOT NULL DEFAULT 1,
        is_liked INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    final countRes =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM user_posters');
    final count = (countRes.first['cnt'] as int?) ?? 0;
    if (count == 0) {
      final now = DateTime.now().toIso8601String();
      await db.insert('user_posters', {
        'category': 'promise',
        'ref_title': 'ஏசாயா (Isaiah) 41:10',
        'verse_text':
            'நீ பயப்படாதே, நான் உன்னுடனே இருக்கிறேன்; திகையாதே, நான் உன் தேவன்; நான் உன்னைப் பலப்படுத்தி உனக்குச் சகாயம்பண்ணுவேன்.',
        'author_name': 'ஆபிரகாம் (Abraham)',
        'bg_color': 0xFF1E2A4A,
        'image_path': null,
        'likes_count': 48,
        'is_liked': 0,
        'created_at': now,
      });
      await db.insert('user_posters', {
        'category': 'promise',
        'ref_title': 'யோசுவா (Joshua) 1:9',
        'verse_text':
            'பலங்கொண்டு திடமனதாயிரு; திகையாதே, கலங்காதே, நீ போகும் இடமெல்லாம் உன் தேவனாகிய கர்த்தர் உன்னோடே இருக்கிறார்.',
        'author_name': 'எஸ்தர் (Esther)',
        'bg_color': 0xFF2B2144,
        'image_path': null,
        'likes_count': 35,
        'is_liked': 0,
        'created_at': now,
      });
      await db.insert('user_posters', {
        'category': 'confession',
        'ref_title': 'பிலிப்பியர் (Philippians) 4:13',
        'verse_text':
            'என்னைப் பெலப்படுத்துகிற கிறிஸ்துவினாலே எல்லாவற்றையுஞ்செய்ய எனக்குப் பெலனுண்டு.',
        'author_name': 'தாவீது (David)',
        'bg_color': 0xFF1B363D,
        'image_path': null,
        'likes_count': 62,
        'is_liked': 0,
        'created_at': now,
      });
      await db.insert('user_posters', {
        'category': 'confession',
        'ref_title': 'சங்கீதம் (Psalms) 138:8',
        'verse_text':
            'கர்த்தர் எனக்காக யாவையும் செய்து முடிப்பார்; கர்த்தாவே, உமது கிருபை என்றுமுள்ளது.',
        'author_name': 'ரூத் (Ruth)',
        'bg_color': 0xFF3A243B,
        'image_path': null,
        'likes_count': 41,
        'is_liked': 0,
        'created_at': now,
      });
    }

    final msgCountRes =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM topic_messages');
    final msgCount = (msgCountRes.first['cnt'] as int?) ?? 0;
    if (msgCount == 0) {
      final now = DateTime.now().toIso8601String();
      await db.insert('topic_messages', {
        'topic_key': '#அன்பு (Love)',
        'author_name': 'யோவான் (John)',
        'message_text':
            'அன்பில்லாதவன் தேவனை அறியான்; தேவன் அன்பாகவே இருக்கிறார். ஒருவரிலொருவர் அன்புகூருவதே கிறிஸ்துவின் பிரமாணம்.',
        'verse_ref': '1 யோவான் 4:8',
        'likes_count': 142,
        'is_liked': 0,
        'created_at': now,
      });
      await db.insert('topic_messages', {
        'topic_key': '#அன்பு (Love)',
        'author_name': 'மரியாள் (Mary)',
        'message_text':
            'மன்னிக்கும் இருதயம் உள்ள இடத்தில் தேவனுடைய அன்பு பரிபூரணமாக வெளிப்படும்.',
        'verse_ref': 'கொலோசெயர் 3:14',
        'likes_count': 54,
        'is_liked': 0,
        'created_at': now,
      });
      await db.insert('topic_messages', {
        'topic_key': '#விசுவாசம் (Faith)',
        'author_name': 'பேதுரு (Peter)',
        'message_text':
            'சூழ்நிலைகள் எதிராக இருந்தாலும், வாக்குத்தத்தம் பண்ணினவர் உண்மையுள்ளவர் என்று விசுவாசிக்கும்போது அற்புதங்கள் நடக்கும்.',
        'verse_ref': 'எபிரெயர் 11:1',
        'likes_count': 118,
        'is_liked': 0,
        'created_at': now,
      });
      await db.insert('topic_messages', {
        'topic_key': '#ஜெபம் (Prayer)',
        'author_name': 'அன்னாள் (Hannah)',
        'message_text':
            'கண்ணீரோடு ஏறெடுக்கப்படும் எந்த ஜெபத்தையும் தேவன் மறப்பதில்லை; ஏற்ற வேளையில் நிச்சயம் பதிலளிப்பார்.',
        'verse_ref': '1 சாமுவேல் 1:27',
        'likes_count': 96,
        'is_liked': 0,
        'created_at': now,
      });
      await db.insert('topic_messages', {
        'topic_key': '#சமாதானம் (Peace)',
        'author_name': 'பவுல் (Paul)',
        'message_text':
            'எல்லாப் புத்திக்கும் மேலான தேவசமாதானம் உங்கள் இருதயங்களையும் சிந்தைகளையும் கிறிஸ்து இயேசுவுக்குள் காத்துக்கொள்ளும்.',
        'verse_ref': 'பிலிப்பியர் 4:7',
        'likes_count': 84,
        'is_liked': 0,
        'created_at': now,
      });
    }
  }

  Future<List> getAllBooks() async {
    final db = await instance.database;
    return await db.query('books', orderBy: 'id ASC');
  }

  Future<int> getChapterCount(int bookId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT MAX(chapter) as max_chapter FROM verses WHERE book_id = ?',
      [bookId],
    );
    if (result.isNotEmpty && result.first['max_chapter'] != null) {
      return result.first['max_chapter'] as int;
    }
    return 1;
  }

  Future<List> getVerses(int bookId, int chapter) async {
    final db = await instance.database;
    return await db.query(
      'verses',
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
      orderBy: 'verse ASC',
    );
  }

  Future<dynamic> getSingleVerse(int bookId, int chapter, int verse) async {
    final db = await instance.database;
    final rows = await db.rawQuery('''
      SELECT v.book_id, v.chapter, v.verse, v.text_ta, v.text_en,
             b.name_ta, b.name_en, b.testament, b.chapters_count
      FROM verses v
      INNER JOIN books b ON v.book_id = b.id
      WHERE v.book_id = ? AND v.chapter = ? AND v.verse = ?
      LIMIT 1
    ''', [bookId, chapter, verse]);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<bool> isChapterAlreadyRead(int bookId, int chapter) async {
    final db = await instance.database;
    final rows = await db.query(
      'reading_progress',
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
    );
    return rows.isNotEmpty;
  }

  Future<void> recordChapterRead(int bookId, int chapter) async {
    final db = await instance.database;
    await db.insert(
      'reading_progress',
      {
        'book_id': bookId,
        'chapter': chapter,
        'read_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<dynamic> getReadingSummary() async {
    final db = await instance.database;
    final totalRes =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM reading_progress');
    final int totalRead = (totalRes.first['cnt'] as int?) ?? 0;

    final lastRows = await db.rawQuery('''
      SELECT rp.book_id, rp.chapter, rp.read_at,
             b.name_ta, b.name_en, b.testament, b.chapters_count
      FROM reading_progress rp
      INNER JOIN books b ON rp.book_id = b.id
      ORDER BY rp.read_at DESC
      LIMIT 1
    ''');

    return {
      'total_read': totalRead,
      'last_read': lastRows.isNotEmpty ? lastRows.first : null,
    };
  }

  Future<List> getPostersByCategory(String category) async {
    final db = await instance.database;
    return await db.query(
      'user_posters',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'likes_count DESC, id DESC',
    );
  }

  Future<void> addUserPoster({
    required String category,
    required String refTitle,
    required String verseText,
    required String authorName,
    required int bgColor,
    String? imagePath,
  }) async {
    final db = await instance.database;
    await db.insert('user_posters', {
      'category': category,
      'ref_title': refTitle,
      'verse_text': verseText,
      'author_name': authorName,
      'bg_color': bgColor,
      'image_path': imagePath,
      'likes_count': 1,
      'is_liked': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> togglePosterLike(int id, int currentLikes, int isLiked) async {
    final db = await instance.database;
    final bool nextLiked = isLiked == 0;
    final int nextCount =
        nextLiked ? currentLikes + 1 : (currentLikes > 0 ? currentLikes - 1 : 0);
    await db.update(
      'user_posters',
      {'likes_count': nextCount, 'is_liked': nextLiked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List> getTopicMessages(String topicKey) async {
    final db = await instance.database;
    return await db.query(
      'topic_messages',
      where: 'topic_key = ?',
      whereArgs: [topicKey],
      orderBy: 'likes_count DESC, id DESC',
    );
  }

  Future<void> addTopicMessage({
    required String topicKey,
    required String authorName,
    required String messageText,
    String? verseRef,
  }) async {
    final db = await instance.database;
    await db.insert('topic_messages', {
      'topic_key': topicKey,
      'author_name': authorName,
      'message_text': messageText,
      'verse_ref': verseRef ?? '',
      'likes_count': 1,
      'is_liked': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> toggleTopicMessageLike(
      int id, int currentLikes, int isLiked) async {
    final db = await instance.database;
    final bool nextLiked = isLiked == 0;
    final int nextCount =
        nextLiked ? currentLikes + 1 : (currentLikes > 0 ? currentLikes - 1 : 0);
    await db.update(
      'topic_messages',
      {'likes_count': nextCount, 'is_liked': nextLiked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List> searchVerses(String keyword) async {
    final clean = keyword.trim();
    if (clean.isEmpty) return [];
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        v.book_id, v.chapter, v.verse, v.text_ta, v.text_en,
        b.name_ta, b.name_en, b.testament, b.chapters_count
      FROM verses v
      INNER JOIN books b ON v.book_id = b.id
      WHERE v.text_ta LIKE ? OR v.text_en LIKE ?
      ORDER BY v.book_id ASC, v.chapter ASC, v.verse ASC
      LIMIT 100
    ''', ['%$clean%', '%$clean%']);
  }

  Future<Set> getBookmarkedVerseNumbers(int bookId, int chapter) async {
    final db = await instance.database;
    final rows = await db.query(
      'bookmarks',
      columns: ['verse'],
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
    );
    return rows.map((r) => r['verse'] as int).toSet();
  }

  Future<bool> toggleBookmark(int bookId, int chapter, int verse) async {
    final db = await instance.database;
    final existing = await db.query(
      'bookmarks',
      where: 'book_id = ? AND chapter = ? AND verse = ?',
      whereArgs: [bookId, chapter, verse],
    );

    if (existing.isNotEmpty) {
      await db.delete(
        'bookmarks',
        where: 'book_id = ? AND chapter = ? AND verse = ?',
        whereArgs: [bookId, chapter, verse],
      );
      return false;
    } else {
      await db.insert('bookmarks', {
        'book_id': bookId,
        'chapter': chapter,
        'verse': verse,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    }
  }

  Future<List> getAllBookmarks() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        bm.id as bookmark_id, bm.book_id, bm.chapter, bm.verse,
        v.text_ta, v.text_en, b.name_ta, b.name_en, b.testament, b.chapters_count
      FROM bookmarks bm
      INNER JOIN verses v 
        ON bm.book_id = v.book_id AND bm.chapter = v.chapter AND bm.verse = v.verse
      INNER JOIN books b ON bm.book_id = b.id
      ORDER BY bm.id DESC
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
