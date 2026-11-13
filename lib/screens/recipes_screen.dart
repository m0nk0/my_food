import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/diary_provider.dart';
import '../services/giga_food_service.dart';
import '../services/calculator_service.dart';
import '../widgets/chef_loading.dart';

class RecipesScreen extends StatefulWidget {
  final String mealType;
  const RecipesScreen({super.key, required this.mealType});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final GigaFoodService _service = GigaFoodService();
  String? _recipes;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateRecipes();
  }

  Future<void> _generateRecipes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final diary = Provider.of<DiaryProvider>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      
      final dailyCalories = await CalculatorService.getDailyCalories();
      final allergies = prefs.getString('userAllergies') ?? '';
      final goal = prefs.getString('userGoal') ?? 'Поддерживать форму';
      
      final remaining = (dailyCalories - diary.totalCalories).clamp(0.0, 5000.0);

      final result = await _service.generateRecipesByTime(
        remainingCalories: remaining,
        mealType: widget.mealType,
        allergies: allergies,
        goal: goal,
      );

      setState(() {
        _recipes = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Рецепты на ${widget.mealType}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? ChefLoading(mealType: widget.mealType)
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: MarkdownBody(
                              data: _recipes ?? '',
                              styleSheet: MarkdownStyleSheet(
                                h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                                h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                                h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                p: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                                listBullet: const TextStyle(fontSize: 16, height: 1.5),
                                strong: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24), // Отступ между карточкой и кнопкой
                        
                        // Кнопка теперь внизу страницы, а не поверх текста
                        if (_recipes != null)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: _generateRecipes,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Другие рецепты', style: TextStyle(fontSize: 16)),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24), // Отступ снизу
                      ],
                    ),
                  ),
                ),
    );
  }
}