import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../services/translation_service.dart';

class RecipeSearchService {
  static const String _spoonacularBaseUrl = 'https://api.spoonacular.com/recipes';
  static const String spoonacularApiKey = 'e4cf0d1a56dc4c648922126f983b3c3a';
  static const String _usdaBaseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static const String usdaApiKey = 'YqJUtsyvFPBC0uB8Rgd2ymyupEHdmQiMYtHw9riP';
  
  static final Logger _logger = Logger('RecipeSearchService');

  // Método para obtener sugerencias de autocompletado
  static Future<List<String>> getAutocompleteSuggestions(String query) async {
    if (query.length < 2) return [];
    
    try {
      // Traducir la consulta al inglés para mejores resultados
      final englishQuery = await TranslationService.traducirAlIngles(query);
      
      final response = await http.get(
        Uri.parse('$_spoonacularBaseUrl/autocomplete?query=$englishQuery&number=5&apiKey=$spoonacularApiKey'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _logger.warning('Timeout al obtener sugerencias');
          return http.Response('[]', 408);
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _logger.info('Sugerencias obtenidas exitosamente: ${data.length} resultados');
        return data.map((item) => item['title'].toString()).toList();
      } else {
        _logger.warning('Error al obtener sugerencias: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.severe('Error al obtener sugerencias: $e');
      return [];
    }
  }

  // Método para buscar recetas
  static Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    try {
      List<Map<String, dynamic>> results = [];

      // Traducir la consulta al inglés para mejores resultados
      String englishQuery;
      try {
        englishQuery = await TranslationService.traducirAlIngles(query)
            .timeout(const Duration(seconds: 3));
        _logger.info('Consulta traducida: "$query" -> "$englishQuery"');
      } catch (e) {
        _logger.warning('Error al traducir, usando consulta original: $e');
        englishQuery = query; // Usar la consulta original si hay error
      }

      // Buscar en Spoonacular
      bool spoonacularSuccess = false;
      try {
        final spoonacularResponse = await http.get(
          Uri.parse('$_spoonacularBaseUrl/complexSearch?query=$englishQuery&number=5&apiKey=$spoonacularApiKey&addRecipeInformation=true&fillIngredients=true&sort=popularity'),
        ).timeout(const Duration(seconds: 8));

        if (spoonacularResponse.statusCode == 200) {
          final spoonacularData = json.decode(spoonacularResponse.body);
          final recipes = spoonacularData['results'] as List? ?? [];
          
          results.addAll(recipes.map((recipe) => {
            'id': recipe['id'],
            'title': recipe['title'] ?? 'Sin título',
            'image': recipe['image'],
            'readyInMinutes': recipe['readyInMinutes'],
            'source': 'spoonacular',
            'type': 'recipe',
          }));
          
          spoonacularSuccess = recipes.isNotEmpty;
        }
      } catch (e) {
        _logger.warning('Error al buscar en Spoonacular: $e');
      }

      // Intentar con la consulta original si la traducida no dio resultados
      if (!spoonacularSuccess && englishQuery != query) {
        try {
          _logger.info('Reintentando búsqueda con consulta original: "$query"');
          final spoonacularResponse = await http.get(
            Uri.parse('$_spoonacularBaseUrl/complexSearch?query=${Uri.encodeComponent(query)}&number=5&apiKey=$spoonacularApiKey&addRecipeInformation=true&fillIngredients=true&sort=popularity'),
          ).timeout(const Duration(seconds: 8));

          if (spoonacularResponse.statusCode == 200) {
            final spoonacularData = json.decode(spoonacularResponse.body);
            final recipes = spoonacularData['results'] as List? ?? [];
            
            results.addAll(recipes.map((recipe) => {
              'id': recipe['id'],
              'title': recipe['title'] ?? 'Sin título',
              'image': recipe['image'],
              'readyInMinutes': recipe['readyInMinutes'],
              'source': 'spoonacular',
              'type': 'recipe',
            }));
          }
        } catch (e) {
          _logger.warning('Error al reintentar con consulta original: $e');
        }
      }

      // Buscar en USDA solo si no tenemos suficientes resultados
      if (results.length < 3) {
        try {
          final usdaResponse = await http.get(
            Uri.parse('$_usdaBaseUrl/foods/search?query=$englishQuery&api_key=$usdaApiKey&pageSize=5'),
          ).timeout(const Duration(seconds: 8));

          if (usdaResponse.statusCode == 200) {
            final usdaData = json.decode(usdaResponse.body);
            final foods = usdaData['foods'] as List? ?? [];
            
            for (var food in foods) {
              try {
                final id = food['fdcId']?.toString();
                if (id == null) continue;
                
                final nutrients = food['foodNutrients'] as List? ?? [];
                final processedNutrients = nutrients
                    .where((n) => n['nutrientName'] != null && n['value'] != null)
                    .map((nutrient) => {
                      'name': nutrient['nutrientName'] ?? '',
                      'amount': nutrient['value'] ?? 0,
                      'unit': nutrient['unitName'] ?? '',
                    })
                    .toList();
                
                results.add({
                  'id': id,
                  'title': food['description'] ?? 'Sin descripción',
                  'image': null, // USDA no proporciona imágenes
                  'readyInMinutes': null,
                  'source': 'usda',
                  'type': 'food',
                  'nutrients': processedNutrients,
                });
              } catch (e) {
                _logger.warning('Error al procesar alimento de USDA: $e');
              }
            }
          }
        } catch (e) {
          _logger.warning('Error al buscar en USDA: $e');
        }
      }

      _logger.info('Búsqueda completada: ${results.length} resultados');
      return results;
    } catch (e) {
      _logger.severe('Error al buscar recetas: $e');
      throw Exception('Error al buscar recetas: $e');
    }
  }

  // Método para obtener detalles de una receta
  static Future<Map<String, dynamic>> getRecipeDetails(dynamic recipeId, String source) async {
    try {
      if (source == 'spoonacular') {
        final response = await http.get(
          Uri.parse('$_spoonacularBaseUrl/$recipeId/information?apiKey=$spoonacularApiKey&includeNutrition=true'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _logger.info('Detalles de receta obtenidos exitosamente');
          return {
            'title': data['title'],
            'image': data['image'],
            'readyInMinutes': data['readyInMinutes'],
            'servings': data['servings'],
            'instructions': data['instructions'],
            'ingredients': data['extendedIngredients']?.map((ingredient) => {
              'name': ingredient['name'],
              'amount': ingredient['amount'],
              'unit': ingredient['unit'],
            }).toList(),
            'nutrition': data['nutrition']?['nutrients']?.map((nutrient) => {
              'name': nutrient['name'],
              'amount': nutrient['amount'],
              'unit': nutrient['unit'],
            }).toList(),
          };
        } else {
          throw Exception('Error al obtener detalles de la receta: ${response.statusCode}');
        }
      } else if (source == 'usda') {
        final response = await http.get(
          Uri.parse('$_usdaBaseUrl/food/$recipeId?api_key=$usdaApiKey'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _logger.info('Detalles de alimento obtenidos exitosamente');
          
          // Extraer información nutricional más detallada
          final nutrients = data['foodNutrients'] as List? ?? [];
          final processedNutrients = nutrients
              .where((n) => n['nutrientName'] != null && n['value'] != null)
              .map((nutrient) => {
                'name': nutrient['nutrientName'] ?? '',
                'amount': nutrient['value'] ?? 0,
                'unit': nutrient['unitName'] ?? '',
              })
              .toList();
          
          // Calcular calorías totales
          final calories = _extractNutrientValue(processedNutrients, 'Energy');
          
          return {
            'title': data['description'],
            'image': null,
            'readyInMinutes': null,
            'servings': 1,
            'instructions': null,
            'ingredients': null,
            'calories': calories,
            'nutrition': processedNutrients,
          };
        } else {
          throw Exception('Error al obtener detalles del alimento: ${response.statusCode}');
        }
      } else {
        throw Exception('Fuente de datos no válida');
      }
    } catch (e) {
      _logger.severe('Error al obtener detalles: $e');
      throw Exception('Error al obtener detalles: $e');
    }
  }
  
  // Utilidad para extraer un valor nutricional por nombre
  static double _extractNutrientValue(List<Map<String, dynamic>> nutrients, String namePattern) {
    final matches = nutrients.where((n) => 
        (n['name'] as String).toLowerCase().contains(namePattern.toLowerCase()));
    
    if (matches.isNotEmpty) {
      final value = matches.first['amount'];
      return value is num ? value.toDouble() : 0.0;
    }
    return 0.0;
  }

  Future<Map<String, dynamic>> getNutritionInfo(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_spoonacularBaseUrl/$id/nutritionWidget.json?apiKey=$spoonacularApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.info('Información nutricional obtenida para receta ID: $id');
        return data;
      } else {
        _logger.warning('Error en nutrición: ${response.statusCode} - ${response.body}');
        throw Exception('Error al obtener información nutricional: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Excepción en nutrición: $e');
      throw Exception('Error al conectar con la API: $e');
    }
  }
} 