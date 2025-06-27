import 'dart:async';
import '../models/timeline_models.dart';

class TimelineService {
  // Streams individuales para cada fuente de eventos
  final StreamController<List<AppEvent>> _agendaController = StreamController<List<AppEvent>>.broadcast();
  final StreamController<List<AppEvent>> _geoController = StreamController<List<AppEvent>>.broadcast();
  final StreamController<List<AppEvent>> _kikiController = StreamController<List<AppEvent>>.broadcast();

  // Stream combinado del timeline
  late final Stream<List<AppEvent>> timelineStream;

  TimelineService() {
    // Combinar todos los streams y ordenar por tiempo
    timelineStream = _combineStreams();
  }

  Stream<List<AppEvent>> _combineStreams() {
    return StreamGroup.merge([
      _agendaController.stream.map((events) => _combineEvents(events, [], [])),
      _geoController.stream.map((events) => _combineEvents([], events, [])),
      _kikiController.stream.map((events) => _combineEvents([], [], events)),
    ]);
  }

  List<AppEvent> _combineEvents(List<AppEvent> agenda, List<AppEvent> geo, List<AppEvent> kiki) {
    final all = [...agenda, ...geo, ...kiki];
    all.sort((a, b) => a.when.compareTo(b.when));
    return all;
  }

  // Métodos para actualizar cada stream
  void updateAgendaEvents(List<AppEvent> events) {
    _agendaController.add(events);
  }

  void updateGeoEvents(List<AppEvent> events) {
    _geoController.add(events);
  }

  void updateKikiEvents(List<AppEvent> events) {
    _kikiController.add(events);
  }

  // Métodos para añadir eventos individuales
  void addAgendaEvent(AppEvent event) {
    // Aquí normalmente consultarías la base de datos actual
    // Por ahora simulamos con datos de prueba
  }

  void addGeoEvent(AppEvent event) {
    // Cálculo de tiempo de salida basado en distancia y velocidad
  }

  void addKikiEvent(AppEvent event) {
    // Eventos generados por el motor de reglas de Kiki
  }

  // Datos de prueba para demostración
  List<AppEvent> getMockEvents() {
    final now = DateTime.now();
    return [
      // Eventos de agenda
      AppEvent.agenda(
        id: '1',
        when: now.add(const Duration(minutes: 30)),
        text: 'Cita con el Dr. Gómez',
        metadata: {'location': 'Clínica Central'},
      ),
      AppEvent.agenda(
        id: '8',
        when: now.add(const Duration(minutes: 90)),
        text: 'Cita con la Dra. Martínez',
        metadata: {'location': 'Hospital General'},
      ),
      AppEvent.agenda(
        id: '9',
        when: now.add(const Duration(minutes: 150)),
        text: 'Cita con el Dr. López',
        metadata: {'location': 'Centro Salud Norte'},
      ),
      
      // Eventos geo
      AppEvent.geo(
        id: '3',
        when: now.add(const Duration(minutes: 15)),
        text: 'Salir hacia el fisio',
        lat: 40.4168,
        lng: -3.7038,
        destination: 'Fisioterapeuta',
      ),
      AppEvent.geo(
        id: '4',
        when: now.add(const Duration(hours: 1, minutes: 30)),
        text: 'Ir al gimnasio',
        lat: 40.4168,
        lng: -3.7038,
        destination: 'Gimnasio Central',
      ),
      
      // Eventos de Kiki
      AppEvent.kiki(
        id: '5',
        when: now.add(const Duration(minutes: 5)),
        text: '¿Has bebido al menos 1L de agua hoy?',
        kikiType: 'hydration_check',
      ),
      AppEvent.kiki(
        id: '6',
        when: now.add(const Duration(minutes: 45)),
        text: 'Hora de tomar tu medicación',
        kikiType: 'medication_reminder',
      ),
      AppEvent.kiki(
        id: '7',
        when: now.add(const Duration(hours: 3)),
        text: 'Tiempo de hacer ejercicio',
        kikiType: 'exercise_reminder',
      ),
    ];
  }

  void dispose() {
    _agendaController.close();
    _geoController.close();
    _kikiController.close();
  }
}

// Clase helper para combinar streams
class StreamGroup {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    return Stream.fromIterable(streams).asyncExpand((stream) => stream);
  }
} 