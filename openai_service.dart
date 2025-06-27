import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  final String apiKey = ApiKeys.openAiKey;
  final String baseUrl = 'https://api.openai.com/v1';

  Future<String> getFoodSuggestions(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': 'Eres un experto nutricionista. Proporciona sugerencias de alimentos saludables y nutritivos.',
            },
            {
              'role': 'user',
              'content': query,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 150,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Error en la llamada a OpenAI: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al conectar con OpenAI: $e');
    }
  }

  Future<Map<String, dynamic>> analizarImagen(String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-vision-preview',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Analiza esta imagen y proporciona una lista de ingredientes y sus propiedades nutricionales.',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': imageUrl,
                  },
                },
              ],
            },
          ],
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Error al analizar la imagen: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al conectar con OpenAI: $e');
    }
  }
} 