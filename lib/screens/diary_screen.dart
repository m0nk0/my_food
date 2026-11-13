import 'dart:io';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/diary_provider.dart';
import '../services/calculator_service.dart';
import '../data/database.dart';
import 'camera_screen.dart';
import 'onboarding_screen.dart';
import 'analytics_screen.dart';
import 'recipes_screen.dart';
import 'menu_screen.dart'; // <--- ДОБАВЛЕН ИМПОРТ

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  double _dailyGoal = 2000.0;
  double _proteinGoal = 100.0;
  double _fatGoal = 70.0;
  double _carbsGoal = 250.0;
  double _waterGoal = 2000.0;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final calories = await CalculatorService.getDailyCalories();
    final protein = await CalculatorService.getDailyProtein();
    final fat = await CalculatorService.getDailyFat();
    final carbs = await CalculatorService.getDailyCarbs();
    final water = await CalculatorService.getWaterGoal();
    
    if (mounted) {
      setState(() {
        _dailyGoal = calories;
        _proteinGoal = protein;
        _fatGoal = fat;
        _carbsGoal = carbs;
        _waterGoal = water;
      });
    }
  }

  void _openProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
    if (result == true) {
      _loadGoals();
    }
  }

  @override
  Widget build(BuildContext context) {
    final diary = Provider.of<DiaryProvider>(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    final now = DateTime.now();
    final isToday = diary.selectedDate.year == now.year && 
                    diary.selectedDate.month == now.month && 
                    diary.selectedDate.day == now.day;
    
    final dateString = isToday 
        ? 'Сегодня' 
        : DateFormat('d MMMM', 'ru_RU').format(diary.selectedDate); 
        
    final dayOfWeekString = DateFormat('EEEE', 'ru_RU').format(diary.selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          SafeArea(
            child: diary.isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    slivers: [
                      // Верхняя шапка
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateString,
                                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    dayOfWeekString[0].toUpperCase() + dayOfWeekString.substring(1),
                                    style: const TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.calendar_month, color: Colors.black87, size: 28),
                                    onPressed: () async {
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: diary.selectedDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                        locale: const Locale('ru', 'RU'),
                                      );
                                      if (pickedDate != null) {
                                        diary.loadEntriesForDate(pickedDate);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _openProfile,
                                    child: const CircleAvatar(
                                      radius: 26,
                                      backgroundColor: Colors.green,
                                      child: Icon(Icons.person, color: Colors.white, size: 32),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Главный круг калорий
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Center(
                            child: SizedBox(
                              width: 200,
                              height: 200,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value: (diary.totalCalories / _dailyGoal).clamp(0.0, 1.0),
                                    strokeWidth: 16,
                                    backgroundColor: Colors.green.shade100,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                                    strokeCap: StrokeCap.round,
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        diary.totalCalories.toStringAsFixed(0),
                                        style: const TextStyle(fontSize: 58, fontWeight: FontWeight.w900),
                                      ),
                                      Text(
                                        'из ${_dailyGoal.toStringAsFixed(0)} ккал', 
                                        style: const TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w600), 
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 30)),

                      // КОЛЬЦА БЖУ
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMacroRing('Белки', diary.totalProtein, _proteinGoal, Colors.red.shade400),
                              _buildMacroRing('Жиры', diary.totalFat, _fatGoal, Colors.orange.shade400),
                              _buildMacroRing('Углеводы', diary.totalCarbs, _carbsGoal, Colors.blue.shade400),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      // КНОПКИ ФИЧ
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildFeatureButton(
                                  title: 'Что поесть?',
                                  subtitle: 'Рецепты по КБЖУ',
                                  icon: Icons.restaurant_menu,
                                  color: Colors.orange,
                                  onTap: () {
                                    final hour = DateTime.now().hour;
                                    String mealType = 'перекус';
                                    if (hour >= 6 && hour < 12) mealType = 'завтрак';
                                    else if (hour >= 12 && hour < 17) mealType = 'обед';
                                    else if (hour >= 17 && hour < 22) mealType = 'ужин';

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => RecipesScreen(mealType: mealType)),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFeatureButton(
                                  title: 'Меню кафе', // <--- ИЗМЕНЕНО
                                  subtitle: 'Перевод и КБЖУ',
                                  icon: Icons.restaurant,
                                  color: Colors.purple,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const MenuScreen()),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 10)),

                      // БЛОК ВОДЫ
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Вода',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                                    ),
                                    Text(
                                      '${diary.totalWaterMl.toStringAsFixed(0)} / ${_waterGoal.toStringAsFixed(0)} мл',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate((_waterGoal / 250).ceil(), (index) {
                                    final isFilled = (diary.totalWaterMl / 250) > index;
                                    return Flexible(
                                      child: GestureDetector(
                                        onTap: () {
                                          if (!isFilled) {
                                            diary.addWater(250);
                                          } else {
                                            diary.removeLastWater();
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 2),
                                          child: Icon(
                                            Icons.water_drop,
                                            size: 24,
                                            color: isFilled ? Colors.blue : Colors.blue.shade100,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 75,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      _buildWaterOption('Чашка', 150, Icons.coffee),
                                      _buildWaterOption('Стакан', 200, Icons.local_drink),
                                      _buildWaterOption('Кружка', 250, Icons.coffee_maker),
                                      _buildWaterOption('Бут. 0.25', 250, Icons.local_drink_outlined),
                                      _buildWaterOption('Бут. 0.5', 500, Icons.water_drop_outlined),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 40)),

                      // Список блюд
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        sliver: diary.selectedDateEntries.isEmpty
                            ? SliverToBoxAdapter(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Text(
                                      isToday ? 'Пока пусто. Добавьте первое блюдо!' : 'В этот день ничего не добавлено.',
                                      style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final entry = diary.selectedDateEntries[index];
                                    return Dismissible(
                                      key: Key(entry.id.toString()),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(Icons.delete, color: Colors.white, size: 30),
                                      ),
                                      onDismissed: (direction) {
                                        diary.deleteEntry(entry.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${entry.dishName} удалено')),
                                        );
                                      },
                                      child: GestureDetector(
                                        onTap: () => _showEditDialog(context, diary, entry),
                                        child: Card(
                                          elevation: 0,
                                          margin: const EdgeInsets.only(bottom: 12),
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: BorderSide(color: Colors.grey.shade200),
                                          ),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.all(16),
                                            leading: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: entry.imagePath != null
                                                  ? Image.file(File(entry.imagePath!), width: 60, height: 60, fit: BoxFit.cover)
                                                  : Container(
                                                      width: 60, height: 60,
                                                      color: Colors.grey.shade200,
                                                      child: const Icon(Icons.fastfood, color: Colors.grey, size: 30),
                                                    ),
                                            ),
                                            title: Text(entry.dishName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                            subtitle: Text('${entry.weight.toStringAsFixed(0)} г', style: const TextStyle(fontSize: 15)),
                                            trailing: Text(
                                              '${entry.calories.toStringAsFixed(0)} ккал',
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: diary.selectedDateEntries.length,
                                ),
                              ),
                      ),
                      
                      SliverToBoxAdapter(child: SizedBox(height: 120 + bottomPadding)),
                    ],
                  ),
          ),
          
          // LIQUID GLASS BOTTOM BAR
          Positioned(
            left: 0,
            right: 0,
            bottom: 0, 
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: _buildLiquidGlassBottomBar(context, diary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterOption(String label, double ml, IconData icon) {
    final diary = Provider.of<DiaryProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => diary.addWater(ml),
        child: Container(
          width: 85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.blue, size: 24),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
              Text('$ml мл', style: const TextStyle(fontSize: 10, color: Colors.blue)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroRing(String label, double current, double goal, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 75,
          height: 75,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0,
                strokeWidth: 8,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text(
                  current.toStringAsFixed(0),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: color), 
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12), 
        Text(
          label, 
          style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold), 
        ),
        Text(
          'из ${goal.toStringAsFixed(0)} г', 
          style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600), 
        ),
      ],
    );
  }

  Widget _buildLiquidGlassBottomBar(BuildContext context, DiaryProvider diary) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.5), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.book, color: Colors.green, size: 32),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                  );
                },
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CameraScreen()),
                  ).then((_) => diary.loadEntriesForDate(diary.selectedDate));
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person, color: Colors.grey, size: 32),
                onPressed: _openProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, DiaryProvider diary, DiaryEntry entry) {
    final nameController = TextEditingController(text: entry.dishName);
    final weightController = TextEditingController(text: entry.weight.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Редактировать блюдо', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название блюда'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Вес (г)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () {
                final newWeight = double.tryParse(weightController.text) ?? entry.weight;
                final newName = nameController.text.trim().isEmpty ? entry.dishName : nameController.text;
                
                final ratio = newWeight / entry.weight;
                final newCalories = entry.calories * ratio;

                diary.updateEntry(
                  id: entry.id,
                  name: newName,
                  weight: newWeight,
                  calories: newCalories,
                  protein: entry.protein * ratio,
                  fat: entry.fat * ratio,
                  carbs: entry.carbs * ratio,
                );
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }
}