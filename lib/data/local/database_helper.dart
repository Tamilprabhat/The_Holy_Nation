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
    await _ensureBookmarksTable(db);
    return db;
  }

  Future<void> _ensureBookmarksTable(Database db) async {
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

  // தமிழ் மற்றும் ஆங்கில வசனங்களில் தேடும் முறை
  Future<List> searchVerses(String keyword) async {
    final clean = keyword.trim();
    if (clean.isEmpty) return [];
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        v.book_id,
        v.chapter,
        v.verse,
        v.text_ta,
        v.text_en,
        b.name_ta,
        b.name_en,
        b.testament,
        b.chapters_count
      FROM verses v
      INNER JOIN books b ON v.book_id = b.id
      WHERE v.text_ta LIKE ? OR v.text_en LIKE ?
      ORDER BY v.book_id ASC, v.chapter ASC, v.verse ASC
      LIMIT 100
    ''', ['%$clean%', '%$clean%']);
  }

  // குறிப்பிட்ட அதிகாரத்தில் புக்மார்க் செய்யப்பட்ட வசன எண்களை எடுத்தல்
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

  // புக்மார்க் சேர்த்தல் அல்லது நீக்குதல்
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

  // சேமிக்கப்பட்ட அனைத்து புக்மார்க்குகளையும் எடுத்தல்
  Future<List> getAllBookmarks() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        bm.id as bookmark_id,
        bm.book_id,
        bm.chapter,
        bm.verse,
        v.text_ta,
        v.text_en,
        b.name_ta,
        b.name_en,
        b.testament,
        b.chapters_count
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
