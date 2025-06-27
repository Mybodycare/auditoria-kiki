import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/receta.dart';

class RecetaService {
  static Future<List<Receta>> cargarRecetas(String categoria) async {
    try {
      List<String> archivos = [];
      
      // Determinar qué archivos cargar basado en la categoría
      switch (categoria) {
        case 'desayuno':
          archivos = ['recetas_desayuno_sin_imagenes_urls.json'];
          break;
        case 'almuerzo':
          archivos = [
            'recetas_almuerzo.json',
            'recetas_almuerzo_10.json',
            'recetas_almuerzo_nuevas.json'
          ];
          break;
        case 'comida':
          archivos = [
            'recetas_comida.json',
            'recetas_comida_10.json',
            'recetas_comida_nuevas.json'
          ];
          break;
        case 'cena':
          archivos = [
            'recetas_cena.json',
            'recetas_cena_10.json',
            'recetas_cena_nuevas.json'
          ];
          break;
      }

      List<Receta> todasLasRecetas = [];

      // Cargar todos los archivos de la categoría
      for (var archivo in archivos) {
        try {
          final String jsonString = await rootBundle.loadString('assets/data/$archivo');
          final List<dynamic> jsonList = json.decode(jsonString);
          todasLasRecetas.addAll(jsonList.map((json) => Receta.fromJson(json)).toList());
        } catch (e) {
          // Ignorar errores de archivos individuales
          continue;
        }
      }

      return todasLasRecetas;
    } catch (e) {
      // En caso de error general, retornar lista vacía
      return [];
    }
  }

  static Future<List<Receta>> filtrarPorTemporada(String categoria, String temporada) async {
    final recetas = await cargarRecetas(categoria);
    return recetas.where((receta) => receta.temporadaRecomendada == temporada).toList();
  }

  static Future<List<Receta>> filtrarPorTipoDieta(String categoria, String tipoDieta) async {
    final recetas = await cargarRecetas(categoria);
    return recetas.where((receta) => receta.infoInterna.tipoDieta == tipoDieta).toList();
  }

  static Future<List<Receta>> filtrarPorCalorias(String categoria, int maxCalorias) async {
    final recetas = await cargarRecetas(categoria);
    return recetas.where((receta) => receta.calorias <= maxCalorias).toList();
  }

  static Future<List<Receta>> filtrarPorTiempo(String categoria, int maxMinutos) async {
    final recetas = await cargarRecetas(categoria);
    return recetas.where((receta) => receta.tiempoTotalMin <= maxMinutos).toList();
  }

  static Future<List<Receta>> buscarRecetas(String categoria, String busqueda) async {
    final recetas = await cargarRecetas(categoria);
    return recetas.where((receta) {
      final nombre = receta.nombre.toLowerCase();
      final ingredientes = receta.ingredientes.map((i) => i.nombre.toLowerCase()).join(' ');
      return nombre.contains(busqueda.toLowerCase()) || 
             ingredientes.contains(busqueda.toLowerCase());
    }).toList();
  }
} 