import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/database.dart';
import 'providers/diary_provider.dart';
import 'providers/food_analysis_provider.dart' as food_provider; 
import 'screens/onboarding_screen.dart';
import 'screens/diary_screen.dart'; // <--- ВОТ ЭТОТ ИМПОРТ БЫЛ ПОТЕРЯН

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool('isFirstRun') ?? true;

  runApp(MyApp(isFirstRun: isFirstRun));
}

class MyApp extends StatelessWidget {
  final bool isFirstRun;
  const MyApp({super.key, required this.isFirstRun});

  @override
  Widget build(BuildContext context) {
    final AppDatabase database = AppDatabase();

    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider(create: (context) => DiaryProvider(database)),
        ChangeNotifierProvider(create: (context) => food_provider.FoodAnalysisProvider()),
      ],
      child: MaterialApp(
        title: 'Моя Еда',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru', 'RU'),
          Locale('en', 'US'),
        ],
        locale: const Locale('ru', 'RU'),
        home: isFirstRun ? const OnboardingScreen() : DiaryScreen(),
      ),
    );
  }
}