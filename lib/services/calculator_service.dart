import 'package:shared_preferences/shared_preferences.dart';

class CalculatorService {
  // 1. Расчет суточной нормы калорий (формула Миффлина-Сан Жеора)
  static double calculateDailyCalories({
    required double weight,
    required double height,
    required String activity,
    required String goal,
    int age = 25,
  }) {
    double bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;

    double activityMultiplier = 1.2;
    if (activity == 'Средняя') activityMultiplier = 1.55;
    if (activity == 'Высокая') activityMultiplier = 1.725;

    double tdee = bmr * activityMultiplier;

    if (goal == 'Похудеть') return tdee - 500;
    if (goal == 'Набрать массу') return tdee + 500;
    return tdee;
  }

  // 2. Расчет нормы воды (30 мл на 1 кг веса)
  static double calculateWaterGoal(double weight) {
    return weight * 30;
  }

  // 3. Сохранение сырых данных профиля
  static Future<void> saveUserProfile({
    required double weight,
    required double height,
    required String activity,
    required String goal,
    required bool hasAllergies,
    required String allergies,
    required bool hasDiseases,
    required String diseases,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('userWeight', weight);
    await prefs.setDouble('userHeight', height);
    await prefs.setString('userActivity', activity);
    await prefs.setString('userGoal', goal);
    await prefs.setBool('userHasAllergies', hasAllergies);
    await prefs.setString('userAllergies', allergies);
    await prefs.setBool('userHasDiseases', hasDiseases);
    await prefs.setString('userDiseases', diseases);
  }

  // 4. Загрузка сырых данных профиля
  static Future<Map<String, dynamic>> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'weight': prefs.getDouble('userWeight') ?? 70.0,
      'height': prefs.getDouble('userHeight') ?? 170.0,
      'activity': prefs.getString('userActivity') ?? 'Средняя',
      'goal': prefs.getString('userGoal') ?? 'Поддерживать форму',
      'hasAllergies': prefs.getBool('userHasAllergies') ?? false,
      'allergies': prefs.getString('userAllergies') ?? '',
      'hasDiseases': prefs.getBool('userHasDiseases') ?? false,
      'diseases': prefs.getString('userDiseases') ?? '',
    };
  }

  // 5. Сохранение посчитанных целей (калории, БЖУ, вода)
  static Future<void> saveDailyGoals({
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    required double water,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dailyCalories', calories);
    await prefs.setDouble('dailyProtein', protein);
    await prefs.setDouble('dailyFat', fat);
    await prefs.setDouble('dailyCarbs', carbs);
    await prefs.setDouble('dailyWaterGoal', water);
  }

  // 6. Получение целей (с дефолтными значениями)
  static Future<double> getDailyCalories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('dailyCalories') ?? 2000.0;
  }

  static Future<double> getDailyProtein() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('dailyProtein') ?? 100.0;
  }

  static Future<double> getDailyFat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('dailyFat') ?? 70.0;
  }

  static Future<double> getDailyCarbs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('dailyCarbs') ?? 250.0;
  }

  static Future<double> getWaterGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('dailyWaterGoal') ?? 2000.0;
  }
}