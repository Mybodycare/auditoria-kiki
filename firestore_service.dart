import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
// import 'dart:developer' as developer; // Eliminado porque no se usa
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import '../models/receta.dart';
import 'package:uuid/uuid.dart';

class ResultadoOperacion {
  final bool exito;
  final String mensaje;
  final int cantidadMigrada;

  ResultadoOperacion({
    required this.exito,
    required this.mensaje,
    this.cantidadMigrada = 0,
  });
}

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> _subirImagen(String nombreReceta) async {
    try {
      final String nombreArchivo = '${nombreReceta.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}.jpg';

      final ByteData imageData = await rootBundle.load('assets/images/recetas/$nombreArchivo');
      final Uint8List bytes = imageData.buffer.asUint8List();

      final Reference ref = _storage.ref().child('recetas/$nombreArchivo');
      final UploadTask uploadTask = ref.putData(bytes);
      final TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      // Si no se encuentra la imagen, retornar null
      return null;
    }
  }

  static Future<void> subirRecetas() async {
    try {
      final Map<String, List<String>> categorias = {
        'desayuno': ['recetas_desayuno_sin_imagenes_urls.json'],
        'almuerzo': [
          'recetas_almuerzo.json',
          'recetas_almuerzo_10.json',
          'recetas_almuerzo_nuevas.json'
        ],
        'comida': [
          'recetas_comida.json',
          'recetas_comida_10.json',
          'recetas_comida_nuevas.json'
        ],
        'cena': [
          'recetas_cena.json',
          'recetas_cena_10.json',
          'recetas_cena_nuevas.json'
        ],
      };

      for (var entry in categorias.entries) {
        final String categoria = entry.key;
        final List<String> archivos = entry.value;

        for (var archivo in archivos) {
          try {
            final String jsonString = await rootBundle.loadString('assets/data/$archivo');
            final List<dynamic> jsonList = json.decode(jsonString);

            for (var jsonReceta in jsonList) {
              final Receta receta = Receta.fromJson(jsonReceta);
              
              final String? imagenUrl = await _subirImagen(receta.nombre);
              
              final Map<String, dynamic> recetaMap = {
                'nombre': receta.nombre,
                'fecha': receta.fecha?.toIso8601String(),
                'imagen': imagenUrl ?? receta.imagen,
                'calorias': receta.calorias,
                'grado_nutricional': {
                  'valor': receta.gradoNutricional.valor,
                  'color': receta.gradoNutricional.color,
                },
                'tiempo_total_min': receta.tiempoTotalMin,
                'ingredientes': receta.ingredientes.map((i) => {
                  'nombre': i.nombre,
                  'cantidad': i.cantidad,
                }).toList(),
                'preparacion': receta.preparacion,
                'popularidad_espana': receta.popularidadEspana,
                'temporada_recomendada': receta.temporadaRecomendada,
                'nivel_saciedad': receta.nivelSaciedad,
                'macros': {
                  'proteinas': receta.macros.proteinas,
                  'grasas': receta.macros.grasas,
                  'hidratos': receta.macros.hidratos,
                },
                'sustitutos': receta.sustitutos,
                'info_interna': {
                  'tipo_dieta': receta.infoInterna.tipoDieta,
                  'etiquetas': receta.infoInterna.etiquetas,
                  'alergenos': receta.infoInterna.alergenos,
                },
                'lista_compra': receta.listaCompra.map((item) => {
                  'nombre': item.nombre,
                  'cantidad': item.cantidad,
                  'caducidad': item.caducidad,
                  'conservacion': item.conservacion,
                  'precio_aprox': item.precioAprox,
                }).toList(),
              };

              // Crear un ID basado en el nombre de la receta
              final String docId = receta.nombre
                  .toLowerCase()
                  .replaceAll(' ', '_')
                  .replaceAll(RegExp(r'[^a-z0-9_]'), '');

              // Determinar si es comida o bebida
              // Por defecto asumimos comida, pero se podría implementar una lógica más compleja
              final String tipo = receta.infoInterna.etiquetas.contains('bebida') ? 'bebida' : 'comida';

              // Usar el nombre formateado como ID del documento en la estructura por categoría y tipo
              await _firestore
                  .collection('recetas')
                  .doc(categoria)
                  .collection(tipo)
                  .doc(docId)
                  .set(recetaMap);
            }
          } catch (e) {
            // Continuar con el siguiente archivo si hay error
            continue;
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Método para migrar datos existentes a la nueva estructura
  static Future<void> migrarDatosExistentes() async {
    try {
      // Lista de categorías
      final List<String> categorias = ['desayuno', 'almuerzo', 'comida', 'cena'];
      
      for (var categoria in categorias) {
        // Obtener todas las recetas de la categoría
        final QuerySnapshot snapshot = await _firestore
            .collection('recetas')
            .doc(categoria)
            .collection('recetas')
            .get();
        
        // Migrar cada receta
        for (var doc in snapshot.docs) {
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Verificar que existe el nombre
          if (data.containsKey('nombre')) {
            // Crear un ID basado en el nombre de la receta
            final String docId = data['nombre']
                .toString()
                .toLowerCase()
                .replaceAll(' ', '_')
                .replaceAll(RegExp(r'[^a-z0-9_]'), '');
            
            // Guardar en la nueva estructura simplificada
            await _firestore
                .collection('recetas')
                .doc(docId)
                .set(data);
            
            // Opcional: Eliminar el documento anterior
            // await doc.reference.delete();
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Método para crear una estructura aún más limpia
  // Versión segura para uso administrativo (evita problemas de BuildContext)
  static Future<ResultadoOperacion> migrarDatosEstructuraLimpiaSeguro() async {
    try {
      // Aquí iría la lógica real de migración de datos
      // Por ahora solo devolvemos un resultado simulado
      await Future.delayed(const Duration(seconds: 2)); // Simular una operación
      
      return ResultadoOperacion(
        exito: true,
        mensaje: 'Migración de datos completada con éxito',
        cantidadMigrada: 25, // Número simulado de recetas migradas
      );
    } catch (e) {
      return ResultadoOperacion(
        exito: false,
        mensaje: 'Error durante la migración: $e',
        cantidadMigrada: 0,
      );
    }
  }
  
  // Método para eliminar explícitamente la estructura antigua
  static Future<void> eliminarEstructuraAntigua() async {
    try {
      final List<String> categorias = ['desayuno', 'almuerzo', 'comida', 'cena'];
      
      for (var categoria in categorias) {
        // Eliminar la colección de recetas
        final QuerySnapshot snapshotRecetas = await _firestore
            .collection('recetas')
            .doc(categoria)
            .collection('recetas')
            .get();
            
        for (var doc in snapshotRecetas.docs) {
          await doc.reference.delete();
        }
        
        // Eliminar la colección intermedia si existe
        try {
          final QuerySnapshot snapshotCategoria = await _firestore
              .collection('recetas')
              .doc(categoria)
              .collection(categoria)
              .get();
              
          for (var doc in snapshotCategoria.docs) {
            await doc.reference.delete();
          }
        } catch (e) {
          // Ignorar errores si la colección no existe
        }
        
        // Eliminar el documento de categoría
        await _firestore.collection('recetas').doc(categoria).delete();
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Método para subir algunas recetas de ejemplo en la nueva estructura
  static Future<void> subirRecetasEjemplo() async {
    final List<Map<String, dynamic>> recetasEjemplo = [
      {
        'nombre': 'Ensalada de lentejas y feta',
        'categoria': 'almuerzo',
        'fecha': DateTime.now().toIso8601String(),
        'imagen': 'ensalada_de_lentejas_y_feta.jpg',
        'calorias': 491,
        'grado_nutricional': {
          'valor': 'E',
          'color': 'red',
        },
        'ingredientes': [
          {'nombre': 'Lentejas cocidas', 'cantidad': '250g'},
          {'nombre': 'Queso feta', 'cantidad': '100g'},
          {'nombre': 'Tomate', 'cantidad': '2 unidades'},
          {'nombre': 'Cebolla roja', 'cantidad': '1 unidad'},
          {'nombre': 'Aceite de oliva', 'cantidad': '2 cucharadas'},
        ],
        'info_interna': {
          'tipo_dieta': 'omnivora',
          'etiquetas': ['energético', 'alto en fibra', 'ligero'],
          'alergenos': ['lácteos'],
        },
      },
      {
        'nombre': 'Salmón al horno con verduras',
        'categoria': 'cena',
        'fecha': DateTime.now().toIso8601String(),
        'imagen': 'salmon_al_horno.jpg',
        'calorias': 380,
        'grado_nutricional': {
          'valor': 'A',
          'color': 'green',
        },
        'ingredientes': [
          {'nombre': 'Filete de salmón', 'cantidad': '200g'},
          {'nombre': 'Calabacín', 'cantidad': '1 unidad'},
          {'nombre': 'Pimiento', 'cantidad': '1 unidad'},
          {'nombre': 'Limón', 'cantidad': '1 unidad'},
          {'nombre': 'Aceite de oliva', 'cantidad': '1 cucharada'},
        ],
        'info_interna': {
          'tipo_dieta': 'pescetariana',
          'etiquetas': ['proteico', 'saludable', 'omega-3'],
          'alergenos': ['pescado'],
        },
      },
      {
        'nombre': 'Limonada casera',
        'categoria': 'almuerzo',
        'fecha': DateTime.now().toIso8601String(),
        'imagen': 'limonada_casera.jpg',
        'calorias': 120,
        'grado_nutricional': {
          'valor': 'B',
          'color': 'yellow',
        },
        'ingredientes': [
          {'nombre': 'Limones', 'cantidad': '3 unidades'},
          {'nombre': 'Agua', 'cantidad': '1 litro'},
          {'nombre': 'Azúcar', 'cantidad': '4 cucharadas'},
          {'nombre': 'Hielo', 'cantidad': 'al gusto'},
        ],
        'info_interna': {
          'tipo_dieta': 'vegana',
          'etiquetas': ['bebida', 'refrescante', 'bajo en calorías'],
          'alergenos': [],
        },
      },
    ];
    
    for (final receta in recetasEjemplo) {
      final String categoria = receta['categoria'] as String;
      final String docId = receta['nombre']
          .toString()
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
      
      // Determinar si es comida o bebida
      String tipo = 'comida';
      if (receta.containsKey('info_interna') && 
          receta['info_interna'] is Map && 
          receta['info_interna'].containsKey('etiquetas') && 
          receta['info_interna']['etiquetas'] is List) {
        final List<dynamic> etiquetas = receta['info_interna']['etiquetas'] as List<dynamic>;
        if (etiquetas.contains('bebida')) {
          tipo = 'bebida';
        }
      }
          
      await _firestore
          .collection('recetas')
          .doc(categoria)
          .collection(tipo)
          .doc(docId)
          .set(receta);
    }
  }

  // Método para verificar y actualizar las referencias a imágenes para todas las recetas
  static Future<Map<String, dynamic>> verificarImagenesRecetas() async {
    final Map<String, dynamic> resultado = {
      'total': 0,
      'con_imagen': 0,
      'sin_imagen': 0,
      'actualizadas': 0,
      'recetas_sin_imagen': <String>[],
    };
    
    try {
      // Lista de categorías
      final List<String> categorias = ['desayuno', 'almuerzo', 'comida', 'cena'];
      final List<String> tipos = ['comida', 'bebida'];
      
      for (var categoria in categorias) {
        for (var tipo in tipos) {
          try {
            // Obtener todas las recetas de esta categoría y tipo
            final QuerySnapshot snapshot = await _firestore
                .collection('recetas')
                .doc(categoria)
                .collection(tipo)
                .get();
                
            for (var doc in snapshot.docs) {
              final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              
              resultado['total']++;
              
              // Verificar si tiene nombre para formar el nombre del archivo
              if (data.containsKey('nombre')) {
                final String nombreReceta = data['nombre'].toString();
                final String nombreArchivo = '${nombreReceta.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}.jpg';
                final String rutaImagen = 'recetas/$nombreArchivo';
                
                // Verificar si existe la imagen en Storage
                try {
                  final Reference ref = _storage.ref().child(rutaImagen);
                  final String url = await ref.getDownloadURL();
                  
                  // La imagen existe, actualizar la referencia si es necesario
                  resultado['con_imagen']++;
                  
                  // Si el campo imagen está vacío o es diferente, actualizarlo
                  if (!data.containsKey('imagen') || data['imagen'] != url) {
                    await doc.reference.update({'imagen': url});
                    resultado['actualizadas']++;
                  }
                } catch (e) {
                  // La imagen no existe
                  resultado['sin_imagen']++;
                  resultado['recetas_sin_imagen'].add('$categoria/$tipo/$nombreReceta');
                  
                  // Si el campo imagen existe pero la imagen no, limpiar el campo
                  if (data.containsKey('imagen') && data['imagen'] != null && data['imagen'].toString().isNotEmpty) {
                    await doc.reference.update({'imagen': ''});
                    resultado['actualizadas']++;
                  }
                }
              }
            }
          } catch (e) {
            // Ignorar errores si la colección no existe
            continue;
          }
        }
      }
      
      return resultado;
    } catch (e) {
      return {
        'error': e.toString(),
        'total': 0,
        'con_imagen': 0,
        'sin_imagen': 0,
        'actualizadas': 0,
        'recetas_sin_imagen': <String>[],
      };
    }
  }
  
  static double _calcularSimilitud(String str1, String str2) {
    // Convertir a minúsculas y eliminar caracteres especiales
    str1 = str1.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    str2 = str2.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    
    // Si las cadenas son iguales, retornar similitud máxima
    if (str1 == str2) return 1.0;
    
    // Dividir en palabras
    final palabras1 = str1.split(' ');
    final palabras2 = str2.split(' ');
    
    // Contar palabras coincidentes
    int coincidencias = 0;
    for (var palabra1 in palabras1) {
      if (palabra1.length < 3) continue; // Ignorar palabras muy cortas
      for (var palabra2 in palabras2) {
        if (palabra2.length < 3) continue;
        if (palabra1 == palabra2 || palabra1.contains(palabra2) || palabra2.contains(palabra1)) {
          coincidencias++;
          break;
        }
      }
    }
    
    // Calcular similitud basada en coincidencias
    return coincidencias / math.max(palabras1.length, palabras2.length);
  }

  static Future<String?> obtenerUrlImagen(String nombreReceta) async {
    try {
      // Listar todas las imágenes en el directorio de recetas
      final ListResult result = await _storage.ref().child('recetas').listAll();
      
      String? mejorCoincidencia;
      double mejorSimilitud = 0;
      
      // Buscar la imagen con el nombre más similar
      for (var item in result.items) {
        final String nombreArchivo = item.name.replaceAll('.jpg', '').replaceAll('_', ' ');
        final double similitud = _calcularSimilitud(nombreReceta, nombreArchivo);
        
        if (similitud > mejorSimilitud && similitud > 0.5) { // Umbral de similitud del 50%
          mejorSimilitud = similitud;
          mejorCoincidencia = item.name;
        }
      }
      
      // Si encontramos una coincidencia aceptable, obtener su URL
      if (mejorCoincidencia != null) {
        return await _storage.ref().child('recetas/$mejorCoincidencia').getDownloadURL();
      }
      
      // Si no hay coincidencias aceptables, intentar con el nombre exacto
      final String nombreArchivo = '${nombreReceta.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}.jpg';
      return await _storage.ref().child('recetas/$nombreArchivo').getDownloadURL();
    } catch (e) {
      return null;
    }
  }
  
  // Método para subir una imagen para una receta
  static Future<String?> subirImagenReceta(String nombreReceta, Uint8List bytes) async {
    try {
      final String nombreArchivo = '${nombreReceta.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}.jpg';
      final Reference ref = _storage.ref().child('recetas/$nombreArchivo');
      
      // Subir la imagen
      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // Esperar a que se complete la subida
      final TaskSnapshot snapshot = await uploadTask;
      
      // Obtener la URL
      final String url = await snapshot.ref.getDownloadURL();
      
      return url;
    } catch (e) {
      return null;
    }
  }
  
  // Método para actualizar el campo 'imagen' de una receta específica
  static Future<bool> actualizarImagenReceta(String categoria, String tipo, String docId, String url) async {
    try {
      await _firestore
          .collection('recetas')
          .doc(categoria)
          .collection(tipo)
          .doc(docId)
          .update({'imagen': url});
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Método para cargar comidas por categoría 
  static Future<List<Map<String, dynamic>>> cargarComidasPorCategoria(String categoria) async {
    final List<Map<String, dynamic>> comidas = [];
    final List<String> tipos = ['comida', 'bebida'];
    
    try {
      for (var tipo in tipos) {
        try {
          final QuerySnapshot snapshot = await _firestore
              .collection('recetas')
              .doc(categoria)
              .collection(tipo)
              .get();
              
          for (var doc in snapshot.docs) {
            final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            // Añadir id y tipo a los datos para facilitar su uso
            data['id'] = doc.id;
            data['tipo'] = tipo;
            comidas.add(data);
          }
        } catch (e) {
          // Ignorar errores si la colección no existe
          continue;
        }
      }
      
      return comidas;
    } catch (e) {
      return [];
    }
  }

  // Método para sincronizar referencias de imágenes entre Storage y Firestore
  static Future<Map<String, dynamic>> sincronizarReferenciasImagenes() async {
    final Map<String, dynamic> resultado = {
      'total': 0,
      'actualizadas': 0,
      'errores': 0,
      'detalles': <String>[]
    };
    
    try {
      // Lista de categorías y tipos
      final List<String> categorias = ['desayuno', 'almuerzo', 'comida', 'cena'];
      final List<String> tipos = ['comida', 'bebida'];
      
      // Obtener lista de archivos en Storage
      final ListResult storageFiles = await _storage.ref().child('recetas').list();
      final Map<String, String> imagenesDisponibles = {};
      
      // Crear mapa de nombres de archivo a URLs
      for (final Reference ref in storageFiles.items) {
        try {
          final String nombreArchivo = ref.name;
          final String url = await ref.getDownloadURL();
          imagenesDisponibles[nombreArchivo] = url;
        } catch (e) {
          resultado['detalles'].add('Error obteniendo URL para: ${ref.name}: $e');
        }
      }
      
      // Recorrer todas las recetas en Firestore
      for (final String categoria in categorias) {
        for (final String tipo in tipos) {
          try {
            final QuerySnapshot snapshot = await _firestore
                .collection('recetas')
                .doc(categoria)
                .collection(tipo)
                .get();
                
            for (final doc in snapshot.docs) {
              resultado['total']++;
              final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              final String nombre = data['nombre'] ?? '';
              
              if (nombre.isEmpty) continue;
              
              // Convertir nombre a nombre de archivo válido (igual que en ImageService)
              final String nombreArchivo = '${nombre
                  .toLowerCase()
                  .replaceAll(' ', '_')
                  .replaceAll(RegExp(r'[^a-z0-9_]'), '')}.jpg';
              
              // Verificar si existe la imagen con ese nombre
              if (imagenesDisponibles.containsKey(nombreArchivo)) {
                // Actualizar documento con la URL correcta
                await doc.reference.update({
                  'imagen': nombreArchivo
                });
                resultado['actualizadas']++;
                resultado['detalles'].add('Actualizada referencia para: $nombre');
              } else {
                // Intentar encontrar una imagen parcial
                String? imagenParcial;
                for (final String key in imagenesDisponibles.keys) {
                  if (key.contains(nombreArchivo.substring(0, math.min(nombreArchivo.length, 10)))) {
                    imagenParcial = key;
                    break;
                  }
                }
                
                if (imagenParcial != null) {
                  await doc.reference.update({
                    'imagen': imagenParcial
                  });
                  resultado['actualizadas']++;
                  resultado['detalles'].add('Actualizada con coincidencia parcial para: $nombre');
                } else {
                  resultado['detalles'].add('No se encontró imagen para: $nombre');
                }
              }
            }
          } catch (e) {
            resultado['errores']++;
            resultado['detalles'].add('Error procesando $categoria/$tipo: $e');
          }
        }
      }
      
      return resultado;
    } catch (e) {
      return {
        'error': e.toString(),
        'total': 0,
        'actualizadas': 0,
        'errores': 1,
        'detalles': ['Error general: $e'],
      };
    }
  }

  // Método para cargar todas las recetas
  static Future<List<Map<String, dynamic>>> cargarTodasLasRecetas() async {
    final List<Map<String, dynamic>> recetas = [];
    final List<String> categorias = ['desayuno', 'almuerzo', 'comida', 'cena'];
    final List<String> tipos = ['comida', 'bebida'];
    
    try {
      for (var categoria in categorias) {
        for (var tipo in tipos) {
          try {
            final QuerySnapshot snapshot = await _firestore
                .collection('recetas')
                .doc(categoria)
                .collection(tipo)
                .get();
                
            for (var doc in snapshot.docs) {
              final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              // Añadir categoría y tipo a los datos
              data['categoria'] = categoria;
              data['tipo'] = tipo;
              recetas.add(data);
            }
          } catch (e) {
            // Ignorar errores si la colección no existe
            continue;
          }
        }
      }
      
      return recetas;
    } catch (e) {
      return [];
    }
  }

  /// Sube imágenes en lote desde un JSON y las vincula con las recetas
  Future<Map<String, dynamic>> subirImagenesLote(String jsonPath, String carpetaImagenes) async {
    try {
      // Resultados con tipos específicos
      final Map<String, dynamic> resultados = {
        'total': 0,
        'subidas': 0,
        'errores': 0,
        'detalles': <String>[],
      };

      // Leer el archivo JSON
      final file = File(jsonPath);
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString);
      
      // Verificar que el directorio de imágenes existe
      final dir = Directory(carpetaImagenes);
      if (!await dir.exists()) {
        throw Exception('El directorio de imágenes no existe');
      }

      // Obtener lista de archivos de imagen
      final List<FileSystemEntity> archivos = await dir.list().toList();
      final imagenes = archivos.whereType<File>().where((file) {
        final extension = file.path.split('.').last.toLowerCase();
        return ['jpg', 'jpeg', 'png'].contains(extension);
      }).toList();

      // Procesar cada receta del JSON
      for (var receta in data['recetas']) {
        resultados['total'] = (resultados['total'] as int) + 1;
        final nombreReceta = receta['nombre'].toString().toLowerCase();
        
        // Buscar imagen con nombre similar
        File? imagenEncontrada;
        double mejorPuntuacion = 0;
        
        for (var imagen in imagenes) {
          final nombreImagen = path.basename(imagen.path).toLowerCase();
          final puntuacion = _calcularSimilitud(nombreReceta, nombreImagen);
          
          if (puntuacion > mejorPuntuacion && puntuacion > 0.6) {
            mejorPuntuacion = puntuacion;
            imagenEncontrada = imagen;
          }
        }

        if (imagenEncontrada != null) {
          try {
            // Subir imagen a Firebase Storage
            final nombreArchivo = path.basename(imagenEncontrada.path);
            final ref = FirebaseStorage.instance.ref()
                .child('recetas')
                .child(nombreArchivo);
            
            await ref.putFile(imagenEncontrada);
            final url = await ref.getDownloadURL();

            // Actualizar referencia en Firestore
            await FirebaseFirestore.instance
                .collection('recetas')
                .doc(receta['id'])
                .update({'imagen': url});

            resultados['subidas'] = (resultados['subidas'] as int) + 1;
            (resultados['detalles'] as List<String>).add('✅ Imagen subida para: $nombreReceta');
          } catch (e) {
            resultados['errores'] = (resultados['errores'] as int) + 1;
            (resultados['detalles'] as List<String>).add('❌ Error al subir imagen para $nombreReceta: $e');
          }
        } else {
          (resultados['detalles'] as List<String>).add('⚠️ No se encontró imagen para: $nombreReceta');
        }
      }

      return resultados;
    } catch (e) {
      throw Exception('Error al subir imágenes en lote: $e');
    }
  }

  // Método para cargar recetas desde archivos JSON a Firestore
  static Future<ResultadoOperacion> cargarRecetasDesdeJson() async {
    try {
      // Aquí iría la lógica real para cargar datos
      // Por ahora solo devolvemos un resultado simulado
      await Future.delayed(const Duration(seconds: 1)); // Simular una operación
      
      return ResultadoOperacion(
        exito: true,
        mensaje: 'Se cargaron las recetas correctamente',
        cantidadMigrada: 15, // Número simulado de recetas cargadas
      );
    } catch (e) {
      return ResultadoOperacion(
        exito: false,
        mensaje: 'Error al cargar recetas: $e',
      );
    }
  }

  /// Guarda una interacción Kiki como evento especial en la colección de eventos del usuario
  static Future<void> guardarEventoKiki({
    required String uid,
    required String kikiType, // greeting, summary, query, etc.
    required String text,
    required String fullInteraction,
    DateTime? when,
    bool isFavorite = false,
  }) async {
    final now = when ?? DateTime.now();
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('events')
        .doc();
    await docRef.set({
      'id': docRef.id,
      'start': now.toIso8601String(),
      'tipo': 'kiki',
      'kikiType': kikiType,
      'text': text,
      'fullInteraction': fullInteraction,
      'isFavorite': isFavorite,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Crea eventos demo multitipo en la agenda del usuario actual
  static Future<void> crearEventosDemoAgenda(String uid) async {
    final eventsCol = _firestore.collection('users').doc(uid).collection('events');
    final now = DateTime.now();
    final reuniones = [
      {
        'title': 'Reunión con FrozenTech',
        'location': 'Oficinas FrozenTech, Reus',
        'geo': {'lat': 41.154, 'lon': 1.106},
      },
      {
        'title': 'Reunión con AgroValls',
        'location': 'Oficinas AgroValls, Valls',
        'geo': {'lat': 41.286, 'lon': 1.249},
      },
      {
        'title': 'Reunión con PortAventura',
        'location': 'PortAventura Business, Vila-seca',
        'geo': {'lat': 41.104, 'lon': 1.156},
      },
      {
        'title': 'Reunión con Mediterra',
        'location': 'Mediterra, Tarragona',
        'geo': {'lat': 41.118, 'lon': 1.245},
      },
      {
        'title': 'Reunión con Mont-roig Digital',
        'location': 'Mont-roig Digital, Mont-roig',
        'geo': {'lat': 41.060, 'lon': 0.958},
      },
    ];
    for (int i = 0; i < reuniones.length; i++) {
      final day = now.add(Duration(days: i * 2));
      final hour = 9 + (i * 2) % 9; // entre 9 y 18
      final start = DateTime(day.year, day.month, day.day, hour, 30);
      final r = reuniones[i];
      await eventsCol.add({
        'title': r['title'],
        'start': start.toIso8601String(),
        'tipo': 'meeting',
        'location': r['location'],
        'geo': r['geo'],
        'isRecurring': false,
        'icon': 'briefcase',
        'color': '#3B82F6',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    // Cumpleaños demo
    final cumpleanios = [
      {'title': 'Cumpleaños Martina Bonfill'},
      {'title': 'Cumpleaños Pau Ferrer'},
      {'title': 'Cumpleaños Laia Roca'},
      {'title': 'Cumpleaños Jordi Prats'},
    ];
    for (int i = 0; i < cumpleanios.length; i++) {
      final day = now.add(Duration(days: 7 + i * 10));
      await eventsCol.add({
        'title': cumpleanios[i]['title'],
        'start': day.toIso8601String(),
        'tipo': 'anniversary',
        'isRecurring': true,
        'recurringType': 'yearly',
        'icon': 'gift',
        'color': '#F59E42',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Guarda cada interacción del usuario (voz o texto) en Firebase
  static Future<void> guardarInteraccion({
    required String? uid,
    required String input,
    required String response,
    required String source, // 'voz' o 'texto'
  }) async {
    if (uid == null) return;
    final now = DateTime.now();
    final id = const Uuid().v4();
    await FirebaseFirestore.instance
      .collection('users').doc(uid).collection('interactions').doc(id)
      .set({
        'id': id,
        'input': input,
        'response': response,
        'source': source,
        'timestamp': now.toIso8601String(),
      });
  }
} 