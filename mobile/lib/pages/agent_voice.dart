import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../agent.dart';
import '../data.dart';
import '../store.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets.dart';
import 'voice_settings.dart';

/// Voice-first CULT Агент: one mic button, no typing, push-style offers.
class AgentVoicePage extends StatefulWidget {
  const AgentVoicePage({super.key});

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
  var _status = 'Нажмите кнопку — говорите';
  List<AgentOffer> _offers = const [];

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_booted) return;
    _booted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ClinicScope.of(context).markChatRead('bot');
      _boot();
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
      _status = 'Говорю…';
    });
    await _tts.speak(CultTts.spokenGreeting, complete: true);
    if (!mounted) return;
    setState(() {
      _speaking = false;
      _status = 'Слушаю — говорите';
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
          _status = 'Нажмите кнопку — говорите';
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
          _status = 'Нажмите кнопку — говорите';
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
      _status = auto ? 'Слушаю…' : 'Слушаю — говорите до конца фразы';
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
      _status = 'Говорю до конца…';
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
      _status = 'Слушаю — говорите';
    });
    _busy = false;
    // Hands-free loop: listen again without typing.
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
        duration: const Duration(milliseconds: 280),
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
      _status = 'Нажмите кнопку — говорите';
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

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final messages = store.threads['bot'] ?? [];
    final canClear = messages.any((m) => m.from == 'me');

    return Scaffold(
      backgroundColor: const Color(0xFF141210),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141210),
        foregroundColor: Colors.white,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CULT Агент',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Одна кнопка · без клавиатуры',
              style: TextStyle(color: Color(0xFFB9A990), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Живой голос',
            onPressed: () {
              cultTapFeedback();
              pushPage(context, const VoiceSettingsPage());
            },
            icon: const Icon(Icons.graphic_eq),
          ),
          if (canClear)
            IconButton(
              tooltip: 'Очистить',
              onPressed: () => _confirmClear(store),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF141210),
              Color(0xFF2A2318),
              Color(0xFF1A1712),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (_offers.isNotEmpty)
                SizedBox(
                  height: 118,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: _offers.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final offer = _offers[index];
                      return _PushOfferCard(
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    if (messages.isEmpty)
                      _VoiceLine(
                        text: contacts.firstWhere((c) => c.id == 'bot').seed,
                        mine: false,
                      ),
                    for (final message in messages.takeLast(12))
                      _VoiceLine(
                        text: message.text,
                        mine: message.from == 'me',
                      ),
                    if (_partial.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _partial,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE8D8BE),
                          fontSize: 16,
                          height: 1.35,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _speechDenied
                        ? const Color(0xFFFFB4A8)
                        : const Color(0xFFD9CBB5),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final active = _listening || _speaking;
                    final scale = active ? 1 + (_pulse.value * 0.06) : 1.0;
                    return Transform.scale(scale: scale, child: child);
                  },
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
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _listening
                                  ? const [
                                      Color(0xFFFED488),
                                      Color(0xFFC4A35A),
                                    ]
                                  : (_speaking
                                      ? const [
                                          Color(0xFFB8955A),
                                          Color(0xFF775A19),
                                        ]
                                      : const [
                                          Color(0xFFE7C98A),
                                          Color(0xFF8A6A2E),
                                        ]),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFED488)
                                    .withValues(alpha: _listening ? 0.45 : 0.2),
                                blurRadius: _listening ? 28 : 16,
                                spreadRadius: _listening ? 2 : 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            _listening
                                ? Icons.stop_rounded
                                : (_speaking
                                    ? Icons.volume_up_rounded
                                    : Icons.mic_rounded),
                            size: 40,
                            color: const Color(0xFF1B1408),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _TakeLast<E> on List<E> {
  Iterable<E> takeLast(int n) => skip(length < n ? 0 : length - n);
}

class _PushOfferCard extends StatelessWidget {
  const _PushOfferCard({
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
      'product' => 'Шоп',
      'infusion' => 'Инфузия',
      _ => 'Услуга',
    };
    return Material(
      color: const Color(0xFF2C261C),
      elevation: 8,
      shadowColor: const Color(0x66000000),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 250,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x55FED488)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x33FED488),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Пуш · $kindLabel',
                      style: const TextStyle(
                        color: Color(0xFFFED488),
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    offer.priceLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                offer.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                offer.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFC9BBA5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Спросить',
                    style: TextStyle(
                      color: Color(0xFFFED488),
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
    );
  }
}

class _VoiceLine extends StatelessWidget {
  const _VoiceLine({required this.text, required this.mine});

  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xFF3A3226)
              : const Color(0xCC1E1A14),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 6),
            bottomRight: Radius.circular(mine ? 6 : 18),
          ),
          border: Border.all(
            color: mine
                ? const Color(0x33FED488)
                : const Color(0x22FFFFFF),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: mine ? const Color(0xFFF6EFE3) : const Color(0xFFEDE4D6),
            height: 1.35,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }
}
