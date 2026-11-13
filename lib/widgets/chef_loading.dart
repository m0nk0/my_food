import 'dart:async';
import 'package:flutter/material.dart';

class ChefLoading extends StatefulWidget {
  final String mealType;
  const ChefLoading({super.key, required this.mealType});

  @override
  State<ChefLoading> createState() => _ChefLoadingState();
}

class _ChefLoadingState extends State<ChefLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;
  int _currentStep = 0;

  final List<String> _steps = [
    'Изучаем твои цели...',
    'Считаем остаток калорий...',
    'Подбираем простые продукты...',
    'Готовим рецепты...',
  ];

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentStep = (_currentStep + 1) % _steps.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Анимация иконки повара
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: (_controller.value - 0.5) * 0.2,
                child: const Icon(Icons.soup_kitchen, size: 100, color: Colors.green),
              );
            },
          ),
          const SizedBox(height: 32),
          
          // Сменяющийся текст
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _steps[_currentStep],
              key: ValueKey<int>(_currentStep),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Шеф-повар уже у плиты...', style: TextStyle(fontSize: 16, color: Colors.grey)),
          
          const SizedBox(height: 50),
          
          // Иконки блюд (по центру и крупные)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDishIcon(Icons.breakfast_dining, 'Завтрак', widget.mealType == 'завтрак'),
              _buildDishIcon(Icons.lunch_dining, 'Обед', widget.mealType == 'обед'),
              _buildDishIcon(Icons.dinner_dining, 'Ужин', widget.mealType == 'ужин'),
              _buildDishIcon(Icons.cookie, 'Перекус', widget.mealType == 'перекус'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDishIcon(IconData icon, String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48, // Увеличили размер
            color: isActive ? Colors.green : Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14, // Увеличили шрифт
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.green : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}