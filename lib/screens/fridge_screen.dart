import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/fridge_provider.dart';
import '../providers/diary_provider.dart';
import '../services/calculator_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FridgeScreen extends StatefulWidget {
  const FridgeScreen({super.key});

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(FridgeProvider provider) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      provider.scanFridge(File(image.path));
    }
  }

  Future<void> _generate(FridgeProvider provider) async {
    final diary = Provider.of<DiaryProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    
    final dailyCalories = await CalculatorService.getDailyCalories();
    final allergies = prefs.getString('userAllergies') ?? '';
    final goal = prefs.getString('userGoal') ?? 'Поддерживать форму';
    
    final remaining = (dailyCalories - diary.totalCalories).clamp(0.0, 5000.0);

    provider.generateRecipes(
      remainingCalories: remaining,
      allergies: allergies,
      goal: goal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FridgeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Холодильник', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(FridgeProvider provider) {
    // 1. Загрузка (сканирование)
    if (provider.isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Смотрим, что в холодильнике...', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    // 2. Генерация рецептов
    if (provider.isGenerating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Шеф-повар думает...', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    // 3. Показ рецептов
    if (provider.recipes != null) {
      return SafeArea(
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
                    data: provider.recipes!,
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => provider.reset(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Вернуться к продуктам', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Если продукты уже распознаны (список)
    if (provider.products.isNotEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.pickedFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(provider.pickedFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 24),
              const Text('Что мы нашли:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                                        children: provider.products.map((product) {
                      return InputChip(
                        label: Text(product, style: const TextStyle(fontSize: 16)),
                        onPressed: () {
                          // Открываем диалог редактирования
                          _showEditProductDialog(provider, product);
                        },
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => provider.removeProduct(product),
                        backgroundColor: Colors.green.shade50,
                        side: BorderSide(color: Colors.green.shade200),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Кнопка добавить продукт вручную
              TextButton.icon(
                onPressed: () {
                  _showAddProductDialog(provider);
                },
                icon: const Icon(Icons.add),
                label: const Text('Добавить продукт'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => _generate(provider),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Придумать рецепты', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 5. Начальный экран (камера)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ),
            const Icon(Icons.kitchen, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text('Что у нас в холодильнике?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Сфотографируйте полку или стол с продуктами', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _pickImage(provider),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Сделать фото', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog(FridgeProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Добавить продукт'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Название продукта'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            FilledButton(
              onPressed: () {
                provider.addProduct(controller.text.trim());
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(FridgeProvider provider, String oldProduct) {
    final controller = TextEditingController(text: oldProduct);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Редактировать продукт'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Название продукта'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            FilledButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  provider.removeProduct(oldProduct);
                  provider.addProduct(newName);
                }
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