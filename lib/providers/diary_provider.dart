import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import '../data/database.dart';

class DiaryProvider extends ChangeNotifier {
  final AppDatabase db;
  List<DiaryEntry> selectedDateEntries = [];
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  
  // Переменные для воды
  double _totalWaterMl = 0.0;
  double get totalWaterMl => _totalWaterMl;

  DiaryProvider(this.db) {
    loadEntriesForDate(DateTime.now());
  }

  Future<void> loadEntriesForDate(DateTime date) async {
    isLoading = true;
    selectedDate = date;
    notifyListeners();

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Загружаем еду
    final query = db.select(db.diaryEntries)
      ..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);

    selectedDateEntries = await query.get();
    
    // Загружаем воду
    final waterQuery = db.select(db.waterEntries)
      ..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay));
    final waterEntriesList = await waterQuery.get();
    
    _totalWaterMl = waterEntriesList.fold(0.0, (sum, item) => sum + item.amountMl);
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> addWater(double ml) async {
    await db.into(db.waterEntries).insert(WaterEntriesCompanion.insert(
      amountMl: ml,
      createdAt: Value(selectedDate),
    ));
    await loadEntriesForDate(selectedDate);
  }

  Future<void> removeLastWater() async {
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
    
    final query = db.select(db.waterEntries)
      ..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
      ..limit(1);
      
    final lastEntry = await query.getSingleOrNull();
    if (lastEntry != null) {
      await (db.delete(db.waterEntries)..where((t) => t.id.equals(lastEntry.id))).go();
      await loadEntriesForDate(selectedDate);
    }
  }

  Future<void> addEntry({
    required String name,
    required double weight,
    required double calories,
    double protein = 0,
    double fat = 0,
    double carbs = 0,
    String? imagePath,
  }) async {
    await db.into(db.diaryEntries).insert(DiaryEntriesCompanion.insert(
      dishName: name,
      weight: weight,
      calories: calories,
      protein: Value(protein),
      fat: Value(fat),
      carbs: Value(carbs),
      imagePath: Value(imagePath),
      createdAt: Value(selectedDate),
    ));
    await loadEntriesForDate(selectedDate);
  }

  Future<void> deleteEntry(int id) async {
    await (db.delete(db.diaryEntries)..where((t) => t.id.equals(id))).go();
    await loadEntriesForDate(selectedDate);
  }

  Future<void> updateEntry({
    required int id,
    required String name,
    required double weight,
    required double calories,
    double protein = 0,
    double fat = 0,
    double carbs = 0,
  }) async {
    await (db.update(db.diaryEntries)..where((t) => t.id.equals(id))).write(
      DiaryEntriesCompanion(
        dishName: Value(name),
        weight: Value(weight),
        calories: Value(calories),
        protein: Value(protein),
        fat: Value(fat),
        carbs: Value(carbs),
      ),
    );
    await loadEntriesForDate(selectedDate);
  }

  double get totalCalories => selectedDateEntries.fold(0, (sum, item) => sum + item.calories);
  double get totalProtein => selectedDateEntries.fold(0, (sum, item) => sum + item.protein);
  double get totalFat => selectedDateEntries.fold(0, (sum, item) => sum + item.fat);
  double get totalCarbs => selectedDateEntries.fold(0, (sum, item) => sum + item.carbs);
}