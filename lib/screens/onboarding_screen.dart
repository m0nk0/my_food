import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diary_screen.dart'; 
import '../services/calculator_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = true;
  bool _hasChanges = false; // Флаг, изменились ли данные

  Map<String, dynamic> _userData = {
    'weight': 70.0,
    'height': 170.0,
    'activity': 'Средняя',
    'hasAllergies': false,
    'allergies': '',
    'hasDiseases': false,
    'diseases': '',
    'goal': 'Поддерживать форму',
  };

  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _allergiesController;
  late TextEditingController _diseasesController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _allergiesController = TextEditingController();
    _diseasesController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await CalculatorService.loadUserProfile();
    setState(() {
      _userData = data;
      _weightController.text = data['weight'].toString();
      _heightController.text = data['height'].toString();
      _allergiesController.text = data['allergies'];
      _diseasesController.text = data['diseases'];
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _allergiesController.dispose();
    _diseasesController.dispose();
    super.dispose();
  }

  // Функция, которая пересчитывает и сохраняет цели
  Future<void> _saveDataAndRecalculate() async {
    // 1. Сохраняем сырые данные
    await CalculatorService.saveUserProfile(
      weight: _userData['weight'],
      height: _userData['height'],
      activity: _userData['activity'],
      goal: _userData['goal'],
      hasAllergies: _userData['hasAllergies'],
      allergies: _userData['allergies'],
      hasDiseases: _userData['hasDiseases'],
      diseases: _userData['diseases'],
    );

    // 2. Считаем калории и БЖУ
    final calories = CalculatorService.calculateDailyCalories(
      weight: _userData['weight'],
      height: _userData['height'],
      activity: _userData['activity'],
      goal: _userData['goal'],
    );
    final protein = (calories * 0.3) / 4;
    final fat = (calories * 0.3) / 9;
    final carbs = (calories * 0.4) / 4;

    // 3. Считаем норму воды (30 мл на 1 кг веса)
    final water = CalculatorService.calculateWaterGoal(_userData['weight']);

    // 4. Сохраняем все цели
    await CalculatorService.saveDailyGoals(
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      water: water,
    );
  }

  // Нажатие на крестик (закрыть)
  void _onClose() async {
    if (_hasChanges) {
      await _saveDataAndRecalculate();
    }
    if (mounted && context.mounted) {
      Navigator.pop(context, true); // Возвращаем true, чтобы Дневник обновился
    }
  }

  // Нажатие на "Далее" / "Сохранить"
  Future<void> _onFinish() async {
    FocusScope.of(context).unfocus();
    await _saveDataAndRecalculate();
    
    if (mounted && context.mounted) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DiaryScreen()),
        );
      }
    }
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();

    if (_currentPage < 4) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false, // Перехватываем кнопку "Назад"
      onPopInvoked: (didPop) async {
        if (didPop) return;
                _onClose(); // При выходе сохраняем
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: _onClose, // При нажатии крестика сохраняем
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: List.generate(5, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        decoration: BoxDecoration(
                          color: index <= _currentPage ? Colors.green : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(), 
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    _buildStep(
                      title: 'Давай познакомимся',
                      subtitle: 'Эти данные нужны для расчета твоей нормы калорий.',
                      child: Column(
                        children: [
                          _buildNumberField('Вес (кг)', _weightController, (val) {
                            _userData['weight'] = double.tryParse(val) ?? 70.0;
                            _hasChanges = true;
                          }),
                          const SizedBox(height: 16),
                          _buildNumberField('Рост (см)', _heightController, (val) {
                            _userData['height'] = double.tryParse(val) ?? 170.0;
                            _hasChanges = true;
                          }),
                        ],
                      ),
                    ),
                    _buildStep(
                      title: 'Физическая активность',
                      subtitle: 'Как часто ты тренируешься или двигаешься?',
                      child: Column(
                        children: ['Низкая', 'Средняя', 'Высокая'].map((level) {
                          return RadioListTile<String>(
                            title: Text(level, style: const TextStyle(fontSize: 18)),
                            value: level,
                            groupValue: _userData['activity'],
                            activeColor: Colors.green,
                            onChanged: (val) {
                              setState(() => _userData['activity'] = val);
                              _hasChanges = true;
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    _buildStep(
                      title: 'Аллергии',
                      subtitle: 'Есть ли у тебя аллергия на продукты?',
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildChoiceChip('Нет', !_userData['hasAllergies'], () {
                                setState(() => _userData['hasAllergies'] = false);
                                _hasChanges = true;
                              }),
                              _buildChoiceChip('Да', _userData['hasAllergies'], () {
                                setState(() => _userData['hasAllergies'] = true);
                                _hasChanges = true;
                              }),
                            ],
                          ),
                          if (_userData['hasAllergies'])
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: TextField(
                                controller: _allergiesController,
                                decoration: const InputDecoration(hintText: 'Например: орехи, лактоза', border: OutlineInputBorder()),
                                onChanged: (val) {
                                  _userData['allergies'] = val;
                                  _hasChanges = true;
                                },
                              ),
                            )
                        ],
                      ),
                    ),
                    _buildStep(
                      title: 'Заболевания',
                      subtitle: 'Есть ли особенности по здоровью?',
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildChoiceChip('Нет', !_userData['hasDiseases'], () {
                                setState(() => _userData['hasDiseases'] = false);
                                _hasChanges = true;
                              }),
                              _buildChoiceChip('Да', _userData['hasDiseases'], () {
                                setState(() => _userData['hasDiseases'] = true);
                                _hasChanges = true;
                              }),
                            ],
                          ),
                          if (_userData['hasDiseases'])
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: TextField(
                                controller: _diseasesController,
                                decoration: const InputDecoration(hintText: 'Например: диабет 2 типа', border: OutlineInputBorder()),
                                onChanged: (val) {
                                  _userData['diseases'] = val;
                                  _hasChanges = true;
                                },
                              ),
                            )
                        ],
                      ),
                    ),
                    _buildStep(
                      title: 'Цель',
                      subtitle: 'Чего ты хочешь достичь?',
                      child: Column(
                        children: ['Похудеть', 'Поддерживать форму', 'Набрать массу'].map((goal) {
                          return RadioListTile<String>(
                            title: Text(goal, style: const TextStyle(fontSize: 18)),
                            value: goal,
                            groupValue: _userData['goal'],
                            activeColor: Colors.green,
                            onChanged: (val) {
                              setState(() => _userData['goal'] = val);
                              _hasChanges = true;
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _nextPage,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _currentPage == 4 ? 'Сохранить' : 'Далее',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({required String title, required String subtitle, required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller, Function(String) onChanged) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 18, color: isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}