import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KikiVoice {
  static final FlutterTts _tts = FlutterTts();

  static Future<void> speak(String text) async {
    if (await _existeBloqueoAhora()) return;
    await _tts.setLanguage("es-ES");
    await _tts.setPitch(1);
    await _tts.setSpeechRate(0.9);
    await _tts.speak(text);
  }

  static Future<void> saludaSiInactivo(Duration inactividad) async {
    await Future.delayed(inactividad);
    await speak("¿Estás por ahí? Puedo ayudarte con tu agenda o recordarte algo 🌟");
  }

  static Future<void> motivarCada(Duration intervalo) async {
    Timer.periodic(intervalo, (timer) async {
      await speak("Recuerda que tú puedes con todo 💪 ¿Quieres que revise tu día?");
    });
  }

  static Future<void> rutinaProactivaDiaria() async {
    if (await _existeBloqueoAhora()) return;
    final ahora = DateTime.now();
    final hora = ahora.hour;

    if (hora == 10) {
      await speak("¿Has bebido suficiente agua esta mañana? 💧");
    } else if (hora == 13) {
      await speak("¿Tienes hambre? Puedo ayudarte a recordar si tienes algo en tu agenda a mediodía 🍽️");
    } else if (hora == 14) {
      await _verificarComidaRegistrada();
    } else if (hora == 17) {
      await speak("¿Tienes plan para moverte un poco esta tarde? 🏃‍♀️ No olvides cuidarte.");
    } else if (hora == 20) {
      await speak("¿Quieres repasar tu día y ver qué lograste hoy? 📝");
    }

    await _analizarAgenda();
    await _detectarHabitosPerdidos();
  }

  static Future<void> _analizarAgenda() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = inicio.add(const Duration(days: 1));

    final eventos = await FirebaseFirestore.instance
      .collection("users").doc(uid).collection("events")
      .where("start", isGreaterThanOrEqualTo: inicio.toIso8601String())
      .where("start", isLessThan: fin.toIso8601String())
      .get();

    if (eventos.docs.isEmpty) {
      await speak("📭 Hoy no tienes nada en tu agenda. ¿Quieres que apunte algo?");
    } else {
      final tieneGym = eventos.docs.any((e) => e["title"].toString().toLowerCase().contains("gym") || e["title"].toString().toLowerCase().contains("entrenamiento"));
      if (!tieneGym && hoy.hour > 15) {
        await speak("Hoy no veo ningún entrenamiento en tu día 🏋️ ¿Quieres que lo agendemos?");
      }
    }
  }

  static Future<void> _verificarComidaRegistrada() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = inicio.add(const Duration(days: 1));

    final interacciones = await FirebaseFirestore.instance
      .collection("users").doc(uid).collection("interactions")
      .where("createdAt", isGreaterThanOrEqualTo: inicio.toIso8601String())
      .where("createdAt", isLessThan: fin.toIso8601String())
      .get();

    final mencionComida = interacciones.docs.any((doc) =>
      doc["input"].toString().toLowerCase().contains("comí") ||
      doc["input"].toString().toLowerCase().contains("he comido") ||
      doc["input"].toString().toLowerCase().contains("desayuné") ||
      doc["input"].toString().toLowerCase().contains("almorcé")
    );

    if (!mencionComida) {
      await speak("🍴 No me has dicho aún qué has comido hoy. ¿Quieres apuntarlo?");
    }
  }

  static Future<void> _detectarHabitosPerdidos() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final hoy = DateTime.now();

    final cafeMatutino = await FirebaseFirestore.instance
      .collection("users").doc(uid).collection("interactions")
      .where("createdAt", isGreaterThanOrEqualTo: hoy.subtract(const Duration(days: 7)).toIso8601String())
      .get();

    final habitual = cafeMatutino.docs.where((d) => d["input"].toLowerCase().contains("café con leche") &&
      DateTime.parse(d["createdAt"]).hour >= 7 && DateTime.parse(d["createdAt"]).hour <= 10);

    final hoyCafe = cafeMatutino.docs.any((d) =>
      d["input"].toLowerCase().contains("café con leche") &&
      DateTime.parse(d["createdAt"]).day == hoy.day);

    if (habitual.length >= 4 && !hoyCafe && hoy.hour >= 11) {
      await speak("☕ Normalmente tomas café con leche por la mañana. ¿Hoy no te apetecía?");
    }
  }

  static void activarRutinaProactiva() {
    Timer.periodic(const Duration(hours: 1), (timer) async {
      await rutinaProactivaDiaria();
    });
  }

  static Future<bool> _existeBloqueoAhora() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;
    try {
      final now = DateTime.now().toIso8601String();
      final snapshot = await FirebaseFirestore.instance
          .collection('users/$userId/events')
          .where('tipo', isEqualTo: 'bloqueo')
          .where('start', isLessThanOrEqualTo: now)
          .where('end', isGreaterThanOrEqualTo: now)
          .orderBy('end')
          .orderBy('start')
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (e.toString().contains('failed-precondition')) {
        await KikiVoice.speak("Estoy preparando todo para ayudarte. Intenta en unos segundos.");
      } else {
        await KikiVoice.speak("Tuve un problema al revisar eso. Intenta de nuevo.");
      }
      return false;
    }
  }
} 