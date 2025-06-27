import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _baseStoragePath = 'recetas';
  static const String _fallbackImageUrl = 'https://firebasestorage.googleapis.com/v0/b/mi-cuerpo-copia.appspot.com/o/recetas%2Fdefault_food.jpg?alt=media';

  // Obtener la URL completa de una imagen a partir del nombre o URL guardada en Firestore
  static String getFullImageUrl(String? dbImageUrl, String foodName) {
    // Si ya tiene una URL completa, úsala
    if (dbImageUrl != null && dbImageUrl.startsWith('http')) {
      return dbImageUrl;
    }
    
    // Si es un path parcial, conviértelo en URL completa
    if (dbImageUrl != null && dbImageUrl.isNotEmpty) {
      // Si es solo el nombre del archivo
      if (!dbImageUrl.contains('/')) {
        return 'https://firebasestorage.googleapis.com/v0/b/mi-cuerpo-copia.appspot.com/o/$_baseStoragePath%2F$dbImageUrl?alt=media';
      }
      
      // Si es una ruta relativa, agregar la base URL
      if (!dbImageUrl.startsWith('https://')) {
        return 'https://firebasestorage.googleapis.com/v0/b/mi-cuerpo-copia.appspot.com/o/$dbImageUrl?alt=media';
      }
    }
    
    // Como último recurso, generar nombre de archivo basado en el nombre de la comida
    final fileName = foodNameToFileName(foodName);
    return 'https://firebasestorage.googleapis.com/v0/b/mi-cuerpo-copia.appspot.com/o/$_baseStoragePath%2F$fileName?alt=media';
  }
  
  // Convertir nombre de comida a nombre de archivo válido
  static String foodNameToFileName(String foodName) {
    if (foodName.isEmpty) return 'default_food.jpg';
    
    // Convertir a minúsculas, reemplazar espacios con guiones bajos, quitar caracteres especiales
    final fileName = '${foodName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')}.jpg';
        
    return fileName;
  }
  
  // Comprobar si una imagen existe en Storage
  static Future<bool> checkIfImageExists(String fileName) async {
    try {
      final ref = _storage.ref().child('$_baseStoragePath/$fileName');
      await ref.getDownloadURL();
      return true;
    } catch (e) {
      debugPrint('Imagen no encontrada en Storage: $fileName');
      return false;
    }
  }
  
  // Obtener la URL de descarga de una imagen en Storage
  static Future<String> getDownloadURL(String fileName) async {
    try {
      final ref = _storage.ref().child('$_baseStoragePath/$fileName');
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error obteniendo URL de descarga: $e');
      return _fallbackImageUrl;
    }
  }
  
  // Widget para mostrar una imagen con manejo de errores
  static Widget buildNetworkImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final actualPlaceholder = placeholder ?? Container(
      color: Colors.grey[300],
      child: const Center(child: CircularProgressIndicator()),
    );
    
    final actualErrorWidget = errorWidget ?? Container(
      color: Colors.grey[300],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
          SizedBox(height: 4),
          Text(
            'Imagen no disponible',
            style: TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    
    // Si la URL está vacía, mostrar el widget de error
    if (imageUrl.isEmpty) {
      return actualErrorWidget;
    }
    
    // Intentar cargar la imagen
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => actualPlaceholder,
      errorWidget: (context, url, error) {
        debugPrint('Error cargando imagen: $url - $error');
        return actualErrorWidget;
      },
      fadeInDuration: const Duration(milliseconds: 200),
      cacheKey: 'food_image_${imageUrl.hashCode}',
    );
  }
}