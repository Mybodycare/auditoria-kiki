import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
// ignore: unused_import
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../helpers/embeddings_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Intencion {
  final String nombre;
  final List<String> keywords;
  final List<RegExp> patrones;
  final List<String> entidades;
  final String respuesta;

  Intencion({
    required this.nombre,
    required this.keywords,
    required this.patrones,
    required this.entidades,
    required this.respuesta,
  });
}

class KikiBrain {
  // Datos integrados de Manolita - EXPANDIDO
  static final Map<String, Map<String, dynamic>> frases = {
    "agua": {
      "input": [
        "he bebido agua", "he tomado agua", "he bebido un vaso de agua", "bebí agua", "he ingerido agua",
        "acabo de beber agua", "voy a beber agua", "tienes que recordarme beber agua", "cuánta agua llevo hoy",
        "me puedes decir si he bebido suficiente agua", "he tomado un vaso de agua", "he bebido 500ml de agua"
      ],
      "respuesta": [
        "Perfecto, lo anoto. Bien hidratada.",
        "Muy bien, mantenerse hidratada es clave.",
        "Lo apunto, agua registrada 💧",
        "¡Excelente! Cada vaso cuenta para tu hidratación.",
        "Agua anotada. ¡Sigue así! 💧",
        "Perfecto, agua registrada. ¿Quieres que te recuerde beber más en una hora?"
      ]
    },
    "comida": {
      "input": [
        "me he comido una ensalada", "he comido pasta con atún", "he tomado un yogur con cereales",
        "he comido arroz con pollo", "me he tomado un yogur", "cuánto he comido hoy",
        "apunta que he desayunado huevos", "he tomado proteína", "cuánta proteína llevo hoy",
        "registra que he comido", "me puedes recordar no tomar lácteos", "he comido pescado",
        "he tomado un batido de proteínas", "he comido fruta", "he tomado un sándwich"
      ],
      "respuesta": [
        "¡Buena elección! ¿Llevaba algo más? 🥗",
        "Pasta registrada, ¡energía en marcha! 🍝",
        "Yogur con cereales, ¡perfecto para mantener el ritmo! 🥣",
        "Anotado: %s. ¿Te apunto las calorías?",
        "¡Perfecto! %s registrado en tu historial nutricional.",
        "¡Buena elección! %s anotado. ¿Quieres que calcule las proteínas?",
        "Comida registrada: %s. ¡Sigue así! 🍽️"
      ]
    },
    "habitos": {
      "input": [
        "me he tomado el colágeno", "me he puesto la medicación", "he bebido agua",
        "hoy me he puesto crema", "recuérdame tomar el colágeno", "he hecho todos mis hábitos hoy",
        "ponme un recordatorio para mi suplemento", "me he tomado las vitaminas", "he hecho estiramientos"
      ],
      "respuesta": [
        "Colágeno registrado, ¡a cuidar esas articulaciones! 💪",
        "Medicación anotada. ¡Bien hecho por seguir tu tratamiento! 💊",
        "¡Bien hidratado! Cada vaso cuenta. 💠",
        "%s registrado. Te recuerdo %s cada día a las %s.",
        "Has completado %s de %s hábitos hoy. ¡Sigue así!",
        "Te apunto ese hábito como pendiente. ¿A qué hora quieres el recordatorio?"
      ]
    },
    "cafeina": {
      "input_prefix": [
        "he tomado", "me he tomado", "me he bebido", "he bebido", "me he metido",
        "acabo de tomar", "voy a tomar", "cuánta cafeína llevo hoy", "recuerda que no puedo tomar mucha cafeína"
      ],
      "productos": [
        "un café", "un cortado", "un descafeinado", "un café solo", "un carajillo",
        "un capuchino", "un café con leche", "un red bull", "una coca-cola", "una pepsi",
        "un monster", "un guaraná", "un mate", "un té verde", "un té negro", "un té matcha",
        "una bebida energética", "una pastilla de cafeína", "un chocolate negro", "un chocolate con leche",
        "un cacao puro", "un batido con café", "un nespresso", "un espresso", "una cápsula de café",
        "una lata de burn", "un shot de cafeína", "una bebida preentreno", "un cold brew", "un café americano"
      ],
      "respuesta": [
        "%s anotado. El chute viene en 20 minutos ⚡",
        "%s registrado. ¡Ahora sí que estás a tope! 💥",
        "Perfecto, %s en el cuerpo. ¡A despegar en breve! 🚀",
        "Hecho. %s cargado. Vamos con todo 💪",
        "%s contado. Recuerda hidratarte también. 💧",
        "Manolita al tanto: %s sumado. 🧠",
        "¡Booom! %s en camino. Dale caña. 🔋",
        "Cuenta con ello. %s en tu sistema. 🔥",
        "Llevas %s mg de cafeína hoy. ¡Cuidado con el límite!"
      ]
    },
    "entrenamiento": {
      "alias": ["he entrenado", "he hecho", "he ido a", "me he pegado", "he practicado", "he realizado",
                "acabo de hacer", "he hecho pierna", "he entrenado fuerza", "he ido a correr"],
      "actividades": {
        "fuerza": ["bíceps", "tríceps", "espalda", "pecho", "piernas", "hombros", "remo", "jalón", "prensa de piernas", "peso muerto", "sentadillas", "dominadas", "flexiones", "burpees"],
        "cardio": ["correr", "caminar", "andar", "trote", "bici", "spinning", "elíptica", "step", "subir escaleras", "bailar", "cinta", "jumping jacks"],
        "outdoor": ["senderismo", "paddle", "natación", "kayak", "escalada", "esquí", "snowboard", "patinaje", "surf", "trekking", "canicross"],
        "otros": ["zumba", "body pump", "crossfit", "pilates", "yoga", "hiit", "tabata"]
      },
      "respuesta": [
        "¡Entreno registrado! 💪",
        "¡Eso cuenta como cardio potente! 🏃‍♂️",
        "¡Manolita lo ha anotado! Sigue así 🧠📊",
        "¡Buen trabajo! Lo apunto todo en tu historial 📈",
        "¡Así se hace! Sigue sumando esfuerzo 👊",
        "%s con %s repeticiones registrado. ¡Excelente trabajo!",
        "Hoy llevas %s entrenos. ¡A por más!",
        "Esta semana llevas %s entrenos. ¡Increíble constancia!"
      ]
    },
    "motivacion": {
      "input": ["motívame", "necesito un empujón", "dime algo bueno", "dame ánimos para entrenar", "algún consejo hoy"],
      "respuesta": [
        "¡Vamos, que si no lo haces tú, no lo va a hacer nadie! 💪",
        "¡Dale caña! Cada paso cuenta, ¡no te frenes! 🔥",
        "¡Hoy es tu día! ¡Con todo! No dejes que el sofá te venza. 😎",
        "¡Lo estás haciendo fenomenal! ¡Adelante! 🎯",
        "¡Eres imparable! ¡Sigue adelante! 💫",
        "¡Vamos, que tú puedes! 🚀",
        "¡Hoy lo petas, máquina! 💪",
        "Cada paso cuenta, ¡ánimo! 🔥",
        "¡A por todas, valiente! ⚡",
        "Recuerda: ¡la constancia es la clave! 🎯"
      ]
    },
    "agenda": {
      "input_prefix": [
        "tengo una reunión con", "tengo una cita con", "he quedado para tomar", "he quedado para comer",
        "he quedado con", "cena con", "comida con", "añade reunión con", "qué tengo hoy en la agenda",
        "a qué hora es mi próxima cita", "me puedes recordar la cena"
      ],
      "productos": [
        "Becky G", "mi coach", "mi terapeuta", "el dentista", "el nutricionista", "mi amiga Laura",
        "unos amigos", "mis padres", "mi pareja", "mi hermana", "mi jefe", "el médico", "el fisio"
      ],
      "respuesta": [
        "%s anotado en tu agenda. ¡Todo bajo control! 🗓️",
        "Agenda actualizada: %s. No se te pasará. ⏰",
        "He registrado: %s. Ya lo tienes cubierto. ✅",
        "Vale, %s queda en tu calendario. ✨",
        "%s apuntado. ¡No se te escapará! 🧠",
        "Hoy tienes: %s. ¿Te lo recuerdo antes?",
        "Próxima cita: %s. ¡Todo listo!"
      ]
    },
    "destinos": {
      "input_prefix": [
        "tengo que ir a", "llévame a", "quiero ir a", "necesito llegar a", "cuánto tardo en llegar a",
        "quiero saber cómo llegar a", "avísame cuándo tengo que salir para", "dónde está el"
      ],
      "productos": [
        "la farmacia", "el gimnasio", "el trabajo", "mi casa", "el centro comercial",
        "la universidad", "el hospital", "la consulta", "la playa", "el parque", "la estación",
        "el aeropuerto", "la casa de Laura", "el supermercado", "el médico", "el dentista"
      ],
      "respuesta": [
        "Vale, buscando ruta a %s 🔍🚗",
        "Te llevo a %s. Asegúrate de estar listo/a. 🚌",
        "Preparando direcciones hacia %s 🗺️",
        "He marcado %s como destino. Vamos allá. 🚜",
        "Listo, %s en marcha. ¡Buen viaje! 🚊",
        "Tardas %s minutos en llegar a %s. ¿Quieres aviso de salida?",
        "El %s más cercano está a %s. ¿Te preparo la ruta?"
      ]
    },
    "alarma": {
      "input": ["ponme una alarma", "despiértame a las", "alarma para las", "necesito despertarme a"],
      "respuesta": [
        "Listo, alarma para las %s. ¡Que descanses! ⏰",
        "Alarma configurada para las %s. ¡Dulces sueños! 😴",
        "¡Perfecto! Te despierto a las %s. 💤",
        "Alarma lista para las %s. ¡A dormir! 🌙"
      ]
    },
    "temporizador": {
      "input": ["ponme un temporizador", "temporizador de", "cuenta atrás de", "necesito un timer de"],
      "respuesta": [
        "Temporizador de %s listo. ¡A contar! ⏱️",
        "¡Perfecto! Timer de %s iniciado. ⏰",
        "Cuenta atrás de %s activada. ¡Vamos! 🔥",
        "Temporizador configurado: %s. ¡Listo! ⏲️"
      ]
    },
    "recordatorio": {
      "input": ["recuérdame", "ponme un recordatorio", "no me olvides", "avísame cuando"],
      "respuesta": [
        "Anotado: recordatorio para %s a las %s. ✅",
        "¡Perfecto! Te recuerdo %s a las %s. 📝",
        "Recordatorio configurado: %s. ¡No se te escapará! 🧠",
        "¡Listo! Te aviso para %s. ¡Confía en mí! 💪"
      ]
    },
    "llamada": {
      "input": ["llama a", "llámame con", "quiero llamar a", "necesito hablar con"],
      "respuesta": [
        "Llamando a %s. 📞",
        "¡Perfecto! Conectando con %s. 📱",
        "Iniciando llamada a %s. ¡Hola! 👋",
        "Llamada a %s en curso. 📞"
      ]
    },
    "mensaje": {
      "input": ["envía un mensaje a", "escribe a", "mándale un mensaje a", "texto para"],
      "respuesta": [
        "Mensaje a %s: «%s», enviado. 📱",
        "¡Perfecto! Mensaje enviado a %s. ✅",
        "Texto enviado a %s. ¡Listo! 📤",
        "Mensaje entregado a %s. ¡Comunicación activa! 💬"
      ]
    },
    "clima": {
      "input": ["qué tiempo va a hacer", "va a llover hoy", "clima mañana", "temperatura"],
      "respuesta": [
        "Mañana en %s: %s. ¿Te preparo ropa? 🌤️",
        "Hoy va a %s. ¡Llévate paraguas si sales! ☔",
        "Clima para %s: %s. ¡Perfecto para salir! 🌞",
        "Temperatura en %s: %s. ¡A disfrutar! 🌡️"
      ]
    },
    "timeline": {
      "input": ["qué he hecho hoy", "qué tomé ayer", "muéstrame mi historial", "resumen de mi día"],
      "respuesta": [
        "Hoy has hecho: %s. ¡Buen trabajo! 📊",
        "Ayer tomaste: %s. ¡Sigue así! 📈",
        "Tu historial: %s. ¡Increíble progreso! 🎯",
        "Resumen del día: %s. ¡Excelente! 🌟"
      ]
    },
    "ayuda": {
      "input": ["qué puedo pedirte", "ayúdame", "no encuentro", "esto no funciona", "cómo apunto"],
      "respuesta": [
        "¡Tranqui! Puedo ayudarte con: agua, comida, entrenos, agenda, alarmas, clima y más. ¿Qué necesitas? 🤖",
        "¡Claro! Te ayudo con: hidratación, nutrición, ejercicio, citas, recordatorios... ¡Dímelo! 💪",
        "¡Sin problema! Puedo registrar: hábitos, comidas, entrenos, citas, y darte motivación. ¿Qué quieres? 🚀",
        "¡Aquí estoy! Te ayudo con todo: agua, cafeína, ejercicio, agenda, clima... ¡Dime qué necesitas! ✨"
      ]
    },
    "errores": {
      "respuesta": [
        "Hmm, eso no lo tengo en mis registros. Pero no te preocupes, ¡yo soy Manolita! Puedo ayudarte a buscar más detalles.",
        "¡Vaya! No encontré eso en mis archivos. Pero no te preocupes, soy tu asistente personal. ¿Me dejas investigar?",
        "Lo siento, no tengo datos exactos para eso, pero puedo estimarlo. ¿Te gustaría que lo haga? ¡Soy bastante buena con los números!",
        "No encontré los detalles exactos, pero puedo ayudarte a calcular algo aproximado. ¡Lo importante es que estemos en sintonía!",
        "¡Tranqui! Vamos otra vez, dime el detalle. 🤔",
        "Si algo no sale, lo miramos juntas. ¿Quieres que lo busque por ti? 🔍",
        "Eso… aún no lo tengo, pero sigo aprendiendo. ¡Prueba con otra cosa! 📚"
      ]
    }
  };

  static final Map<String, Map<String, List<String>>> multilang = {
    "desconocido": {
      "es": [
        "No estoy segura de qué hacer con eso, pero lo estoy aprendiendo 🤔",
        "Interesante... lo anoto para aprender 💡",
        "Lo guardaré para procesarlo mejor más tarde."
      ]
    }
  };

  // Memoria temporal (en una app real, esto se guardaría en Firebase)
  static final Map<String, List<String>> memoria = {};
  static final Map<String, dynamic> aprendidos = {};

  static final List<Intencion> INTENCIONES = [
    Intencion(
      nombre: "agua",
      keywords: ["agua", "vaso", "botella", "beber", "tomar", "hidratar", "he bebido", "me he tomado"],
      patrones: [RegExp(r"(beber|tomar|hidratar).*(agua|vaso|botella)")],
      entidades: ["cantidad"],
      respuesta: "Perfecto, agua anotada. ¿Te apunto la cantidad?",
    ),
    Intencion(
      nombre: "comida",
      keywords: ["comida", "comer", "cenar", "desayunar", "merendar", "plato", "he comido", "he tomado"],
      patrones: [RegExp(r"(he|voy a|acabo de)?.*(comido|tomado|desayunado|cenado|merendado).*(\\w+)")],
      entidades: ["comida", "cantidad"],
      respuesta: "Comida registrada. ¿Quieres que te apunte las calorías?",
    ),
    Intencion(
      nombre: "cafeina",
      keywords: ["café", "té", "red bull", "monster", "mate", "guaraná", "chocolate", "energética"],
      patrones: [RegExp(r"(he|me he|voy a|quiero).*(tomado|bebido|ingerido|metido).*(café|té|red bull|monster|energética|mate|guaraná|chocolate)")],
      entidades: ["producto", "cantidad"],
      respuesta: "{producto} anotado. ¿Quieres registrar la cantidad?",
    ),
    Intencion(
      nombre: "ejercicio",
      keywords: ["entrenar", "ejercicio", "fuerza", "cardio", "correr", "yoga", "pilates", "sentadillas", "burpees", "he entrenado", "he hecho"],
      patrones: [RegExp(r"(he|me he|voy a|acabo de).*(entrenado|hecho|realizado|practicado|ido a|pegado).*(\\w+)")],
      entidades: ["actividad", "repeticiones", "duración"],
      respuesta: "¡Entreno registrado! ¿Te apunto el tiempo o las repeticiones?",
    ),
    Intencion(
      nombre: "cita",
      keywords: ["cita", "reunión", "evento", "he quedado", "comida", "cena", "cumpleaños", "consulta", "tengo", "poner", "registrar", "programar", "crear", "cancelar", "añadir"],
      patrones: [RegExp(r"((tengo|ponme|apúntame|añade|he quedado|programa|crea|registra).*(cita|reunión|evento|comida|cena|desayuno|consulta|cumpleaños))")],
      entidades: ["persona", "fecha", "hora"],
      respuesta: "Evento registrado en tu agenda. ¿Quieres que te avise antes?",
    ),
    // ...añade el resto de intenciones siguiendo el mismo formato...
  ];

  static String normalizar(String texto) {
    texto = texto.toLowerCase().trim();
    texto = texto
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[.,;:!?¿¡]'), '');
    return texto;
  }

  // 1. Patrón flexible para "citas" (día + hora + persona + ubicación)
  static final RegExp _patronCitaFull = RegExp(
    r'(cita|reunión|comida|cena|almuerzo|desayuno)\s*(para|el|tengo|tengo\s+una)?\s*(lunes|martes|miércoles|jueves|viernes|sábado|domingo|mañana|hoy|mañana)?\s*(?:a\s*las\s*|a\s*)?(\d{1,2})(?:[:h](\d{2})?)?\s*(?:con)?\s*(.+?)(?:\s+en\s+(.+))?$',
    caseSensitive: false,
    unicode: true,
  );

  // 2. Patrón específico para detectar ubicaciones
  static final RegExp _patronUbicacion = RegExp(
    r'en\s+(.+?)(?:\s+en\s+(.+))?$',
    caseSensitive: false,
    unicode: true,
  );

  // 3. Patrón para detectar personas
  static final RegExp _patronPersona = RegExp(
    r'con\s+(.+?)(?:\s+en\s+|$)',
    caseSensitive: false,
    unicode: true,
  );

  static Future<String> detectarIntencionAvanzada(String texto) async {
    texto = normalizar(texto);

    // --- PRIORIDAD 1: Detectar citas con ubicaciones (geo) ---
    if (_patronCitaFull.hasMatch(texto) || _patronUbicacion.hasMatch(texto)) {
      // Verificar si contiene ubicación específica
      final ubicacionMatch = _patronUbicacion.firstMatch(texto);
      if (ubicacionMatch != null) {
        return "cita_geo"; // Nueva intención para citas geolocalizadas
      }
      return "cita";
    }

    // --- PRIORIDAD 2: Detectar citas simples sin ubicación ---
    if (texto.contains("cita") || texto.contains("reunión") || 
        (texto.contains("comida") && texto.contains("con")) ||
        (texto.contains("cena") && texto.contains("con"))) {
      return "cita";
    }

    // 1. Intento local (keywords, regex, fuzzy, etc.)
    for (final intencion in INTENCIONES) {
      if (intencion.keywords.any((kw) => texto.contains(kw))) {
        for (final patron in intencion.patrones) {
          if (patron.hasMatch(texto)) {
            return intencion.nombre;
          }
        }
        return intencion.nombre;
      }
    }

    // 2. Si no hay match claro, usa embeddings
    double maxScore = 0.0;
    String? mejorIntencion;
    for (final intencion in INTENCIONES) {
      for (final ejemplo in intencion.keywords) {
        final sim = await EmbeddingsHelper.obtenerSimilitud(texto, ejemplo);
        if (sim.score > maxScore) {
          maxScore = sim.score;
          mejorIntencion = intencion.nombre;
        }
      }
    }
    if (maxScore > 0.75 && mejorIntencion != null) {
      return mejorIntencion;
    }
    return "desconocida";
  }

  static Future<String> respuestaPorIntencion(String intencion, [Map<String, String>? entidades, String? texto]) async {
    if (intencion == "cita_geo" && texto != null) {
      // Extraer información completa de la cita geolocalizada
      String ubicacion = _extraerUbicacionCompleta(texto);
      String persona = _extraerPersonaCompleta(texto);
      final citaMatch = _patronCitaFull.firstMatch(texto);
      
      String dia = "hoy";
      String hora = "12:00";
      
      if (citaMatch != null) {
        dia = citaMatch.group(3) ?? "hoy";
        final horaStr = citaMatch.group(4);
        final minStr = citaMatch.group(5);
        if (horaStr != null) {
          hora = horaStr + (minStr?.isNotEmpty == true ? ":$minStr" : ":00");
        }
        // Si no encontramos persona con el patrón específico, usar el grupo 6
        if (persona.isEmpty) {
          persona = citaMatch.group(6)?.trim() ?? "alguien";
        }
      }
      
      // Si no encontramos ubicación con el patrón específico, buscar "en" en el texto
      if (ubicacion.isEmpty) {
        final enIndex = texto.indexOf(" en ");
        if (enIndex != -1) {
          ubicacion = texto.substring(enIndex + 4).trim();
        }
      }
      
      // Guardar como evento geo en Firebase
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final eventId = const Uuid().v4();
        final now = DateTime.now();
        
        // Parsear fecha
        DateTime fechaEvento = now;
        if (dia == "domingo") {
          fechaEvento = _nextWeekdayDateTime(DateTime.sunday);
        } else if (dia == "lunes") {
          fechaEvento = _nextWeekdayDateTime(DateTime.monday);
        } else if (dia == "martes") {
          fechaEvento = _nextWeekdayDateTime(DateTime.tuesday);
        } else if (dia == "miércoles") {
          fechaEvento = _nextWeekdayDateTime(DateTime.wednesday);
        } else if (dia == "jueves") {
          fechaEvento = _nextWeekdayDateTime(DateTime.thursday);
        } else if (dia == "viernes") {
          fechaEvento = _nextWeekdayDateTime(DateTime.friday);
        } else if (dia == "sábado") {
          fechaEvento = _nextWeekdayDateTime(DateTime.saturday);
        } else if (dia == "mañana") {
          fechaEvento = now.add(const Duration(days: 1));
        }
        
        // Parsear hora
        final partesHora = hora.split(":");
        final horaInt = int.tryParse(partesHora[0]) ?? 12;
        final minInt = int.tryParse(partesHora[1]) ?? 0;
        fechaEvento = DateTime(fechaEvento.year, fechaEvento.month, fechaEvento.day, horaInt, minInt);
        
        await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('events').doc(eventId).set({
            'id': eventId,
            'start': fechaEvento.toIso8601String(),
            'tipo': 'geo',
            'title': 'Comida con $persona',
            'placeName': ubicacion,
            'lat': 0.0, // Se puede geocodificar después
            'lng': 0.0,
            'createdAt': now.toIso8601String(),
          });
      }
      
      return "¡Perfecto! He guardado tu cita geolocalizada: $dia a las $hora con $persona en $ubicacion. 📍";
    }
    
    if (intencion == "cita" && texto != null && _patronCitaFull.hasMatch(texto)) {
      final m = _patronCitaFull.firstMatch(texto)!;
      final dia   = m.group(3) ?? "hoy";
      final hora  = m.group(4)! + (m.group(5)?.isNotEmpty == true ? ":" + m.group(5)! : ":00");
      final conQuien = m.group(6)!.trim();
      return "Cita anotada: $dia a las $hora con $conQuien. ¿Te aviso antes?";
    }
    final obj = INTENCIONES.firstWhere((i) => i.nombre == intencion, orElse: () => Intencion(
      nombre: "desconocida",
      keywords: [],
      patrones: [],
      entidades: [],
      respuesta: "No lo entendí, ¿me lo dices de otra forma?",
    ));
    String resp = obj.respuesta;
    entidades?.forEach((k, v) {
      resp = resp.replaceAll('{$k}', v);
    });
    return resp;
  }

  static String aclaracionPorIntencion(String intencion) {
    switch (intencion) {
      case "agua":
        return "¿Cuánta agua te apunto?";
      case "comida":
        return "¿Qué plato te apunto?";
      case "alarma":
        return "¿A qué hora pongo la alarma?";
      case "cita":
        return "¿Con quién es la cita?";
      default:
        return "¿Me puedes dar más detalles?";
    }
  }

  static Future<String> responder(String input) async {
    final intencion = await detectarIntencionAvanzada(input);
    if (intencion == "desconocida") {
      return "Eso no lo pillo bien, ¿me lo explicas de otra forma?";
    }
    return await respuestaPorIntencion(intencion, null, input);
  }

  // Utilidades
  static String limpiarInput(String texto) {
    // Normalizar caracteres especiales
    texto = texto.toLowerCase().trim();
    // Remover acentos básicos
    texto = texto
        .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
        .replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('ñ', 'n');
    return texto;
  }

  static String obtenerRespuestaAleatoria(List<String> respuestas) {
    final random = Random();
    return respuestas[random.nextInt(respuestas.length)];
  }

  // Métodos de detección - NUEVOS
  // ignore: unused_element
  static String _detectarAlarma(String texto) {
    final inputs = frases["alarma"]!["input"] as List<String>;
    for (String input in inputs) {
      if (texto.contains(limpiarInput(input))) {
        // Extraer hora
        final horaRegExp = RegExp(r'(\d{1,2})[:h](\d{0,2})');
        final match = horaRegExp.firstMatch(texto);
        if (match != null) {
          final hora = match.group(1);
          final min = match.group(2)!.isEmpty ? '00' : match.group(2);
          return "$hora:$min";
        }
      }
    }
    return "";
  }

  // ignore: unused_element
  static String _detectarTemporizador(String texto) {
    final inputs = frases["temporizador"]!["input"] as List<String>;
    for (String input in inputs) {
      if (texto.contains(limpiarInput(input))) {
        // Extraer duración
        final duracionRegExp = RegExp(r'(\d+)\s*(minutos?|horas?|segundos?)');
        final match = duracionRegExp.firstMatch(texto);
        if (match != null) {
          return "${match.group(1)} ${match.group(2)}";
        }
      }
    }
    return "";
  }

  // ignore: unused_element
  static String _detectarRecordatorio(String texto) {
    final inputs = frases["recordatorio"]!["input"] as List<String>;
    for (String input in inputs) {
      if (texto.contains(limpiarInput(input))) {
        // Extraer acción y hora
        final accionRegExp = RegExp(r'recuérdame\s+(.+?)\s+(?:a las|para las|cuando)');
        final match = accionRegExp.firstMatch(texto);
        if (match != null) {
          return match.group(1) ?? "algo";
        }
      }
    }
    return "";
  }

  // ignore: unused_element
  static String _detectarLlamada(String texto) {
    final inputs = frases["llamada"]!["input"] as List<String>;
    for (String input in inputs) {
      if (texto.contains(limpiarInput(input))) {
        // Extraer contacto
        final contactoRegExp = RegExp(r'llama a\s+(.+)');
        final match = contactoRegExp.firstMatch(texto);
        if (match != null) {
          return match.group(1) ?? "alguien";
        }
      }
    }
    return "";
  }

  // ignore: unused_element
  static String _detectarMensaje(String texto) {
    final inputs = frases["mensaje"]!["input"] as List<String>;
    for (String input in inputs) {
      if (texto.contains(limpiarInput(input))) {
        // Extraer destinatario y mensaje
        final mensajeRegExp = RegExp(r'(?:envía|escribe|mándale)\s+(?:un\s+)?mensaje\s+a\s+(.+?)\s+(?:que dice|diciendo|:)');
        final match = mensajeRegExp.firstMatch(texto);
        if (match != null) {
          return match.group(1) ?? "alguien";
        }
      }
    }
    return "";
  }

  // ignore: unused_element
  static bool _detectarClima(String texto) {
    final inputs = frases["clima"]!["input"] as List<String>;
    return inputs.any((input) => texto.contains(limpiarInput(input)));
  }

  // ignore: unused_element
  static bool _detectarTimeline(String texto) {
    final inputs = frases["timeline"]!["input"] as List<String>;
    return inputs.any((input) => texto.contains(limpiarInput(input)));
  }

  // ignore: unused_element
  static bool _detectarAyuda(String texto) {
    final inputs = frases["ayuda"]!["input"] as List<String>;
    return inputs.any((input) => texto.contains(limpiarInput(input)));
  }

  // Métodos de detección - EXISTENTES (expandidos)
  // ignore: unused_element
  static bool _detectarAgua(String texto) {
    final inputs = frases["agua"]!["input"] as List<String>;
    return inputs.any((input) => texto.contains(limpiarInput(input)));
  }

  // ignore: unused_element
  static String _detectarCafeina(String texto) {
    final prefix = frases["cafeina"]!["input_prefix"] as List<String>;
    final productos = frases["cafeina"]!["productos"] as List<String>;
    
    for (String pref in prefix) {
      for (String producto in productos) {
        if (texto.contains(limpiarInput(pref)) && texto.contains(limpiarInput(producto))) {
          return producto;
        }
      }
    }
    return "";
  }

  // ignore: unused_element
  static String _detectarEntrenamiento(String texto) {
    final alias = frases["entrenamiento"]!["alias"] as List<String>;
    final actividades = frases["entrenamiento"]!["actividades"] as Map<String, List<String>>;
    
    for (String al in alias) {
      for (String categoria in actividades.keys) {
        for (String actividad in actividades[categoria]!) {
          if (texto.contains(limpiarInput(al)) && texto.contains(limpiarInput(actividad))) {
            return "$categoria: $actividad";
          }
        }
      }
    }
    return "";
  }

  // ignore: unused_element
  static String _detectarAgenda(String texto) {
    final prefix = frases["agenda"]!["input_prefix"] as List<String>;
    final productos = frases["agenda"]!["productos"] as List<String>;
    
    for (String pref in prefix) {
      for (String producto in productos) {
        if (texto.contains(limpiarInput(pref)) && texto.contains(limpiarInput(producto))) {
          return producto;
        }
      }
    }
    return "";
  }

  // ignore: unused_element
  static String _detectarDestino(String texto) {
    final prefix = frases["destinos"]!["input_prefix"] as List<String>;
    final productos = frases["destinos"]!["productos"] as List<String>;
    
    for (String pref in prefix) {
      for (String producto in productos) {
        if (texto.contains(limpiarInput(pref)) && texto.contains(limpiarInput(producto))) {
          return producto;
        }
      }
    }
    return "";
  }

  // ignore: unused_element
  static bool _detectarHabitos(String texto) {
    final inputs = frases["habitos"]!["input"] as List<String>;
    return inputs.any((input) => texto.contains(limpiarInput(input)));
  }

  // ignore: unused_element
  static bool _detectarComida(String texto) {
    final inputs = frases["comida"]!["input"] as List<String>;
    return inputs.any((input) => texto.contains(limpiarInput(input)));
  }

  // ignore: unused_element
  static bool _detectarMotivacion(String texto) {
    final inputs = frases["motivacion"]!["input"] as List<String>;
    return inputs.any((input) => texto.contains(limpiarInput(input)));
  }

  // Métodos de registro en Firebase - NUEVOS
  // ignore: unused_element
  static Future<void> _registrarAlarma(String uid, String hora) async {
    final id = const Uuid().v4();
    await FirebaseFirestore.instance
      .collection("users").doc(uid).collection("events").doc(id).set({
        "id": id,
        "start": DateTime.now().toIso8601String(),
        "tipo": "alarma",
        "title": "Alarma: $hora",
        "createdAt": DateTime.now().toIso8601String(),
      });
  }

  // ignore: unused_element
  static Future<void> _registrarTemporizador(String uid, String duracion) async {
    final id = const Uuid().v4();
    await FirebaseFirestore.instance
      .collection("users").doc(uid).collection("events").doc(id).set({
        "id": id,
        "start": DateTime.now().toIso8601String(),
        "tipo": "temporizador",
        "title": "Temporizador: $duracion",
        "createdAt": DateTime.now().toIso8601String(),
      });
  }

  // ignore: unused_element
  static Future<void> _registrarRecordatorio(String uid, String accion) async {
    final id = const Uuid().v4();
    await FirebaseFirestore.instance
      .collection("users").doc(uid).collection("events").doc(id).set({
        "id": id,
        "start": DateTime.now().toIso8601String(),
        "tipo": "recordatorio",
        "title": "Recordatorio: $accion",
        "createdAt": DateTime.now().toIso8601String(),
      });
  }

  // ignore: unused_element
  static Future<String> _obtenerHistorial(String uid) async {
    try {
      final hoy = DateTime.now();
      final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
      
      final snapshot = await FirebaseFirestore.instance
        .collection("users").doc(uid).collection("events")
        .where("start", isGreaterThanOrEqualTo: inicioDia.toIso8601String())
        .orderBy("start", descending: true)
        .limit(10)
        .get();

      if (snapshot.docs.isEmpty) {
        return "Nada registrado hoy aún. ¡Empieza a hacer cosas!";
      }

      final eventos = snapshot.docs.map((doc) => doc.data()["title"] as String).toList();
      return eventos.take(5).join(", ");
    } catch (e) {
      return "No pude obtener tu historial, pero sigue así!";
    }
  }

  // Métodos de registro en Firebase - EXISTENTES
  // ignore: unused_element
  static Future<void> _registrarAgua(String uid) async {
    final id = const Uuid().v4();
    await FirebaseFirestore.instance
      .collection("users").doc(uid).collection("events").doc(id).set({
        "id": id,
        "start": DateTime.now().toIso8601String(),
        "tipo": "agua",
        "title": "Agua consumida",
        "createdAt": DateTime.now().toIso8601String(),
      });
  }

  // ignore: unused_element
  static Future<void> _registrarCafeina(String uid, String producto) async {
    final id = const Uuid().v4();
    await FirebaseFirestore.instance
      .collection("users").doc(uid).collection("events").doc(id).set({
        "id": id,
        "start": DateTime.now().toIso8601String(),
        "tipo": "cafeina",
        "title": "Cafeína: $producto",
        "createdAt": DateTime.now().toIso8601String(),
      });
  }

  // ignore: unused_element
  static Future<void> _registrarEntrenamiento(String uid, String actividad) async {
    final id = const Uuid().v4();
    await FirebaseFirestore.instance
      .collection("users").doc(uid).collection("events").doc(id).set({
        "id": id,
        "start": DateTime.now().toIso8601String(),
        "tipo": "entrenamiento",
        "title": "Entrenamiento: $actividad",
        "createdAt": DateTime.now().toIso8601String(),
      });
  }

  // ignore: unused_element
  static Future<void> _registrarAgenda(String uid, String evento) async {
    final id = const Uuid().v4();
    await FirebaseFirestore.instance
      .collection("users").doc(uid).collection("events").doc(id).set({
        "id": id,
        "start": DateTime.now().toIso8601String(),
        "tipo": "agenda",
        "title": "Agenda: $evento",
        "createdAt": DateTime.now().toIso8601String(),
      });
  }

  // ignore: unused_element
  static Future<void> _registrarHabito(String uid, String habito) async {
    final id = const Uuid().v4();
    await FirebaseFirestore.instance
      .collection("users").doc(uid).collection("events").doc(id).set({
        "id": id,
        "start": DateTime.now().toIso8601String(),
        "tipo": "habito",
        "title": "Hábito: $habito",
        "createdAt": DateTime.now().toIso8601String(),
      });
  }

  // ignore: unused_element
  static Future<void> _registrarComida(String uid, String comida) async {
    final id = const Uuid().v4();
    await FirebaseFirestore.instance
      .collection("users").doc(uid).collection("events").doc(id).set({
        "id": id,
        "start": DateTime.now().toIso8601String(),
        "tipo": "comida",
        "title": "Comida: $comida",
        "createdAt": DateTime.now().toIso8601String(),
      });
  }

  // Métodos originales para citas
  // ignore: unused_element
  static String _extraerDia(String texto) {
    final hoy = DateTime.now();
    if (texto.contains("mañana")) return DateFormat('yyyy-MM-dd').format(hoy.add(Duration(days: 1)));
    if (texto.contains("viernes")) return _nextWeekday(DateTime.friday);
    if (texto.contains("jueves")) return _nextWeekday(DateTime.thursday);
    if (texto.contains("lunes")) return _nextWeekday(DateTime.monday);
    if (texto.contains("martes")) return _nextWeekday(DateTime.tuesday);
    if (texto.contains("miércoles")) return _nextWeekday(DateTime.wednesday);
    if (texto.contains("sábado")) return _nextWeekday(DateTime.saturday);
    if (texto.contains("domingo")) return _nextWeekday(DateTime.sunday);
    return "";
  }

  // ignore: unused_element
  static String _extraerHora(String texto) {
    final horaRegExp = RegExp(r'(\d{1,2})[:h](\d{0,2})');
    final match = horaRegExp.firstMatch(texto);
    if (match != null) {
      final hora = match.group(1);
      final min = match.group(2)!.isEmpty ? '00' : match.group(2);
      return "$hora:$min";
    }
    return "";
  }

  // ignore: unused_element
  static String _extraerPersona(String texto) {
    final conIndex = texto.indexOf("con ");
    if (conIndex != -1) {
      return texto.substring(conIndex + 4).split(" ")[0];
    }
    return "";
  }

  // ignore: unused_element
  static DateTime _parsearFechaHora(String diaISO, String horaStr) {
    final fecha = DateTime.parse(diaISO);
    final partes = horaStr.split(":");
    return DateTime(fecha.year, fecha.month, fecha.day, int.parse(partes[0]), int.parse(partes[1]));
  }

  // ignore: unused_element
  static String _nextWeekday(int weekday) {
    DateTime fecha = DateTime.now();
    while (fecha.weekday != weekday) {
      fecha = fecha.add(Duration(days: 1));
    }
    return DateFormat('yyyy-MM-dd').format(fecha);
  }

  // Helper para obtener el próximo día de la semana como DateTime
  static DateTime _nextWeekdayDateTime(int weekday) {
    DateTime fecha = DateTime.now();
    while (fecha.weekday != weekday) {
      fecha = fecha.add(const Duration(days: 1));
    }
    return fecha;
  }

  // Helper para extraer ubicación completa
  static String _extraerUbicacionCompleta(String texto) {
    final ubicacionMatch = _patronUbicacion.firstMatch(texto);
    if (ubicacionMatch != null) {
      String ubicacion = ubicacionMatch.group(1)?.trim() ?? "";
      String ubicacionSecundaria = ubicacionMatch.group(2)?.trim() ?? "";
      
      if (ubicacionSecundaria.isNotEmpty) {
        return "$ubicacion, $ubicacionSecundaria";
      }
      return ubicacion;
    }
    return "";
  }

  // Helper para extraer persona completa
  static String _extraerPersonaCompleta(String texto) {
    final personaMatch = _patronPersona.firstMatch(texto);
    if (personaMatch != null) {
      return personaMatch.group(1)?.trim() ?? "";
    }
    return "";
  }

  // Función de test para verificar la detección
  static Future<void> testDeteccionCita() async {
    final testCases = [
      "Domingo tengo una comida con Isaac Bonfill en la calle Montseny en Castellcir",
      "Tengo una cita con María en el centro comercial",
      "Comida con Juan en el restaurante italiano",
      "Reunión con el equipo en la oficina",
      "Cena con Ana en Barcelona",
    ];
    
    for (final testCase in testCases) {
      final intencion = await detectarIntencionAvanzada(testCase);
      print("Test: '$testCase' -> Intención: $intencion");
    }
  }
} 