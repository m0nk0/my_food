import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/giga_food_service.dart';

class FoodAnalysisProvider extends ChangeNotifier {
  final GigaFoodService _service = GigaFoodService();
  final ImagePicker _picker = ImagePicker();

  File? pickedFile;
  Map<String, dynamic>? apiResponse;
  bool isLoading = false;
  String? errorMessage;

  Future<void> pickAndAnalyzeImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) await _processImage(File(image.path));
  }

  Future<void> pickAndAnalyzeImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );
    if (image != null) await _processImage(File(image.path));
  }

  Future<void> _processImage(File file) async {
    pickedFile = file;
    apiResponse = null;
    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      final result = await _service.analyzeFood(pickedFile!);
      apiResponse = result;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> analyzeManualInput(String dishName, double? weight) async {
    pickedFile = null;
    apiResponse = null;
    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      final result = await _service.analyzeFoodByName(dishName, weight: weight);
      apiResponse = result;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Обновляем данные (когда меняем вес)
  void updateResponse(Map<String, dynamic> newData) {
    apiResponse = newData;
    notifyListeners();
  }

  void reset() {
    pickedFile = null;
    apiResponse = null;
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }
}