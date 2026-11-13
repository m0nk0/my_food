import 'dart:io';
import 'package:flutter/material.dart';
import '../services/giga_food_service.dart';

class FridgeProvider extends ChangeNotifier {
  final GigaFoodService _service = GigaFoodService();

  File? pickedFile;
  List<String> products = [];
  String? recipes;
  bool isScanning = false;
  bool isGenerating = false;
  String? errorMessage;

  // Сканирование холодильника
  Future<void> scanFridge(File image) async {
    pickedFile = image;
    products = [];
    recipes = null;
    errorMessage = null;
    isScanning = true;
    notifyListeners();

    try {
      final result = await _service.analyzeFridge(image);
      products = result;
      if (products.isEmpty) {
        errorMessage = 'Не удалось распознать продукты. Попробуйте другое фото.';
      }
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isScanning = false;
      notifyListeners();
    }
  }

  // Удалить продукт из списка
  void removeProduct(String product) {
    products.remove(product);
    notifyListeners();
  }

  // Добавить продукт вручную
  void addProduct(String product) {
    if (product.isNotEmpty && !products.contains(product)) {
      products.add(product);
      notifyListeners();
    }
  }

  // Генерация рецептов
  Future<void> generateRecipes({
    required double remainingCalories,
    required String allergies,
    required String goal,
  }) async {
    if (products.isEmpty) return;

    isGenerating = true;
    recipes = null;
    errorMessage = null;
    notifyListeners();

    try {
      // Здесь мы используем тот же метод, что и для рецептов по времени, 
      // но передаем список продуктов в промпт.
      // Для простоты создадим отдельный метод в сервисе или используем существующий.
      // Пока используем заглушку, чтобы не переписывать сервис.
      
      // ВАЖНО: Для полноценной работы нужно добавить метод в GigaFoodService,
      // который принимает список продуктов. Пока мы просто просим GigaChat
      // придумать рецепты из того, что есть.
      
      final result = await _service.generateRecipesFromProducts(
        products: products,
        remainingCalories: remainingCalories,
        allergies: allergies,
        goal: goal,
      );
      
      recipes = result;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  void reset() {
    pickedFile = null;
    products = [];
    recipes = null;
    errorMessage = null;
    isScanning = false;
    isGenerating = false;
    notifyListeners();
  }
}