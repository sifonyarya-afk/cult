import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../agent.dart';
import '../data.dart';
import '../store.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets.dart';
/// Voice-first CULT Агент: one mic button, living consultation layout.
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
  var _status = 'Нажмите — и говорите своими словами';
  List<AgentOffer> _offers = const [];

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.active) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else if (_pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
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
          setState(() => _status = 'Нажмите — и говорите своими словами');
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
      _status = 'Нажмите — и говорите своими словами';
    });
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
    await _tts.speak(CultTts.spokenGreeting, complete: true);
    if (!mounted) return;
    setState(() {
      _speaking = false;
      _status = 'Слушаю вас';
    });
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
          _status = 'Нажмите — и говорите своими словами';
        });
      }
      return;
    }
    if (_listening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _listening = false;
          _partial = '';
          _status = 'Нажмите — и говорите своими словами';
        });
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
      _status = auto ? 'Слушаю…' : 'Говорите до конца фразы';
    });
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
    HapticFeedback.selectionClick();
    store.sendMessage('bot', text);
    store.markChatRead('bot');
    final reply = store.threads['bot']?.lastOrNull;
    final line = (reply != null && reply.from == 'them') ? reply.text : '';
    final offers = line.isEmpty
        ? <AgentOffer>[]
        : cultAgent.suggestOffers(
            line,
            lastUser: text,
            localServices: store.catalogServices,
            localProducts: products,
            localInfusions: infusions,
            gender: store.gender,
          );
    if (!mounted) return;
    setState(() {
      _offers = offers;
      _status = 'Отвечаю…';
    });
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
      _status = 'Слушаю вас';
    });
    _busy = false;
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted || _listening || _speaking) return;
    await _startListen(store, auto: true);
  }

  Future<void> _askOffer(ClinicStore store, AgentOffer offer) async {
    if (_busy) return;
    try {
      await _speech.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
    await _finishUtterance(store, offer.ask);
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
          'История с CULT Агентом на этом телефоне сбросится к приветствию.',
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
    setState(() {
      _offers = const [];
      _partial = '';
      _status = 'Нажмите — и говорите своими словами';
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
      backgroundColor: const Color(0xFF100E0C),
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CULT Агент',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Живой разговор',
              style: TextStyle(color: Color(0xFFB9A990), fontSize: 11),
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
          final ambient = _listening
              ? 0.55 + _pulse.value * 0.35
              : (_speaking ? 0.4 + _pulse.value * 0.25 : 0.22);
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.55),
                radius: 1.15,
                colors: [
                  Color.lerp(
                    const Color(0xFF3A2E1C),
                    const Color(0xFF5A4630),
                    ambient,
                  )!,
                  const Color(0xFF1A1510),
                  const Color(0xFF100E0C),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_offers.isNotEmpty)
                  SizedBox(
                    height: 104,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      scrollDirection: Axis.horizontal,
                      itemCount: _offers.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final offer = _offers[index];
                        return _SuggestCard(
                          offer: offer,
                          onTap: () => _askOffer(store, offer),
                          onBook: offer.kind == 'service' ||
                                  offer.kind == 'infusion'
                              ? () {
                                  cultTapFeedback();
                                  _askOffer(
                                    store,
                                    AgentOffer(
                                      title: offer.title,
                                      subtitle: offer.subtitle,
                                      priceLabel: offer.priceLabel,
                                      kind: offer.kind,
                                      ask: 'Запиши меня на ${offer.title}',
                                    ),
                                  );
                                }
                              : null,
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    children: [
                      if (lastUser != null && lastUser.isNotEmpty) ...[
                        Text(
                          'Вы · $lastUser',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0x99C9BBA5),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 280),
                        opacity: _speaking ? 1 : 0.96,
                        child: Text(
                          hero,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFF3EBDD),
                            fontSize: hero.length > 160 ? 16 : 19,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                      if (_partial.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          _partial,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color.lerp(
                              const Color(0xFFE8D8BE),
                              Cult.sand,
                              _pulse.value,
                            ),
                            fontSize: 16,
                            height: 1.35,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (messages.length > 2) ...[
                        const SizedBox(height: 20),
                        ...messages
                            .where((m) => m.from == 'them')
                            .toList()
                            .reversed
                            .skip(1)
                            .take(2)
                            .toList()
                            .reversed
                            .map(
                              (m) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  m.text,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0x66D9CBB5),
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
                  child: AnimatedSwitcher(
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
                            : const Color(0xFFD9CBB5),
                        fontSize: 13,
                        height: 1.3,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: Center(
                    child: Builder(
                      builder: (context) {
                        final active = _listening || _speaking;
                        final scale = active ? 1 + (_pulse.value * 0.06) : 1.0;
                        final ring = active ? 8 + (_pulse.value * 10) : 0.0;
                        return Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            if (active)
                              Container(
                                width: 88 + ring,
                                height: 88 + ring,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Cult.sand.withValues(
                                      alpha: 0.28 + _pulse.value * 0.22,
                                    ),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            Transform.scale(
                              scale: scale,
                              child: Semantics(
                                button: true,
                                label: _listening
                                    ? 'Остановить прослушивание'
                                    : (_speaking
                                        ? 'Остановить речь'
                                        : 'Говорить с CULT Агентом'),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => _onMainButton(store),
                                    child: Ink(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: _listening
                                              ? const [
                                                  Color(0xFFE8D9C0),
                                                  Color(0xFFB9A07A),
                                                ]
                                              : (_speaking
                                                  ? const [
                                                      Color(0xFFC9B496),
                                                      Color(0xFF6E5B43),
                                                    ]
                                                  : const [
                                                      Color(0xFFD7BEA0),
                                                      Color(0xFF8A7355),
                                                    ]),
                                        ),
                                      ),
                                      child: Icon(
                                        _listening
                                            ? Icons.stop_rounded
                                            : (_speaking
                                                ? Icons.volume_up_rounded
                                                : Icons.mic_rounded),
                                        size: 36,
                                        color: const Color(0xFF1B1408),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
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

class _SuggestCard extends StatelessWidget {
  const _SuggestCard({
    required this.offer,
    required this.onTap,
    this.onBook,
  });

  final AgentOffer offer;
  final VoidCallback onTap;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final kindLabel = switch (offer.kind) {
      'product' => 'Из шопа',
      'infusion' => 'Инфузия',
      _ => 'Услуга',
    };
    return Material(
      color: const Color(0xCC241E16),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 228,
          height: 96,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        kindLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB9A990),
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Text(
                      offer.priceLabel,
                      style: const TextStyle(
                        color: Color(0xFFF6EFE3),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  offer.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  offer.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC9BBA5),
                    fontSize: 11,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Рассказать',
                      style: TextStyle(
                        color: Cult.sand,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (onBook != null) ...[
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: onBook,
                        child: const Text(
                          'Запись',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
