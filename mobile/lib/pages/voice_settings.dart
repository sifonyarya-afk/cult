import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../tts.dart';
import '../widgets.dart';

/// Configure human neural voice (Yandex Alena) for CULT Агент.
class VoiceSettingsPage extends StatefulWidget {
  const VoiceSettingsPage({super.key});

  @override
  State<VoiceSettingsPage> createState() => _VoiceSettingsPageState();
}

class _VoiceSettingsPageState extends State<VoiceSettingsPage> {
  final _key = TextEditingController();
  final _tts = CultTts();
  var _loading = true;
  var _saving = false;
  var _testing = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final key = await CultTts.readKey();
    if (!mounted) return;
    _key.text = key ?? '';
    setState(() {
      _loading = false;
      _status = (key != null && key.isNotEmpty)
          ? 'Нейроголос Alena включён'
          : 'Сейчас системный голос iPhone (может звучать плоско)';
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await CultTts.saveKey(_key.text);
    await _tts.loadKey();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _status = _key.text.trim().isEmpty
          ? 'Ключ удалён — снова системный голос'
          : 'Сохранено. Проверьте кнопкой «Прослушать»';
    });
    HapticFeedback.mediumImpact();
    showCultSnack(context, 'Настройки голоса сохранены');
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _status = 'Синтезирую…';
    });
    await CultTts.saveKey(_key.text);
    await _tts.loadKey();
    try {
      await _tts.speak(
        'Здравствуйте. Я консультант клиники Культ. Говорю спокойно, как живой человек на приёме.',
      );
      if (!mounted) return;
      setState(() {
        _status = _tts.usingNeural ||
                (_tts.selectedVoiceLabel?.toLowerCase().contains('alena') ??
                    false) ||
                (_tts.selectedVoiceLabel?.toLowerCase().contains('neural') ??
                    false)
            ? 'Звучит нейроголос Alena'
            : 'Сыграл запасной голос iPhone (${_tts.selectedVoiceLabel ?? 'системный'})';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Не вышло: $e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Живой голос')),
      body: _loading
          ? const CultLoading(label: 'Голос…')
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Как у человека', style: cultHeadline(28)),
                const SizedBox(height: 8),
                const Text(
                  'Системный голос iPhone часто звучит плоско. '
                  'Для живой русской речи добавьте ключ Yandex SpeechKit — голос Alena. '
                  'Без ключа скачайте Premium Милена в настройках iPhone.',
                  style: TextStyle(color: Cult.muted, height: 1.4),
                ),
                const SizedBox(height: 18),
                const CultSectionLabel('Yandex SpeechKit'),
                const SizedBox(height: 10),
                TextField(
                  controller: _key,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'API-ключ',
                    hintText: 'AQVN…',
                  ),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 12),
                CultButton(
                  label: _saving ? 'Сохраняю…' : 'Сохранить',
                  onPressed: _saving ? null : _save,
                ),
                const SizedBox(height: 8),
                CultButton(
                  label: _testing ? 'Идёт озвучка…' : 'Прослушать тест',
                  onPressed: _testing ? null : _test,
                ),
                if (_status != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _status!,
                    style: const TextStyle(color: Cult.muted, height: 1.35),
                  ),
                ],
                const SizedBox(height: 22),
                const CultSectionLabel('Без ключа — Premium на iPhone'),
                const SizedBox(height: 10),
                const Text(
                  'Настройки → Универсальный доступ → Spoken Content → Голоса → Русский → '
                  'Милена → скачайте Premium или Enhanced. Затем перезапустите CULT.',
                  style: TextStyle(color: Cult.muted, height: 1.4),
                ),
              ],
            ),
    );
  }
}
