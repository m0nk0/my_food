import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:provider/provider.dart';
import '../providers/food_analysis_provider.dart';
import '../providers/diary_provider.dart';
import '../widgets/scanning_overlay.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FoodAnalysisProvider>(context);
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);

    // 1. ЭКРАН СКАНИРОВАНИЯ
    if (provider.isLoading && provider.pickedFile != null) {
      return Scaffold(
        body: ScanningOverlay(imagePath: provider.pickedFile!.path),
      );
    }

    // 2. ЭКРАН РЕЗУЛЬТАТА
    if (provider.apiResponse != null && !provider.isLoading) {
      final data = provider.apiResponse!;
      
      final dishName = data['dish_name'] ?? data['блюдо'] ?? 'Без названия';
      final weight = (data['weight_g'] ?? data['вес'] ?? 100).toDouble();
      
      // КБЖУ на 100г
      final cal100 = (data['calories_per_100g'] ?? data['calories'] ?? 0).toDouble();
      final prot100 = (data['protein_per_100g'] ?? data['protein'] ?? 0).toDouble();
      final fat100 = (data['fat_per_100g'] ?? data['fat'] ?? 0).toDouble();
      final carb100 = (data['carbs_per_100g'] ?? data['carbs'] ?? 0).toDouble();

      // Пересчитываем на текущий вес
      final ratio = weight / 100.0;
      final calories = cal100 * ratio;
      final protein = prot100 * ratio;
      final fat = fat100 * ratio;
      final carbs = carb100 * ratio;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Анализ блюда'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => provider.reset(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (provider.pickedFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: FutureBuilder<File>(
                      future: FlutterExifRotation.rotateImage(path: provider.pickedFile!.path),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return Image.file(provider.pickedFile!, fit: BoxFit.cover);
                        }
                        return Image.file(snapshot.data!, fit: BoxFit.cover);
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dishName.toString(),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      
                      // КЛИКАБЕЛЬНЫЙ ВЕС
                      GestureDetector(
                        onTap: () {
                          _showWeightEditDialog(context, weight, cal100, prot100, fat100, carb100);
                        },
                        child: Row(
                          children: [
                            Text(
                              'Вес: ${weight.toStringAsFixed(0)} г',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.edit, size: 24, color: Colors.green),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // СТРОКА ПРО 100 ГРАММ (Крупнее и с выделением)
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 15, color: Colors.black54),
                          children: [
                            const TextSpan(
                              text: 'На 100 г: ',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            TextSpan(
                              text: '${cal100.toStringAsFixed(0)} ккал | Б:${prot100.toStringAsFixed(1)} Ж:${fat100.toStringAsFixed(1)} У:${carb100.toStringAsFixed(1)}',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 32),
                      
                      // ИТОГОВЫЕ КБЖУ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildNutrient('Ккал', calories, Colors.green),
                          _buildNutrient('Белки', protein, Colors.red),
                          _buildNutrient('Жиры', fat, Colors.orange),
                          _buildNutrient('Углев.', carbs, Colors.blue),
                        ],
                      ),
                      
                      const Divider(height: 32),

                      if (data['warning'] != null && data['warning'].toString().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['warning'],
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showInfoBottomSheet(context, dishName, data['description'] ?? '', data['benefits'] ?? '', data['warnings'] ?? '');
                          },
                          icon: const Icon(Icons.menu_book, color: Colors.green),
                          label: const Text('Узнать больше о продукте', style: TextStyle(color: Colors.green, fontSize: 16)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await diaryProvider.addEntry(
                              name: dishName.toString(),
                              weight: weight,
                              calories: calories,
                              protein: protein,
                              fat: fat,
                              carbs: carbs,
                              imagePath: provider.pickedFile?.path,
                            );
                            
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Добавлено в дневник!')),
                              );
                            }
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Добавить в дневник', style: TextStyle(fontSize: 16)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => provider.reset(),
                child: const Text('Отменить и вернуться', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            ],
          ),
        ),
      );
    }

    // 3. ЭКРАН ВЫБОРА ФОТО
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Добавить еду', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const Text(
                'Сделать фото',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'ИИ определит блюдо и посчитает КБЖУ',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              
              const SizedBox(height: 40),
              
              GestureDetector(
                onTap: () => provider.pickAndAnalyzeImageFromCamera(),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              TextButton.icon(
                onPressed: () => _showManualInputDialog(context, provider),
                icon: const Icon(Icons.edit, color: Colors.grey, size: 24),
                label: const Text(
                  'Ввести вручную',
                  style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrient(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _showWeightEditDialog(BuildContext context, double currentWeight, double cal100, double prot100, double fat100, double carb100) {
    final weightController = TextEditingController(text: currentWeight.toStringAsFixed(0));
    final provider = Provider.of<FoodAnalysisProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Изменить вес', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Вес (г)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () {
                final newWeight = double.tryParse(weightController.text) ?? currentWeight;
                
                final newData = Map<String, dynamic>.from(provider.apiResponse!);
                newData['weight_g'] = newWeight;
                newData['calories_per_100g'] = cal100;
                newData['protein_per_100g'] = prot100;
                newData['fat_per_100g'] = fat100;
                newData['carbs_per_100g'] = carb100;
                
                provider.updateResponse(newData);
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

  void _showManualInputDialog(BuildContext context, FoodAnalysisProvider provider) {
    final nameController = TextEditingController();
    final weightController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ручной ввод', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Введите название блюда, и ИИ посчитает КБЖУ.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Название блюда',
                  hintText: 'Например: Борщ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Вес (г) - опционально',
                  hintText: 'Оставьте пустым, если не знаете',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final weight = double.tryParse(weightController.text);
                    
                    Navigator.pop(context);
                    provider.analyzeManualInput(name, weight);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Узнать КБЖУ', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showInfoBottomSheet(BuildContext context, String title, String description, String benefits, String warnings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Описание', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 20),
                  const Text('Польза', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 8),
                  Text(benefits, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 20),
                  const Text('Предостережения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 8),
                  Text(warnings, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }
}