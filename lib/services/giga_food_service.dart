import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class GigaFoodService {
  static const String _authUrl = 'https://ngw.devices.sberbank.ru:9443/api/v2/oauth';
  static const String _apiUrl = 'https://gigachat.devices.sberbank.ru/api/v1/chat/completions';
  static const String _filesUrl = 'https://gigachat.devices.sberbank.ru/api/v1/files';

  String? _accessToken;

  final HttpClient _httpClient = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;

  Future<String> _getAccessToken() async {
    if (_accessToken != null) return _accessToken!;
    final request = await _httpClient.postUrl(Uri.parse(_authUrl));
    request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
    request.headers.set('Accept', 'application/json');
    request.headers.set('RqUID', '123e4567-e89b-12d3-a456-426614174000');
    request.headers.set('Authorization', 'Basic ${AppConfig.gigaApiKey}');
    request.add(utf8.encode('scope=GIGACHAT_API_PERS'));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      _accessToken = jsonDecode(responseBody)['access_token'];
      return _accessToken!;
    }
    throw Exception('Auth error: ${response.statusCode} - $responseBody');
  }

  Future<String> _uploadImage(File imageFile, String token) async {
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: 800,
      minHeight: 800,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    if (compressedBytes == null) throw Exception('Не удалось сжать изображение');

    final boundary = '----GigaChatBoundary${DateTime.now().millisecondsSinceEpoch}';
    final request = await _httpClient.postUrl(Uri.parse(_filesUrl));
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Content-Type', 'multipart/form-data; boundary=$boundary');

    final body = <int>[];
    body.addAll(utf8.encode('--$boundary\r\n'));
    body.addAll(utf8.encode('Content-Disposition: form-data; name="purpose"\r\n\r\n'));
    body.addAll(utf8.encode('general\r\n'));
    body.addAll(utf8.encode('--$boundary\r\n'));
    body.addAll(utf8.encode('Content-Disposition: form-data; name="file"; filename="food.jpg"\r\n'));
    body.addAll(utf8.encode('Content-Type: image/jpeg\r\n\r\n'));
    body.addAll(compressedBytes);
    body.addAll(utf8.encode('\r\n--$boundary--\r\n'));

    request.add(body);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      return jsonDecode(responseBody)['id'];
    }
    throw Exception('Upload error: ${response.statusCode} - $responseBody');
  }

  Future<Map<String, dynamic>> analyzeFood(File imageFile) async {
    try {
      final token = await _getAccessToken();
      final fileId = await _uploadImage(imageFile, token);

      final prefs = await SharedPreferences.getInstance();
      final hasAllergies = prefs.getBool('userHasAllergies') ?? false;
      final allergies = prefs.getString('userAllergies') ?? '';
      final hasDiseases = prefs.getBool('userHasDiseases') ?? false;
      final diseases = prefs.getString('userDiseases') ?? '';
      final goal = prefs.getString('userGoal') ?? 'Поддерживать форму';

      String healthContext = '';
      if (hasAllergies && allergies.isNotEmpty) {
        healthContext += 'ВАЖНО: У пользователя аллергия на: $allergies. ';
      }
      if (hasDiseases && diseases.isNotEmpty) {
        healthContext += 'ВАЖНО: У пользователя есть заболевания: $diseases. ';
      }

      final requestBody = {
        'model': 'GigaChat-2-Pro', 
        'messages': [
          {
            'role': 'system',
            'content': '''
Ты — умный нутрициолог. Проанализируй фото.
$healthContext
Цель пользователя: $goal.

Верни ответ СТРОГО в формате JSON.
ОЧЕНЬ ВАЖНО: Оцени свою уверенность в распознавании от 0 до 100 и верни в поле "confidence". Если ты не уверен, что это за блюдо, или видишь только часть упаковки, ставь низкую уверенность (меньше 60).

Формат JSON:
{
  "dish_name": "Название блюда",
  "weight_g": 150,
  "calories": 100,
  "protein": 2.0,
  "fat": 0.5,
  "carbs": 25.0,
  "description": "Краткая справка.",
  "benefits": "Польза.",
  "warnings": "Аллергены.",
  "warning": "КРИТИЧЕСКОЕ ПРЕДУПРЕЖДЕНИЕ (если аллергия).",
  "confidence": 85
}
'''
          },
          {
            'role': 'user',
            'content': 'Что это за еда?',
            'attachments': [fileId]
          }
        ]
      };

      final request = await _httpClient.postUrl(Uri.parse(_apiUrl));
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');
      request.add(utf8.encode(jsonEncode(requestBody)));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final content = jsonDecode(responseBody)['choices'][0]['message']['content'] as String;
        String cleanContent = content.replaceAll('```json', '').replaceAll('```', '').trim();
        
        try {
          return jsonDecode(cleanContent);
        } catch (e) {
          // Если модель снова ответила текстом, возвращаем заглушку с низкой уверенностью
          return {
            'dish_name': 'Неизвестное блюдо',
            'weight_g': 100,
            'calories': 0,
            'protein': 0.0,
            'fat': 0.0,
            'carbs': 0.0,
            'description': cleanContent,
            'benefits': 'Нет данных',
            'warnings': 'Нет данных',
            'warning': '',
            'confidence': 0, // Низкая уверенность
          };
        }
      }
      throw Exception('API error: ${response.statusCode} - $responseBody');
    } catch (e) {
      throw Exception('Ошибка при анализе фото: $e');
    }
  }
}