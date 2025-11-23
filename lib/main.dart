import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'factory_db/factory_database.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'ui/main_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 必要に応じてテストデータを投入する（本番では削除してください）
  final db = await FactoryDatabase.instance.database;
  await db.insert(
    'projects',
    {'id': 1, 'name': 'テスト工事A'},
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
  await db.insert(
    'products',
    {
      'id': 1,
      'project_id': 1,
      'product_code': 'ABC-001',
    },
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());

  final now = DateTime.now();
  final formatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
  // 起動ログ（デバッグ用）  // ignore: avoid_print
  print('アプリ起動時刻: $formatted');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: '溶接測定データ管理',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.compact(),
        home: const MainScaffold(),
      ),
    );
  }
}
