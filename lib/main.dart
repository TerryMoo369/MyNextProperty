import 'package:flutter/material.dart';
import 'package:mynextproperty/screens/main_layout.dart';
import 'package:mynextproperty/services/dataSync_service.dart';
import 'package:provider/provider.dart';
import 'Data/databaseHelper.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/search_filter_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure Flutter bindings are initialized before accessing native channels (SQLite)
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Database Cache immediately
  // This ensures the local SQLite tables are created before the UI queries them
  final dbHelper = DatabaseHelper();
  await dbHelper.database;

  // Trigger Background API Sync
  // DO NOT 'await' this. It runs silently in the background.
  final syncService = DataSyncService();
  syncService.syncAllBackground();

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