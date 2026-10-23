import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../agent.dart';
import '../data.dart';
import '../store.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets.dart';
/// Voice-first Мира: pearl orb, living consult, booking only via «Запись».
class AgentVoicePage extends StatefulWidget {
  const AgentVoicePage({super.key, this.active = true});

  /// When embedded in the shell tab, false pauses mic/TTS off-tab.
  final bool active;

  @override
  State<AgentVoicePage> createState() => _AgentVoicePageState();
}

class _AgentVoicePageState extends State<AgentVoicePage>
    with SingleTickerProviderStateMixin {
  final _speech = SpeechToText();
  final _tts = CultTts();
  final _scroll = ScrollController();

  var _listening = false;
  var _speaking = false;
  var _speechReady = false;
  var _speechDenied = false;
  var _booted = false;
  var _busy = false;
  var _partial = '';
  var _status = 'Коснитесь жемчужины — и говорите';

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _syncPulse();
  }

  void _syncPulse() {
    if (!widget.active) {
      if (_pulse.isAnimating) {
        _pulse
          ..stop()
          ..value = 0;
      }
      return;
    }
    final talk = _listening || _speaking;
    final next = Duration(milliseconds: talk ? (_listening ? 900 : 1200) : 2400);
    if (_pulse.duration != next) {
      final v = _pulse.value;
      _pulse
        ..stop()
        ..duration = next
        ..value = v;
    }
    if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_booted || !widget.active) return;
    _booted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.active) return;
      ClinicScope.of(context).markChatRead('bot');
      _boot();
    });
  }

  @override
  void didUpdateWidget(covariant AgentVoicePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncPulse();
    if (oldWidget.active && !widget.active) {
      _pauseSession();
    } else if (!oldWidget.active && widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.active) return;
        if (!_booted) {
          _booted = true;
          ClinicScope.of(context).markChatRead('bot');
          _boot();
        } else {
          setState(() => _status = 'Коснитесь жемчужины — и говорите');
        }
      });
    }
  }

  Future<void> _pauseSession() async {
    try {
      await _speech.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _listening = false;
      _speaking = false;
      _busy = false;
      _partial = '';
      _status = 'Коснитесь жемчужины — и говорите';
    });
    _syncPulse();
  }

  Future<void> _boot() async {
    await _tts.loadKey();
    await _tts.prepare();
    final ok = await _ensureSpeech();
    if (!mounted) return;
    if (!ok) {
      setState(() => _status = 'Нужен доступ к микрофону');
      showCultSnack(
        context,
        'Разрешите Микрофон и «Распознавание речи» в Настройках → CULT.',
      );
      return;
    }
    setState(() {
      _speaking = true;
      _status = 'Отвечаю…';
    });
    _syncPulse();
    await _tts.speak(CultTts.spokenGreeting, complete: true);
    if (!mounted) return;
    setState(() {
      _speaking = false;
      _status = 'Слушаю вас';
    });
    _syncPulse();
    await _startListen(ClinicScope.of(context), auto: true);
  }

  Future<bool> _ensureSpeech() async {
    if (_speechReady) return true;
    try {
      final available = await _speech.initialize(
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _listening = false;
            _speechDenied = true;
            _status = 'Микрофон: ${error.errorMsg}';
          });
        },
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _listening = false);
          }
        },
      );
      if (!mounted) return available;
      setState(() {
        _speechReady = available;
        _speechDenied = !available;
      });
      return available;
    } catch (_) {
      if (mounted) setState(() => _speechDenied = true);
      return false;
    }
  }

  Future<void> _onMainButton(ClinicStore store) async {
    if (_busy) return;
    cultTapFeedback();
    if (_speaking) {
      try {
        await _tts.stop();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _speaking = false;
          _status = 'Коснитесь жемчужины — и говорите';
        });
        _syncPulse();
      }
      return;
    }
    if (_listening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _listening = false;
          _partial = '';
          _status = 'Коснитесь жемчужины — и говорите';
        });
        _syncPulse();
      }
      return;
    }
    await _startListen(store);
  }

  Future<void> _startListen(ClinicStore store, {bool auto = false}) async {
    if (_busy || _speaking) return;
    final available = await _ensureSpeech();
    if (!available) {
      if (mounted) {
        showCultSnack(
          context,
          'Нет доступа к микрофону. Настройки → CULT → Микрофон и речь.',
        );
      }
      return;
    }
    try {
      await _tts.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _listening = true;
      _partial = '';
      _status = auto ? 'Слушаю…' : 'Говорите — жемчужина вас слышит';
    });
    _syncPulse();
    HapticFeedback.mediumImpact();
    await _speech.listen(
      onResult: (result) {
        if (!mounted || _busy) return;
        setState(() => _partial = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _finishUtterance(store, result.recognizedWords.trim());
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: 'ru_RU',
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> _finishUtterance(ClinicStore store, String text) async {
    if (_busy || text.isEmpty) return;
    _busy = true;
    try {
      await _speech.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _listening = false;
      _partial = '';
      _speaking = true;
      _status = 'Думаю…';
    });
    _syncPulse();
    HapticFeedback.selectionClick();
    store.sendMessage('bot', text);
    store.markChatRead('bot');
    final reply = store.threads['bot']?.lastOrNull;
    final line = (reply != null && reply.from == 'them') ? reply.text : '';
    if (!mounted) return;
    setState(() => _status = 'Отвечаю…');
    _syncPulse();
    _scrollToEnd();
    if (line.isNotEmpty) {
      try {
        await _tts.stop();
      } catch (_) {}
      if (!mounted) return;
      await _tts.speak(line, complete: true);
    }
    if (!mounted) return;
    setState(() {
      _speaking = false;
      _status = store.agentBookingDraft != null
          ? 'Проверьте детали и нажмите «Запись»'
          : 'Слушаю вас';
    });
    _syncPulse();
    _busy = false;
    if (store.agentBookingDraft != null) return;
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted || _listening || _speaking) return;
    await _startListen(store, auto: true);
  }

  Future<void> _confirmBooking(ClinicStore store) async {
    if (_busy || store.agentBookingDraft == null) return;
    _busy = true;
    cultTapFeedback();
    try {
      await _speech.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
    final line = store.confirmAgentBooking();
    if (!mounted) return;
    setState(() {
      _speaking = true;
      _status = 'Записываю…';
    });
    _syncPulse();
    HapticFeedback.mediumImpact();
    if (line != null && line.isNotEmpty) {
      await _tts.speak(line, complete: true);
    }
    if (!mounted) return;
    setState(() {
      _speaking = false;
      _status = 'Слушаю вас';
    });
    _syncPulse();
    _busy = false;
    showCultSnack(context, 'Визит в «Мои записи»');
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted || _listening || _speaking) return;
    await _startListen(store, auto: true);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _confirmClear(ClinicStore store) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Очистить разговор?'),
        content: const Text(
          'История с Мирой на этом телефоне сбросится к приветствию.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Оставить'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Очистить', style: TextStyle(color: Cult.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    store.clearChat('bot');
    store.clearAgentBookingDraft();
    setState(() {
      _partial = '';
      _status = 'Коснитесь жемчужины — и говорите';
    });
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech.stop();
    _tts.stop();
    _scroll.dispose();
    super.dispose();
  }

  String? get _heroReply {
    final messages = ClinicScope.of(context).threads['bot'] ?? [];
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].from == 'them') return messages[i].text;
    }
    return null;
  }

  String? get _lastUserLine {
    final messages = ClinicScope.of(context).threads['bot'] ?? [];
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].from == 'me') return messages[i].text;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final messages = store.threads['bot'] ?? [];
    final canClear = messages.any((m) => m.from == 'me');
    final hero = _heroReply ?? contacts.firstWhere((c) => c.id == 'bot').seed;
    final lastUser = _lastUserLine;

    // Embedded above shell bottom nav — no extra SafeArea (that caused Column overflow).
    return Scaffold(
      backgroundColor: const Color(0xFF0C0B0A),
      appBar: AppBar(
        toolbarHeight: 52,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cultAgentName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                letterSpacing: 3.2,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              'Косметолог CULT',
              style: TextStyle(color: Color(0xFFC4B49A), fontSize: 11),
            ),
          ],
        ),
        actions: [
          if (canClear)
            IconButton(
              tooltip: 'Очистить',
              onPressed: () => _confirmClear(store),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final talk = _listening || _speaking;
          final t = _pulse.value;
          final ambient = _listening
              ? 0.62 + t * 0.38
              : (_speaking ? 0.48 + t * 0.3 : 0.2 + t * 0.08);
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, talk ? -0.05 : -0.2),
                radius: talk ? 1.35 : 1.2,
                colors: [
                  Color.lerp(
                    const Color(0xFF2C2418),
                    const Color(0xFF4A3A28),
                    ambient,
                  )!,
                  Color.lerp(
                    const Color(0xFF15120E),
                    const Color(0xFF1C1812),
                    ambient * 0.5,
                  )!,
                  const Color(0xFF0C0B0A),
                ],
                stops: const [0, 0.42, 1],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (store.agentBookingDraft != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: _BookingConfirmBar(
                      draft: store.agentBookingDraft!,
                      onConfirm: () => _confirmBooking(store),
                      onEdit: () {
                        cultTapFeedback();
                        store.clearAgentBookingDraft();
                        setState(
                          () => _status = 'Скажите, что поправить — услугу или время',
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ListView(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
                          children: [
                            if (lastUser != null && lastUser.isNotEmpty) ...[
                              Text(
                                'Вы · $lastUser',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0x88C9BBA5),
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 280),
                              opacity: _speaking ? 1 : 0.94,
                              child: Text(
                                hero,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFF6F0E6),
                                  fontSize: hero.length > 160 ? 15.5 : 18,
                                  height: 1.42,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            if (_partial.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                _partial,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color.lerp(
                                    const Color(0xFFE8D8BE),
                                    const Color(0xFFD4C4A8),
                                    t,
                                  ),
                                  fontSize: 15,
                                  height: 1.35,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Semantics(
                              button: true,
                              label: _listening
                                  ? 'Остановить прослушивание'
                                  : (_speaking
                                      ? 'Остановить речь'
                                      : 'Говорить с Мирой'),
                              child: GestureDetector(
                                onTap: () => _onMainButton(store),
                                child: _PearlOrb(
                                  pulse: t,
                                  listening: _listening,
                                  speaking: _speaking,
                                  size: 168,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Text(
                                _status,
                                key: ValueKey(_status),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _speechDenied
                                      ? const Color(0xFFFFB4A8)
                                      : Color.lerp(
                                          const Color(0xFFC4B49A),
                                          const Color(0xFFE8DCC8),
                                          talk ? t : 0.35,
                                        ),
                                  fontSize: 13,
                                  height: 1.3,
                                  letterSpacing: 0.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Iridescent pearl — idle shimmer; stronger pulse while listening / speaking.
class _PearlOrb extends StatelessWidget {
  const _PearlOrb({
    required this.pulse,
    required this.listening,
    required this.speaking,
    this.size = 168,
  });

  final double pulse;
  final bool listening;
  final bool speaking;
  final double size;

  @override
  Widget build(BuildContext context) {
    final talk = listening || speaking;
    final breath = talk ? 0.08 + pulse * 0.14 : 0.02 + pulse * 0.04;
    final scale = 1 + breath;
    final glow = talk ? 0.35 + pulse * 0.45 : 0.16 + pulse * 0.12;
    final ringSpread = talk ? 28.0 + pulse * 36 : 10.0 + pulse * 8;

    return SizedBox(
      width: size + ringSpread * 1.4,
      height: size + ringSpread * 1.4,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Outer aurora haze — mother-of-pearl glow
          Container(
            width: size + ringSpread * 1.35,
            height: size + ringSpread * 1.35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color.fromRGBO(
                    255,
                    listening ? 236 : 228,
                    speaking ? 210 : 220,
                    glow * 0.5,
                  ),
                  Color.fromRGBO(210, 190, 170, glow * 0.16),
                  Colors.transparent,
                ],
                stops: const [0.2, 0.55, 1],
              ),
            ),
          ),
          // Soft halo ring
          Container(
            width: size + ringSpread * 0.55,
            height: size + ringSpread * 0.55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Color.fromRGBO(255, 248, 240, 0.14 + pulse * 0.22),
                width: talk ? 1.4 : 0.8,
              ),
            ),
          ),
          Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(
                      255,
                      236,
                      210,
                      talk ? 0.32 + pulse * 0.24 : 0.14,
                    ),
                    blurRadius: talk ? 40 + pulse * 20 : 24,
                    spreadRadius: talk ? 2 : 0,
                  ),
                  BoxShadow(
                    color: Color.fromRGBO(20, 14, 10, 0.55),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.42),
                  radius: 1.05,
                  colors: listening
                      ? const [
                          Color(0xFFFFFEFA),
                          Color(0xFFF8F0E6),
                          Color(0xFFE8D4C0),
                          Color(0xFFD0B498),
                          Color(0xFFA88870),
                        ]
                      : speaking
                      ? const [
                          Color(0xFFFFFAF2),
                          Color(0xFFF5E8D4),
                          Color(0xFFE0C8A8),
                          Color(0xFFC4A070),
                          Color(0xFF8A6E48),
                        ]
                      : const [
                          Color(0xFFFFFEFC),
                          Color(0xFFF7F2EC),
                          Color(0xFFE8DCD0),
                          Color(0xFFCDB8A4),
                          Color(0xFF9A8474),
                        ],
                  stops: const [0, 0.22, 0.48, 0.78, 1],
                ),
              ),
              child: Stack(
                children: [
                  // Iridescent mother-of-pearl veil
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Color.fromRGBO(255, 230, 220, 0.0),
                          Color.fromRGBO(210, 235, 245, 0.16 + pulse * 0.1),
                          Color.fromRGBO(255, 236, 200, 0.18),
                          Color.fromRGBO(235, 220, 240, 0.12),
                          Color.fromRGBO(255, 230, 220, 0.0),
                        ],
                        transform: GradientRotation(pulse * 0.9),
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                  // Specular highlight
                  Align(
                    alignment: const Alignment(-0.38, -0.42),
                    child: Container(
                      width: size * 0.38,
                      height: size * 0.28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size),
                        gradient: RadialGradient(
                          colors: [
                            Color.fromRGBO(255, 255, 255, 0.9),
                            Color.fromRGBO(255, 255, 255, 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Soft underside shade
                  Align(
                    alignment: const Alignment(0.15, 0.55),
                    child: Container(
                      width: size * 0.55,
                      height: size * 0.35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size),
                        gradient: RadialGradient(
                          colors: [
                            Color.fromRGBO(70, 50, 35, talk ? 0.2 : 0.14),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingConfirmBar extends StatelessWidget {
  const _BookingConfirmBar({
    required this.draft,
    required this.onConfirm,
    required this.onEdit,
  });

  final AgentBookingDraft draft;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE6282218),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Подтверждение визита',
              style: TextStyle(
                color: Color(0xFFB9A990),
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              draft.summary,
              style: const TextStyle(
                color: Color(0xFFF6F0E6),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: onEdit,
                  child: const Text('Изменить'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE8D4B8),
                    foregroundColor: const Color(0xFF1B1408),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Запись'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
