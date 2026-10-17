import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb('holy_nation.db');
    return _database!;
  }

  Future<Database> _initDb(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load('assets/$filePath');
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Write copied bytes to the local device storage
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path);
  }

  Future<List<Map<String, dynamic>>> getAllBooks() async {
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
    return 0;
  }

  Future<List<Map<String, dynamic>>> getVerses(int bookId, int chapter) async {
    final db = await instance.database;
    return await db.query(
      'verses',
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
      orderBy: 'verse ASC',
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
