import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class FoodRecognitionService {
  static const String _apiKey = 'TU_API_KEY'; // Reemplazar con tu API key
  static const String _apiUrl = 'https://api.nutritionix.com/v1_1/item';

  static Future<Map<String, dynamic>> recognizeFood(File imageFile) async {
    try {
      // 1. Temporalmente comentado para evitar problemas de compilación
      // final textRecognizer = TextRecognizer();
      // final inputImage = InputImage.fromFile(imageFile);
      // final recognizedText = await textRecognizer.processImage(inputImage);
      
      // 2. Por ahora, usamos un texto de ejemplo
      final recognizedText = "manzana"; // Texto temporal
      
      // 3. Enviamos el texto reconocido a la API de Nutritionix
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-app-id': _apiKey,
          'x-app-key': 'TU_APP_KEY', // Reemplazar con tu app key
        },
        body: jsonEncode({
          'query': recognizedText,
          'timezone': 'US/Eastern',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al reconocer el alimento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al procesar la imagen: $e');
    }
  }

  static Future<Map<String, dynamic>> getNutritionInfo(String foodName) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-app-id': _apiKey,
          'x-app-key': 'TU_APP_KEY',
        },
        body: jsonEncode({
          'query': foodName,
          'timezone': 'US/Eastern',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener información nutricional: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al procesar la solicitud: $e');
    }
  }
} 