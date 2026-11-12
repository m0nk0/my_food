import 'package:drift/drift.dart';

// Таблица для очереди загрузки (если интернет пропал)
class FoodQueues extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get imagePath => text().withLength(min: 1, max: 500)();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttempt => dateTime().clientDefault(() => DateTime.now())();
  TextColumn get status => text().withLength(min: 1, max: 20).withDefault(const Constant('pending'))();
}

// Таблица: Дневник питания
class DiaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dishName => text()();
  RealColumn get weight => real()();
  RealColumn get calories => real()();
  RealColumn get protein => real().withDefault(const Constant(0))();
  RealColumn get fat => real().withDefault(const Constant(0))();
  RealColumn get carbs => real().withDefault(const Constant(0))();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
}

// НОВАЯ ТАБЛИЦА: Дневник воды
class WaterEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amountMl => real()(); // Количество воды в мл
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
}