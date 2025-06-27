import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pharmacology_models.dart';
import '../data/pharmacology_data.dart';
import 'package:uuid/uuid.dart';

class PharmacologyService {
  // Claves para SharedPreferences
  static const String _substancesKey = 'pharmacology_substances';
  static const String _administrationsKey = 'pharmacology_administrations';
  static const String _templatesKey = 'pharmacology_templates';
  
  // Instancia de UUID para generar identificadores
  final Uuid _uuid = Uuid();
  
  // Singleton
  static final PharmacologyService _instance = PharmacologyService._internal();
  
  factory PharmacologyService() {
    return _instance;
  }
  
  PharmacologyService._internal();
  
  // Método para guardar una sustancia
  Future<void> saveSubstance(PharmacologicalSubstance substance) async {
    final prefs = await SharedPreferences.getInstance();
    
    List<PharmacologicalSubstance> substances = await getSubstances();
    
    // Verifica si la sustancia ya existe
    int existingIndex = substances.indexWhere((s) => s.id == substance.id);
    
    if (existingIndex >= 0) {
      substances[existingIndex] = substance;
    } else {
      substances.add(substance);
    }
    
    await prefs.setString(
      _substancesKey, 
      jsonEncode(substances.map((s) => s.toJson()).toList())
    );
  }
  
  // Método para obtener todas las sustancias
  Future<List<PharmacologicalSubstance>> getSubstances() async {
    final prefs = await SharedPreferences.getInstance();
    final String? substancesJson = prefs.getString(_substancesKey);

    if (substancesJson == null || substancesJson.isEmpty) {
      // Si no hay sustancias guardadas, guardarlas TODAS de una vez
      try {
        // Convertir todas las predefinidas a JSON
        final predefinedJsonList = predefinedSubstances.map((s) => s.toJson()).toList();
        // Guardar la lista completa en SharedPreferences
        await prefs.setString(_substancesKey, jsonEncode(predefinedJsonList));
        // Devolver la lista predefinida directamente
        return predefinedSubstances;
      } catch (e) {
        return []; // Devolver vacío en caso de error al guardar
      }
    }

    // Si ya existen datos, decodificarlos y devolverlos
    try {
      List<dynamic> decodedList = jsonDecode(substancesJson);
      final substances = decodedList
          .map((item) => PharmacologicalSubstance.fromJson(item))
          .toList();
      return substances;
    } catch (e) {
      // Si hay un error al decodificar, intentar borrar datos corruptos y devolver vacío
      await prefs.remove(_substancesKey);
      return [];
    }
  }
  
  // Método para guardar una administración
  Future<void> saveAdministration(SubstanceAdministration administration) async {
    final prefs = await SharedPreferences.getInstance();
    
    List<SubstanceAdministration> administrations = await getAdministrations();
    
    // Verifica si la administración ya existe
    int existingIndex = administrations.indexWhere((a) => a.id == administration.id);
    
    if (existingIndex >= 0) {
      administrations[existingIndex] = administration;
    } else {
      administrations.add(administration);
    }
    
    await prefs.setString(
      _administrationsKey, 
      jsonEncode(administrations.map((a) => a.toJson()).toList())
    );
  }
  
  // Método para obtener todas las administraciones
  Future<List<SubstanceAdministration>> getAdministrations() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? administrationsJson = prefs.getString(_administrationsKey);
    
    if (administrationsJson == null || administrationsJson.isEmpty) {
      return [];
    }
    
    try {
      List<dynamic> decodedList = jsonDecode(administrationsJson);
      return decodedList
          .map((item) => SubstanceAdministration.fromJson(item))
          .toList();
    } catch (e) {
      // Si hay un error, retornar una lista vacía
      return [];
    }
  }
  
  // Método para obtener administraciones por fecha
  Future<List<SubstanceAdministration>> getAdministrationsByDate(DateTime date) async {
    List<SubstanceAdministration> allAdministrations = await getAdministrations();
    
    return allAdministrations.where((admin) => 
      admin.date.year == date.year && 
      admin.date.month == date.month && 
      admin.date.day == date.day
    ).toList();
  }
  
  // Método para calcular la potencia anabólica total para un día
  Future<double> calculateDailyAnabolicPotency(DateTime date) async {
    List<SubstanceAdministration> dailyAdministrations = 
        await getAdministrationsByDate(date);
    
    if (dailyAdministrations.isEmpty) return 0.0;
    
    List<PharmacologicalSubstance> substances = await getSubstances();
    
    double totalPotency = 0.0;
    
    for (var administration in dailyAdministrations) {
      // Buscar la sustancia correspondiente
      final substance = substances.firstWhere(
        (s) => s.id == administration.substanceId,
        orElse: () => PharmacologicalSubstance(
          id: '', // ID vacío indica que no se encontró
          name: 'Desconocido',
          unit: '',
          baseAnabolicPotency: 0,
          category: SubstanceCategory.other,
          // No se requiere iconPath ni justification aquí
        ),
      );
      
      if (substance.id.isNotEmpty) {
        totalPotency += administration.calculateAnabolicPotency(
          substance.baseAnabolicPotency
        );
      }
    }
    
    return totalPotency;
  }
  
  // Método para calcular la potencia anabólica semanal
  Future<double> calculateWeeklyAnabolicPotency(DateTime date) async {
    // Obtener el inicio de la semana (lunes)
    DateTime startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    
    double weeklyTotal = 0.0;
    
    // Calcular potencia para cada día de la semana
    for (int i = 0; i < 7; i++) {
      DateTime currentDay = startOfWeek.add(Duration(days: i));
      double dailyPotency = await calculateDailyAnabolicPotency(currentDay);
      weeklyTotal += dailyPotency;
    }
    
    return weeklyTotal;
  }
  
  // Obtener potencia promedio diaria
  Future<double> calculateAverageDailyPotency(DateTime date) async {
    double weeklyPotency = await calculateWeeklyAnabolicPotency(date);
    return weeklyPotency / 7.0;
  }
  
  // Método para guardar una plantilla
  Future<void> saveTemplate(AdministrationTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    
    List<AdministrationTemplate> templates = await getTemplates();
    
    // Verifica si la plantilla ya existe
    int existingIndex = templates.indexWhere((t) => t.id == template.id);
    
    if (existingIndex >= 0) {
      templates[existingIndex] = template;
    } else {
      templates.add(template);
    }
    
    await prefs.setString(
      _templatesKey, 
      jsonEncode(templates.map((t) => t.toJson()).toList())
    );
  }
  
  // Método para obtener todas las plantillas
  Future<List<AdministrationTemplate>> getTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? templatesJson = prefs.getString(_templatesKey);
    
    if (templatesJson == null || templatesJson.isEmpty) {
      return [];
    }
    
    try {
      List<dynamic> decodedList = jsonDecode(templatesJson);
      return decodedList
          .map((item) => AdministrationTemplate.fromJson(item))
          .toList();
    } catch (e) {
      // Si hay un error, retornar una lista vacía
      return [];
    }
  }
  
  // Aplicar una plantilla a una fecha específica
  Future<void> applyTemplate(String templateId, DateTime date) async {
    List<AdministrationTemplate> templates = await getTemplates();
    
    // Buscar la plantilla
    final template = templates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => AdministrationTemplate(
        id: '',
        name: '',
        administrations: [],
      ),
    );
    
    if (template.id.isEmpty) return;
    
    // Aplicar las administraciones de la plantilla
    for (var templateAdmin in template.administrations) {
      // Crear una nueva administración con fecha actual pero mismos datos
      SubstanceAdministration newAdmin = SubstanceAdministration(
        id: _uuid.v4(),
        substanceId: templateAdmin.substanceId,
        date: date,
        dosage: templateAdmin.dosage,
        time: templateAdmin.time,
        route: templateAdmin.route,
      );
      
      await saveAdministration(newAdmin);
    }
  }
  
  // Eliminar una administración
  Future<void> deleteAdministration(String administrationId) async {
    final prefs = await SharedPreferences.getInstance();
    
    List<SubstanceAdministration> administrations = await getAdministrations();
    
    // Filtrar la administración a eliminar
    administrations.removeWhere((a) => a.id == administrationId);
    
    await prefs.setString(
      _administrationsKey, 
      jsonEncode(administrations.map((a) => a.toJson()).toList())
    );
  }
  
  // Crear una nueva sustancia
  Future<PharmacologicalSubstance> createSubstance({
    required String name,
    required String unit,
    required double baseAnabolicPotency,
    required SubstanceCategory category,
    String iconPath = '',
  }) async {
    final newSubstance = PharmacologicalSubstance(
      id: _uuid.v4(),
      name: name,
      unit: unit,
      baseAnabolicPotency: baseAnabolicPotency,
      category: category,
      iconPath: iconPath,
    );
    
    await saveSubstance(newSubstance);
    return newSubstance;
  }
  
  // Crear una nueva administración
  Future<SubstanceAdministration> createAdministration({
    required String substanceId,
    required DateTime date,
    required double dosage,
    TimeOfDay? time,
    AdministrationRoute? route,
  }) async {
    final newAdministration = SubstanceAdministration(
      id: _uuid.v4(),
      substanceId: substanceId,
      date: date,
      dosage: dosage,
      time: time,
      route: route,
    );
    
    await saveAdministration(newAdministration);
    return newAdministration;
  }
  
  // Crear una nueva plantilla
  Future<AdministrationTemplate> createTemplate({
    required String name,
    required List<SubstanceAdministration> administrations,
  }) async {
    final newTemplate = AdministrationTemplate(
      id: _uuid.v4(),
      name: name,
      administrations: administrations,
    );
    
    await saveTemplate(newTemplate);
    return newTemplate;
  }
} 