import 'package:flutter/material.dart';
import 'package:mynextproperty/services/data_gov_sync_service.dart';
import 'package:mynextproperty/views/main_layout.dart';
import 'package:provider/provider.dart';

import 'data/database_helper.dart';
import 'providers/search_filter_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper();
  await dbHelper.database;

  final syncService = DataSyncService();
  await syncService.syncAllBackground();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SearchFilterProvider()),
      ],
      builder: (context, _) {
        final themeProvider = Provider.of<ThemeProvider>(context);

        return MaterialApp(
          title: 'MyNextProperty',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MainLayout(),
        );
      },
    );
  }
}
