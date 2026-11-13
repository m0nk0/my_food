import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:provider/provider.dart';
import '../providers/food_analysis_provider.dart';
import '../providers/diary_provider.dart';

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

    // Экран результата (когда анализ завершен)
    if (provider.apiResponse != null && !provider.isLoading) {
      final data = provider.apiResponse!;
      
      final dishName = data['dish_name'] ?? data['блюдо'] ?? 'Без названия';
      final weight = (data['weight_g'] ?? data['вес'] ?? 100).toDouble();
      final calories = (data['calories'] ?? 0).toDouble();
      final protein = (data['protein'] ?? 0).toDouble();
      final fat = (data['fat'] ?? 0).toDouble();
      final carbs = (data['carbs'] ?? 0).toDouble();
      
      final description = data['description'] ?? 'Нет описания';
      final benefits = data['benefits'] ?? 'Нет данных';
      final warnings = data['warnings'] ?? 'Нет данных';
      final criticalWarning = data['warning'] ?? '';
      final confidence = (data['confidence'] ?? 100).toDouble();

      return Scaffold(
        appBar: AppBar(title: const Text('Анализ блюда')),
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
                      // ИСПРАВЛЕНО: file: -> path:
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
                      Text('Вес: ${weight.toStringAsFixed(0)} г', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      
                      const Divider(height: 32),
                      
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

                      // ОРАНЖЕВОЕ ПРЕДУПРЕЖДЕНИЕ (Низкая уверенность)
                      if (confidence < 60) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.help_outline, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ИИ не уверен в этом блюде. Проверьте название и вес, при необходимости отредактируйте.',
                                  style: TextStyle(color: Colors.orange.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // КРАСНОЕ ПРЕДУПРЕЖДЕНИЕ (Аллергии)
                      if (criticalWarning.isNotEmpty) ...[
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
                                  criticalWarning,
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
                            _showInfoBottomSheet(context, dishName, description, benefits, warnings);
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
                child: const Text('Выбрать другое фото', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    // Экран выбора фото (камера или галерея)
    return Scaffold(
      appBar: AppBar(title: const Text('Камера')),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 100, 
          child: Center(
            child: provider.isLoading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('Анализируем фото...', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (provider.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            provider.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      
                      Icon(Icons.camera_alt, size: 80, color: Colors.green.shade200),
                      const SizedBox(height: 20),
                      
                      ElevatedButton.icon(
                        onPressed: () => provider.pickAndAnalyzeImageFromCamera(),
                        icon: const Icon(Icons.camera),
                        label: const Text('Сделать фото', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      OutlinedButton.icon(
                        onPressed: () => provider.pickAndAnalyzeImageFromGallery(),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Выбрать из галереи', style: TextStyle(fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
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