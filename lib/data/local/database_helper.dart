import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'bible_books_data.dart';
import 'bible_verses_data.dart';

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE books (
      id INTEGER PRIMARY KEY,
      testament TEXT NOT NULL,
      name_ta TEXT NOT NULL,
      name_en TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE verses (
      id INTEGER PRIMARY KEY,
      book_id INTEGER NOT NULL,
      chapter INTEGER NOT NULL,
      verse INTEGER NOT NULL,
      text_ta TEXT NOT NULL,
      text_en TEXT NOT NULL,
      FOREIGN KEY (book_id) REFERENCES books (id)
    )
    ''');

    // புத்தகங்களை ஏற்றுகிறோம்
    for (var book in BibleBooksData.books) {
      await db.insert('books', book);
    }

    // வசனங்களை ஏற்றுகிறோம் (Mock Data)
    final verses = BibleVersesData.generateMockVerses();
    for (var verse in verses) {
      await db.insert('verses', verse);
    }
  }

  Future<List<Map<String, dynamic>>> getAllBooks() async {
    final db = await instance.database;
    return await db.query('books', orderBy: 'id ASC');
  }

  // ஒரு புத்தகத்தின் மொத்த அதிகாரங்களைக் கண்டுபிடிக்கும் Function
  Future<int> getChapterCount(int bookId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT MAX(chapter) as max_chapter FROM verses WHERE book_id = ?',
        [bookId]);
    if (result.isNotEmpty && result.first['max_chapter'] != null) {
      return result.first['max_chapter'] as int;
    }
    return 0;
  }

  // ஒரு குறிப்பிட்ட அதிகாரம் மற்றும் புத்தகத்தின் வசனங்களை எடுக்கும் Function
  Future<List<Map<String, dynamic>>> getVerses(int bookId, int chapter) async {
    final db = await instance.database;
    return await db.query('verses',
        where: 'book_id = ? AND chapter = ?',
        whereArgs: [bookId, chapter],
        orderBy: 'verse ASC');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
