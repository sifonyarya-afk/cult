import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On-device + optional Yandex neural speech for CULT Агент.
///
/// System AVSpeech always sounds somewhat synthetic. For a human Russian voice
/// set a Yandex SpeechKit API key (voice «alena») in Settings, or download
/// Apple Premium Milena for the local fallback.
class CultTts {
  CultTts({FlutterTts? engine, AudioPlayer? player})
    : _tts = engine ?? FlutterTts(),
      _player = player ?? AudioPlayer();

  static const prefsKey = 'cult-yandex-tts-key';

  /// Optional compile-time seed: `flutter run --dart-define=CULT_YANDEX_TTS_KEY=…`
  /// Never commit real keys; paste in Settings or pass via dart-define / local file.
  static const envYandexTtsKey = String.fromEnvironment('CULT_YANDEX_TTS_KEY');

  final FlutterTts _tts;
  final AudioPlayer _player;
  var _ready = false;
  var _speakGen = 0;
  String? selectedVoiceLabel;
  String? yandexApiKey;
  var _useNeural = false;
  var _rate = 0.47;
  var _pitch = 1.04;

  bool get usingNeural => _useNeural && (yandexApiKey?.trim().isNotEmpty ?? false);

  Future<void> loadKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(prefsKey)) {
      yandexApiKey = prefs.getString(prefsKey) ?? '';
      return;
    }
    final fromEnv = envYandexTtsKey.trim();
    final fromFile = await _readLocalKeyFile();
    final seed = fromEnv.isNotEmpty ? fromEnv : fromFile;
    if (seed != null && seed.isNotEmpty) {
      yandexApiKey = seed;
      await prefs.setString(prefsKey, seed);
      return;
    }
    yandexApiKey = '';
  }

  /// Gitignored `mobile/.cult_yandex_tts_key` — one line, API key only.
  static Future<String?> _readLocalKeyFile() async {
    try {
      for (final path in [
        '.cult_yandex_tts_key',
        'mobile/.cult_yandex_tts_key',
      ]) {
        final file = File(path);
        if (await file.exists()) {
          final text = (await file.readAsString()).trim();
          if (text.isNotEmpty) return text;
        }
      }
      // App documents / bundle relative — also try alongside temp for simulators.
      final dir = await getTemporaryDirectory();
      final sibling = File('${dir.parent.path}/.cult_yandex_tts_key');
      if (await sibling.exists()) {
        final text = (await sibling.readAsString()).trim();
        if (text.isNotEmpty) return text;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> saveKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    // Empty string disables neural.
    await prefs.setString(prefsKey, key.trim());
  }

  static Future<String?> readKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(prefsKey)) return prefs.getString(prefsKey);
    final fromEnv = envYandexTtsKey.trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    return _readLocalKeyFile();
  }

  Future<void> prepare() async {
    await loadKey();
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
      _rate = 0.46;
      _pitch = 1.03;
    } else if (h.contains('enhanced')) {
      _rate = 0.45;
      _pitch = 1.04;
    } else {
      _rate = 0.42;
      _pitch = 1.07;
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
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await prepare();
    final spoken = toSpokenBrief(humanize(trimmed));
    if (spoken.isEmpty) return;
    final gen = ++_speakGen;

    // Neural Yandex Alena — human Russian voice when key is set.
    final key = yandexApiKey?.trim() ?? '';
    if (key.isNotEmpty) {
      try {
        await _speakYandex(spoken, key, gen);
        if (gen == _speakGen) {
          _useNeural = true;
          selectedVoiceLabel = 'Yandex Alena (neural)';
        }
        return;
      } catch (_) {
        _useNeural = false;
        // Fall through to system voice.
      }
    }

    if (!_ready) return;
    await _speakSystem(spoken, gen);
  }

  Future<void> _speakYandex(String text, String apiKey, int gen) async {
    await _player.stop();
    final uri = Uri.https('tts.api.cloud.yandex.net', '/speech/v1/tts:synthesize');
    final response = await http
        .post(
          uri,
          headers: {'Authorization': 'Api-Key $apiKey'},
          body: {
            'text': text,
            'lang': 'ru-RU',
            'voice': 'alena',
            'emotion': 'good',
            'speed': '0.95',
            'format': 'mp3',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Yandex TTS ${response.statusCode}');
    }
    if (gen != _speakGen) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/cult_tts_$gen.mp3');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    if (gen != _speakGen) return;
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.play(DeviceFileSource(file.path));
    try {
      await _player.onPlayerComplete.first.timeout(const Duration(minutes: 2));
    } catch (_) {}
  }

  Future<void> _speakSystem(String spoken, int gen) async {
    try {
      await _tts.stop();
      await _applyProsody();
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (gen != _speakGen) return;

      // Breath groups with tiny pitch sway — breaks flat “robot” monotone.
      final groups = breathGroups(spoken);
      for (var i = 0; i < groups.length; i++) {
        if (gen != _speakGen) return;
        final sway = (i % 2 == 0) ? 0.025 : -0.02;
        await _tts.setPitch((_pitch + sway).clamp(0.9, 1.2));
        await _tts.setSpeechRate(_rate);
        await _tts.speak(groups[i]);
        if (i < groups.length - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 110));
        }
      }
      await _applyProsody();
    } catch (_) {}
  }

  /// Rewrite stiff clinic copy into spoken Russian.
  static String humanize(String text) {
    var s = text;
    const swaps = <String, String>{
      'Обратите внимание на': 'Посмотрите,',
      'Ориентир по цене —': 'Стоит примерно',
      'Ориентир по цене': 'Цена примерно',
      'По протоколу': 'По процедуре',
      'Точного совпадения в каталоге пока не вижу.':
          'Давайте подберём вместе, без сложных названий.',
      'Хорошо, давайте разберём без каталога.': 'Хорошо, давайте разберёмся.',
      'Я CULT Агент — голосовой консультант клиники.':
          'Я консультант клиники Культ.',
      'окончательное решение по протоколу всегда за очным специалистом':
          'окончательное решение всегда за врачом на приёме',
      'Нажмите «Голос»': 'Нажмите голос',
      'через «+»': 'через плюс на главной',
      'через плюс на главной на главной': 'через плюс на главной',
    };
    for (final e in swaps.entries) {
      s = s.replaceAll(e.key, e.value);
    }
    return s;
  }

  /// Short spoken form for TTS; full reply stays in the chat bubble.
  static String toSpokenBrief(String text) {
    final full = forSpeech(text);
    if (full.length <= 240) return full;
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
      if (buf.isNotEmpty && next.length > 240) break;
      if (buf.isNotEmpty) buf.write(' ');
      buf.write(sentence);
      if (buf.length >= 160 && i >= 1) break;
    }
    var out = buf.toString().trim();
    if (out.isEmpty) out = sentences.first;
    if (!RegExp(r'[.!?…]$').hasMatch(out)) out = '$out.';
    return out;
  }

  /// Split into short breath groups for more human rhythm.
  static List<String> breathGroups(String spoken) {
    final words = spoken.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length <= 10) return [spoken];
    final groups = <String>[];
    var buf = <String>[];
    for (final word in words) {
      buf.add(word);
      final endClause = word.endsWith(',') ||
          word.endsWith(';') ||
          word.endsWith('.') ||
          word.endsWith('!') ||
          word.endsWith('?') ||
          word.endsWith('…');
      if (buf.length >= 9 || (endClause && buf.length >= 5)) {
        groups.add(buf.join(' '));
        buf = [];
      }
    }
    if (buf.isNotEmpty) groups.add(buf.join(' '));
    return groups;
  }

  static String forSpeech(String text) {
    var s = humanize(text);
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
        .replaceAll('«Прайс»', 'прайс')
        .replaceAll('«Магазин»', 'магазин')
        .replaceAll('«Услуги»', 'услуги')
        .replaceAll('«Голос»', 'голос')
        .replaceAll('«+»', 'плюс')
        .replaceAll('«Инфузии»', 'инфузии')
        .replaceAll('«Аппаратная»', 'аппаратная');

    s = s.replaceAllMapped(RegExp(r'\b(\d{1,3})\s(\d{3})\b'), (m) {
      final hi = m.group(1)!;
      final lo = m.group(2)!;
      if (lo == '000') return '$hi тысяч';
      return '$hi тысяч $lo';
    });

    s = s
        .replaceAll(RegExp(r',\s*'), ', ')
        .replaceAll(RegExp(r';\s*'), '; ')
        .replaceAll(RegExp(r'\.\s*'), '. ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (s.isEmpty) return s;
    if (!RegExp(r'[.!?…]$').hasMatch(s)) s = '$s.';
    return s;
  }

  static List<String> speechChunks(String spoken) => breathGroups(spoken);

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
