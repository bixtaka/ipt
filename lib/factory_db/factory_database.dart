import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

/// factory_app.db を管理するシングルトン
class FactoryDatabase {
  FactoryDatabase._internal();

  /// どこからでも同じインスタンスを使えるようにする
  static final FactoryDatabase instance = FactoryDatabase._internal();

  Database? _database;

  /// SQLite データベースへのアクセサ
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _openDatabase();
    return _database!;
  }

  /// factory_app.db を開く（なければ作成）
  Future<Database> _openDatabase() async {
    // アプリのドキュメントフォルダに DB を作成
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(documentsDir.path, 'factory_app.db');

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqflite_ffi.sqfliteFfiInit();
      final factory = sqflite_ffi.databaseFactoryFfi;
      return await factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async => _createTables(db),
        ),
      );
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await _createTables(db);
      },
    );
  }

  /// 必要なテーブルを作成
  Future<void> _createTables(Database db) async {
    // 工事名テーブル
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects(
        id INTEGER PRIMARY KEY,
        name TEXT
      )
    ''');

    // 製品符号テーブル
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products(
        id INTEGER PRIMARY KEY,
        project_id INTEGER,
        product_code TEXT
      )
    ''');
  }

  /// 工事一覧を取得
  Future<List<Map<String, dynamic>>> getProjects() async {
    final db = await database;
    return await db.query(
      'projects',
      orderBy: 'name ASC',
    );
  }

  /// 指定した工事IDに紐づく製品一覧を取得
  Future<List<Map<String, dynamic>>> getProductsByProject(int projectId) async {
    final db = await database;
    return await db.query(
      'products',
      where: 'project_id = ?',
      whereArgs: <Object>[projectId],
      orderBy: 'product_code ASC',
    );
  }

  /// 必要なら明示的にクローズしたいとき用
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
