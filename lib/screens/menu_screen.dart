import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/giga_food_service.dart';
import '../providers/diary_provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final GigaFoodService _service = GigaFoodService();
  final ImagePicker _picker = ImagePicker();
  File? _pickedFile;
  List<Map<String, dynamic>>? _menuItems;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _pickedFile = File(image.path);
      _isLoading = true;
      _error = null;
      _menuItems = null;
    });

    try {
      final result = await _service.analyzeMenu(_pickedFile!);
      setState(() {
        _menuItems = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Вызываем диалог вместо прямого добавления
  void _addToDiary(BuildContext context, Map<String, dynamic> item, DiaryProvider diary) {
    showDialog(
      context: context,
      builder: (context) {
        final weightController = TextEditingController(text: '250'); // Дефолтный вес

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(item['dish_name_ru'] ?? 'Добавить блюдо', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Укажите вес порции (в граммах):', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Вес (г)',
                  border: OutlineInputBorder(),
                ),
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
                final weight = double.tryParse(weightController.text) ?? 250.0;
                
                // Пересчитываем КБЖУ пропорционально весу (относительно 250г)
                final ratio = weight / 250.0; 
                
                final calories = ((item['calories'] ?? 0) as num).toDouble() * ratio;
                final protein = ((item['protein'] ?? 0) as num).toDouble() * ratio;
                final fat = ((item['fat'] ?? 0) as num).toDouble() * ratio;
                final carbs = ((item['carbs'] ?? 0) as num).toDouble() * ratio;

                diary.addEntry(
                  name: item['dish_name_ru'] ?? 'Без названия',
                  weight: weight,
                  calories: calories,
                  protein: protein,
                  fat: fat,
                  carbs: carbs,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item['dish_name_ru']} добавлено в дневник!')),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final diary = Provider.of<DiaryProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Меню в кафе', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Читаем меню...', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : _menuItems == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                          ),
                        const Icon(Icons.restaurant_menu, size: 80, color: Colors.green),
                        const SizedBox(height: 20),
                        const Text('Сфотографируйте меню', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Мы переведем и посчитаем КБЖУ', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 40),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Сделать фото', style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Из галереи', style: TextStyle(fontSize: 16)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _menuItems!.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems![index];
                    final warning = item['warning'] ?? '';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['dish_name_ru'] ?? 'Без названия',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      if (item['dish_name_original'] != null)
                                        Text(
                                          item['dish_name_original'].toString(),
                                          style: const TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
                                        ),
                                    ],
                                  ),
                                ),
                                if (item['price'] != null)
                                  Text(
                                    item['price'].toString(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(item['description'] ?? '', style: const TextStyle(color: Colors.black87)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildNutrient('Ккал', (item['calories'] ?? 0).toDouble(), Colors.green),
                                _buildNutrient('Белки', (item['protein'] ?? 0).toDouble(), Colors.red),
                                _buildNutrient('Жиры', (item['fat'] ?? 0).toDouble(), Colors.orange),
                                _buildNutrient('Углев.', (item['carbs'] ?? 0).toDouble(), Colors.blue),
                              ],
                            ),
                            if (warning.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(warning, style: const TextStyle(color: Colors.red, fontSize: 12))),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _addToDiary(context, item, diary), // <--- ВЫЗОВ ДИАЛОГА
                                icon: const Icon(Icons.add),
                                label: const Text('Добавить в дневник'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildNutrient(String label, double value, Color color) {
    return Column(
      children: [
        Text(value.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}