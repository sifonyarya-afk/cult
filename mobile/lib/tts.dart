import 'package:flutter_tts/flutter_tts.dart';

/// On-device speech for CULT Агент: natural RU voice + speakable copy.
class CultTts {
  CultTts({FlutterTts? engine}) : _tts = engine ?? FlutterTts();

  final FlutterTts _tts;
  var _ready = false;
  String? selectedVoiceLabel;

  Future<void> prepare() async {
    if (_ready) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      try {
        await _tts.setSharedInstance(true);
        await _tts.autoStopSharedSession(false);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          const [
            IosTextToSpeechAudioCategoryOptions.duckOthers,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.allowAirPlay,
          ],
          IosTextToSpeechAudioMode.spokenAudio,
        );
      } catch (_) {}
      await _tts.setLanguage('ru-RU');
      // Premium voices sound most natural near the iOS default.
      await _tts.setSpeechRate(0.50);
      await _tts.setPitch(1.02);
      await _tts.setVolume(1.0);
      try {
        await _tts.setQueueMode(1);
      } catch (_) {}
      selectedVoiceLabel = await _pickHumanVoice();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Prefer Premium / Enhanced Milena by identifier when iOS exposes it.
  Future<String?> _pickHumanVoice() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return null;
      Map<String, String>? best;
      var bestScore = -1;
      for (final entry in raw) {
        if (entry is! Map) continue;
        final voice = <String, String>{
          for (final e in entry.entries) '${e.key}': '${e.value}',
        };
        final score = _voiceScore(voice);
        if (score > bestScore) {
          bestScore = score;
          best = voice;
        }
      }
      if (best == null || bestScore < 1) return null;
      final id = best['identifier']?.trim() ?? '';
      if (id.isNotEmpty) {
        await _tts.setVoice({'identifier': id});
      } else {
        await _tts.setVoice({
          'name': best['name'] ?? 'Milena',
          'locale': best['locale'] ?? 'ru-RU',
        });
      }
      // Re-apply language after voice — some iOS builds reset locale.
      await _tts.setLanguage(best['locale'] ?? 'ru-RU');
      await _tts.setSpeechRate(0.50);
      await _tts.setPitch(1.02);
      final name = best['name'] ?? 'ru-RU';
      final quality = best['quality'] ?? '';
      return quality.isEmpty ? name : '$name ($quality)';
    } catch (_) {
      return null;
    }
  }

  int _voiceScore(Map<String, String> voice) {
    final locale = (voice['locale'] ?? '').toLowerCase();
    final name = (voice['name'] ?? '').toLowerCase();
    final quality = (voice['quality'] ?? '').toLowerCase();
    final gender = (voice['gender'] ?? '').toLowerCase();
    final id = (voice['identifier'] ?? '').toLowerCase();
    if (!locale.contains('ru') && !id.contains('.ru')) return -1;
    var score = 1;
    if (locale.contains('ru-ru') || locale.contains('ru_ru')) score += 2;
    if (id.contains('premium') || quality.contains('premium')) score += 20;
    if (id.contains('enhanced') || quality.contains('enhanced')) score += 12;
    if (name.contains('milena') || id.contains('milena')) score += 8;
    if (gender.contains('female') || name.contains('female')) score += 3;
    if (id.contains('compact') || quality.contains('default')) score -= 2;
    return score;
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await prepare();
    if (!_ready) return;
    final spoken = forSpeech(trimmed);
    if (spoken.isEmpty) return;
    try {
      await _tts.stop();
      // Soft pause before speech — feels less abrupt on iOS.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (spoken.length <= 360) {
        await _tts.speak(spoken);
        return;
      }
      for (final chunk in speechChunks(spoken)) {
        await _tts.speak(chunk);
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
    } catch (_) {}
  }

  /// Flatten punctuation and pronounce English catalog names in Russian.
  static String forSpeech(String text) {
    var s = text;
    for (final entry in _phonetics.entries) {
      s = s.replaceAllMapped(
        RegExp(RegExp.escape(entry.key), caseSensitive: false),
        (_) => entry.value,
      );
    }
    s = s
        .replaceAll('·', ',')
        .replaceAll('—', ',')
        .replaceAll('–', ',')
        .replaceAll('→', ',')
        .replaceAll('«', '')
        .replaceAll('»', '')
        .replaceAll('₽', ' рублей')
        .replaceAll('+', ' плюс ')
        .replaceAll('/', ' ')
        .replaceAll('\n', '. ');

    // UI chrome → spoken Russian.
    s = s
        .replaceAll('меню Прайс', 'раздел прайс')
        .replaceAll('меню «Прайс»', 'раздел прайс')
        .replaceAll('«Прайс»', 'прайс')
        .replaceAll('«Магазин»', 'магазин')
        .replaceAll('«Услуги»', 'услуги')
        .replaceAll('«Голос»', 'голос')
        .replaceAll('«+»', 'плюс')
        .replaceAll('«Инфузии»', 'инфузии')
        .replaceAll('«Аппаратная»', 'аппаратная');

    // 45 000 / 14 200 → «45 тысяч», «14 тысяч 200»
    s = s.replaceAllMapped(RegExp(r'\b(\d{1,3})\s(\d{3})\b'), (m) {
      final hi = m.group(1)!;
      final lo = m.group(2)!;
      if (lo == '000') return '$hi тысяч';
      return '$hi тысяч $lo';
    });

    // Soften dense clauses for Premium TTS pacing.
    s = s
        .replaceAll(RegExp(r',\s*'), ', ')
        .replaceAll(RegExp(r'\.\s*'), '. ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Keep replies speakable — drop a trailing UI essay if huge.
    if (s.length > 520) {
      final cut = s.substring(0, 520);
      final stop = cut.lastIndexOf('. ');
      s = stop > 180 ? cut.substring(0, stop + 1) : '$cut.';
    }

    if (s.isEmpty) return s;
    if (!RegExp(r'[.!?…]$').hasMatch(s)) s = '$s.';
    return s;
  }

  static List<String> speechChunks(String spoken) {
    final parts = spoken
        .split(RegExp(r'(?<=[.!?…])\s+'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (parts.isEmpty) return [spoken];
    final merged = <String>[];
    var buf = '';
    for (final part in parts) {
      if (buf.isEmpty) {
        buf = part;
      } else if (buf.length + part.length < 220) {
        buf = '$buf $part';
      } else {
        merged.add(buf);
        buf = part;
      }
    }
    if (buf.isNotEmpty) merged.add(buf);
    return merged;
  }

  /// Short line spoken on chat open (full seed stays on screen).
  static const spokenGreeting =
      'Здравствуйте. Я рядом, можно просто поговорить. Нажмите голос — внимательно слушаю.';

  static const _phonetics = <String, String>{
    'Veil Peptide Serum': 'Вейл Пептайд Сёрум',
    'Veil Peptide': 'Вейл Пептайд',
    'Mitochondrial Fuel': 'Митохондриал Фьюэл',
    'Lumen Barrier Cream': 'Люмен Барьер Крим',
    'Neuro-Regen IV Serum': 'Нейро Реген ай ви Сёрум',
    'Cellular Catalyst 01': 'Селлулар Каталист ноль один',
    'Cellular Catalyst': 'Селлулар Каталист',
    'Liposomal Gluta-Pure': 'Липосоумол Глута Пьюр',
    'Aura Mineral Mist': 'Аура Минерал Мист',
    'Home Bio-Scan Kit': 'Хоум Био Скан Кит',
    'Circadian Light Panel': 'Циркадиан Лайт Панел',
    'NAD+ Micro-Patch': 'эн эй ди плюс Майкро Патч',
    'NAD+ Energy': 'эн эй ди плюс Энерджи',
    'NAD+': 'эн эй ди плюс',
    'Immunity Boost': 'Имьюнити Буст',
    'Beauty & Glow': 'Бьюти энд Глоу',
    'Beauty and Glow': 'Бьюти энд Глоу',
    'HydraPure': 'Гидра Пьюр',
    'Morpheus8': 'Морфеус восемь',
    'Ultherapy': 'Альтерапи',
    'Lumecca': 'Люмекка',
    'BodyTite': 'Боди Тайт',
    'CULT Агент': 'культ агент',
    'CULT Сочи': 'культ сочи',
    'CULT TV': 'культ ти ви',
    'CULT Guest': 'культ гест',
    'CULT': 'культ',
    'YClients': 'вай клиентс',
    'SMAS': 'смас',
    'IPL': 'ай пи эл',
    'SPF': 'эс пи эф',
    'RF': 'эр эф',
    'IV': 'ай ви',
    'Wi‑Fi': 'вай фай',
    'Wi-Fi': 'вай фай',
    'WiFi': 'вай фай',
  };
}
