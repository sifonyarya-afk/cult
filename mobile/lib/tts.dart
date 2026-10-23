import 'package:flutter_tts/flutter_tts.dart';

/// On-device speech for CULT Агент: natural RU voice + short spoken lines.
class CultTts {
  CultTts({FlutterTts? engine}) : _tts = engine ?? FlutterTts();

  final FlutterTts _tts;
  var _ready = false;
  var _speakGen = 0;
  String? selectedVoiceLabel;
  var _rate = 0.49;
  var _pitch = 1.03;

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
      await _tts.setVolume(1.0);
      try {
        await _tts.setQueueMode(1);
      } catch (_) {}
      selectedVoiceLabel = await _pickHumanVoice();
      await _applyProsody();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> _applyProsody() async {
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(_pitch);
  }

  /// Prefer Premium / Enhanced Milena — try known Apple ids first.
  Future<String?> _pickHumanVoice() async {
    const preferredIds = <String>[
      'com.apple.voice.premium.ru-RU.Milena',
      'com.apple.ttsbundle.Milena-premium',
      'com.apple.voice.enhanced.ru-RU.Milena',
      'com.apple.ttsbundle.Milena-enhanced',
      'com.apple.voice.compact.ru-RU.Milena',
      'com.apple.ttsbundle.Milena-compact',
    ];
    for (final id in preferredIds) {
      try {
        final ok = await _tts.setVoice({'identifier': id});
        if (ok == 1) {
          _tuneForQuality(id);
          await _tts.setLanguage('ru-RU');
          return id.contains('premium')
              ? 'Milena (premium)'
              : id.contains('enhanced')
              ? 'Milena (enhanced)'
              : 'Milena';
        }
      } catch (_) {}
    }

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
        _tuneForQuality('$id ${best['quality']}');
      } else {
        await _tts.setVoice({
          'name': best['name'] ?? 'Milena',
          'locale': best['locale'] ?? 'ru-RU',
        });
        _tuneForQuality(best['quality'] ?? '');
      }
      await _tts.setLanguage(best['locale'] ?? 'ru-RU');
      final name = best['name'] ?? 'ru-RU';
      final quality = best['quality'] ?? '';
      return quality.isEmpty ? name : '$name ($quality)';
    } catch (_) {
      return null;
    }
  }

  void _tuneForQuality(String hint) {
    final h = hint.toLowerCase();
    if (h.contains('premium')) {
      // Premium carries emotion best a touch under default speed.
      _rate = 0.48;
      _pitch = 1.02;
    } else if (h.contains('enhanced')) {
      _rate = 0.47;
      _pitch = 1.03;
    } else {
      // Compact: slightly slower + warmer pitch reads less robotic.
      _rate = 0.44;
      _pitch = 1.06;
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
    _speakGen++;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await prepare();
    if (!_ready) return;
    final spoken = toSpokenBrief(trimmed);
    if (spoken.isEmpty) return;
    final gen = ++_speakGen;
    try {
      await _tts.stop();
      await _applyProsody();
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (gen != _speakGen) return;

      // Prefer one calm utterance — sounds like a person, not a slideshow.
      if (spoken.length <= 300) {
        await _tts.speak(spoken);
        return;
      }
      for (final chunk in speechChunks(spoken)) {
        if (gen != _speakGen) return;
        await _tts.speak(chunk);
        await Future<void>.delayed(const Duration(milliseconds: 140));
      }
    } catch (_) {}
  }

  /// Short spoken form for TTS; full reply stays in the chat bubble.
  static String toSpokenBrief(String text) {
    final full = forSpeech(text);
    if (full.length <= 280) return full;
    final sentences = full
        .split(RegExp(r'(?<=[.!?…])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (sentences.isEmpty) return full;
    final buf = StringBuffer();
    for (var i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final next = buf.isEmpty ? sentence : '$buf $sentence';
      if (buf.isNotEmpty && next.length > 280) break;
      if (buf.isNotEmpty) buf.write(' ');
      buf.write(sentence);
      if (buf.length >= 200 && i >= 1) break;
    }
    var out = buf.toString().trim();
    if (out.isEmpty) out = sentences.first;
    if (!RegExp(r'[.!?…]$').hasMatch(out)) out = '$out.';
    return out;
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
        .replaceAll('—', ', ')
        .replaceAll('–', ', ')
        .replaceAll('→', ', ')
        .replaceAll('«', '')
        .replaceAll('»', '')
        .replaceAll('₽', ' рублей')
        .replaceAll('+', ' плюс ')
        .replaceAll('/', ' ')
        .replaceAll('\n', '. ');

    s = s
        .replaceAll('меню Прайс', 'раздел прайс')
        .replaceAll('меню «Прайс»', 'раздел прайс')
        .replaceAll('«Прайс»', 'прайс')
        .replaceAll('Прайс', 'прайс')
        .replaceAll('«Магазин»', 'магазин')
        .replaceAll('«Услуги»', 'услуги')
        .replaceAll('«Голос»', 'голос')
        .replaceAll('«+»', 'плюс')
        .replaceAll('«Инфузии»', 'инфузии')
        .replaceAll('«Аппаратная»', 'аппаратная')
        .replaceAll('«Врачи»', 'врачи')
        .replaceAll('«Мои записи»', 'мои записи');

    // 45 000 / 14 200 → «45 тысяч» / «14 тысяч 200» — Premium reads this smoothly.
    s = s.replaceAllMapped(RegExp(r'\b(\d{1,3})\s(\d{3})\b'), (m) {
      final hi = m.group(1)!;
      final lo = m.group(2)!;
      if (lo == '000') return '$hi тысяч';
      return '$hi тысяч $lo';
    });

    // Breath-friendly pauses after clauses.
    s = s
        .replaceAll(RegExp(r',\s*'), ', ')
        .replaceAll(RegExp(r';\s*'), '; ')
        .replaceAll(RegExp(r'\.\s*'), '. ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Soften stacked questions / exclamations for TTS.
    s = s.replaceAll('?.', '?').replaceAll('!.', '!');

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
      } else if (buf.length + part.length < 180) {
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
      'Здравствуйте. Я рядом. Нажмите голос — спокойно вас слушаю.';

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
    'AlethiaPro': 'Алетиа Про',
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
