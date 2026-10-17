import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'bible_books_data.dart';

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
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER NOT NULL,
      chapter INTEGER NOT NULL,
      verse INTEGER NOT NULL,
      text_ta TEXT NOT NULL,
      text_en TEXT NOT NULL,
      FOREIGN KEY (book_id) REFERENCES books (id)
    )
    ''');

    for (var book in BibleBooksData.books) {
      await db.insert('books', book);
    }
  }

  Future<List<Map<String, dynamic>>> getAllBooks() async {
    final db = await instance.database;
    return await db.query('books', orderBy: 'id ASC');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
