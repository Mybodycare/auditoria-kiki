import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class TranslationService {
  static final Logger _logger = Logger('TranslationService');
  static final Map<String, String> _cache = {};
  
  /// Traduce un texto del español al inglés con timeout y caché
  static Future<String> traducirAlIngles(String texto) async {
    if (texto.isEmpty) return texto;
    
    // Normalizar el texto: eliminar espacios extras y trim
    final textoNormalizado = texto.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Verificar caché primero
    if (_cache.containsKey(textoNormalizado)) {
      _logger.info('Traducción encontrada en caché: "$textoNormalizado" -> "${_cache[textoNormalizado]}"');
      return _cache[textoNormalizado]!;
    }
    
    try {
      // Usar timeout para evitar esperas indefinidas
      final response = await http.post(
        Uri.parse("https://libretranslate.de/translate"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "q": textoNormalizado,
          "source": "es",
          "target": "en",
          "format": "text"
        }),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _logger.warning('Timeout al traducir: "$textoNormalizado"');
          return http.Response('{"error": "timeout"}', 408);
        },
      );
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final traduccion = data['translatedText'] as String?;
          
          if (traduccion != null && traduccion.isNotEmpty) {
            _logger.info('Texto completo traducido: "$textoNormalizado" -> "$traduccion"');
            
            // Guardar en caché
            _cache[textoNormalizado] = traduccion;
            
            return traduccion;
          }
        } catch (e) {
          _logger.warning('Error al procesar respuesta de traducción: $e');
        }
      }
      
      _logger.warning('Error al traducir: ${response.statusCode} - ${response.body}');
      
      // Plan B: Implementar traducción de emergencia para frases comunes
      final emergencyTranslation = _getEmergencyTranslation(textoNormalizado);
      if (emergencyTranslation != textoNormalizado) {
        _cache[textoNormalizado] = emergencyTranslation;
        return emergencyTranslation;
      }
      
      return textoNormalizado;
    } catch (e) {
      _logger.severe('Excepción al traducir: $e');
      return textoNormalizado;
    }
  }
  
  /// Traducciones de emergencia para términos comunes
  static String _getEmergencyTranslation(String texto) {
    final lowercaseText = texto.toLowerCase();
    
    // Diccionario básico de traducciones de frases comunes
    const Map<String, String> commonPhrases = {
      'recetas de': 'recipes with',
      'comida': 'food',
      'desayuno': 'breakfast',
      'almuerzo': 'lunch',
      'cena': 'dinner',
      'sin gluten': 'gluten free',
      'vegetariano': 'vegetarian',
      'vegano': 'vegan',
      'bajo en calorías': 'low calorie',
      'saludable': 'healthy',
      'rápido': 'quick',
      'fácil': 'easy',
      'postre': 'dessert',
      'sopa': 'soup',
      'ensalada': 'salad',
      'con': 'with',
      'sin': 'without',
      'y': 'and',
    };
    
    String translatedText = lowercaseText;
    
    // Primero intentar traducir frases completas
    for (final entry in commonPhrases.entries) {
      translatedText = translatedText.replaceAll(entry.key, entry.value);
    }
    
    // Si no se encontró una traducción de frase, usar el diccionario de alimentos
    if (translatedText == lowercaseText) {
      return _translateFoodItems(texto);
    }
    
    return translatedText;
  }
  
  /// Traduce elementos individuales de comida
  static String _translateFoodItems(String texto) {
    final lowercaseText = texto.toLowerCase();
    
    // Diccionario básico de traducciones de alimentos
    const Map<String, String> basicFoodDictionary = {
      'arroz': 'rice',
      'pan': 'bread',
      'leche': 'milk',
      'queso': 'cheese',
      'pollo': 'chicken',
      'carne': 'meat',
      'pescado': 'fish',
      'huevo': 'egg',
      'huevos': 'eggs',
      'manzana': 'apple',
      'naranja': 'orange',
      'plátano': 'banana',
      'banana': 'banana',
      'fresa': 'strawberry',
      'fresas': 'strawberries',
      'tomate': 'tomato',
      'lechuga': 'lettuce',
      'zanahoria': 'carrot',
      'patata': 'potato',
      'papa': 'potato',
      'cebolla': 'onion',
      'ajo': 'garlic',
      'pasta': 'pasta',
      'macarrones': 'macaroni',
      'espagueti': 'spaghetti',
      'fideos': 'noodles',
      'sopa': 'soup',
      'ensalada': 'salad',
      'pizza': 'pizza',
      'hamburguesa': 'hamburger',
      'sandwich': 'sandwich',
      'agua': 'water',
      'café': 'coffee',
      'té': 'tea',
      'azúcar': 'sugar',
      'sal': 'salt',
      'pimienta': 'pepper',
      'aceite': 'oil',
      'vinagre': 'vinegar',
      'mantequilla': 'butter',
      'salsa': 'sauce',
      'chocolate': 'chocolate',
      'helado': 'ice cream',
      'galleta': 'cookie',
      'galletas': 'cookies',
      'pastel': 'cake',
      'torta': 'cake',
      'frijoles': 'beans',
      'judías': 'beans',
      'lentejas': 'lentils',
      'garbanzos': 'chickpeas',
      'maíz': 'corn',
      'avena': 'oatmeal',
    };
    
    String translatedText = lowercaseText;
    
    // Traducir cada palabra individualmente
    for (final entry in basicFoodDictionary.entries) {
      translatedText = translatedText.replaceAll(entry.key, entry.value);
    }
    
    return translatedText;
  }
} 