import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfigService {
  static const String _serverUrlKey = 'server_url';
  
  // URLs predefinidas para diferentes entornos
  static const List<String> _defaultUrls = [
    'http://10.0.2.2:3000',    // Emulador Android estándar
    'http://127.0.0.1:3000',   // Localhost
    'http://localhost:3000',   // Nombre localhost
  ];
  
  static const String _defaultUrl = 'http://10.0.2.2:3000';
  
  // Singleton pattern
  static final ServerConfigService _instance = ServerConfigService._internal();
  factory ServerConfigService() => _instance;
  ServerConfigService._internal();

  String? _cachedUrl;
  SharedPreferences? _prefs;

  /// Inicializa el servicio
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Obtiene la URL del servidor actual
  Future<String> getServerUrl() async {
    if (_cachedUrl != null) return _cachedUrl!;
    
    await _ensureInitialized();
    
    // Intentar obtener URL guardada
    final savedUrl = _prefs!.getString(_serverUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _cachedUrl = savedUrl;
      return savedUrl;
    }
    
    // Usar URL por defecto según el entorno
    final defaultUrl = _getDefaultUrlForEnvironment();
    _cachedUrl = defaultUrl;
    await _saveServerUrl(defaultUrl);
    return defaultUrl;
  }

  /// Guarda la URL del servidor
  Future<void> setServerUrl(String url) async {
    await _ensureInitialized();
    
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;
    
    _cachedUrl = cleanUrl;
    await _saveServerUrl(cleanUrl);
  }

  /// Obtiene todas las URLs disponibles
  List<String> getAvailableUrls() {
    return List.from(_defaultUrls);
  }

  /// Detecta la URL por defecto según el entorno
  String _getDefaultUrlForEnvironment() {
    if (kIsWeb) {
      // En web, usar localhost
      return 'http://127.0.0.1:3000';
    }
    
    if (Platform.isAndroid) {
      // En Android, preferir 10.0.2.2 para emuladores
      return 'http://10.0.2.2:3000';
    }
    
    if (Platform.isIOS) {
      // En iOS, usar localhost
      return 'http://127.0.0.1:3000';
    }
    
    // Fallback
    return _defaultUrl;
  }

  /// Guarda la URL en SharedPreferences
  Future<void> _saveServerUrl(String url) async {
    await _prefs!.setString(_serverUrlKey, url);
  }

  /// Asegura que el servicio esté inicializado
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }

  /// Limpia la caché (útil para testing)
  void clearCache() {
    _cachedUrl = null;
  }

  /// Resetea a la URL por defecto
  Future<void> resetToDefault() async {
    final defaultUrl = _getDefaultUrlForEnvironment();
    await setServerUrl(defaultUrl);
  }

  /// Verifica si la URL actual es válida
  bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene información del entorno actual
  Map<String, dynamic> getEnvironmentInfo() {
    return {
      'isWeb': kIsWeb,
      'isAndroid': Platform.isAndroid,
      'isIOS': Platform.isIOS,
      'isDebug': kDebugMode,
      'defaultUrl': _getDefaultUrlForEnvironment(),
    };
  }
} 