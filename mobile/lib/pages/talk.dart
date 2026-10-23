import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';
import '../tts.dart';
import '../widgets.dart';
import '../yclients.dart';
import 'agent_voice.dart';
import 'cabinet.dart';
import 'voice_settings.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  IconData _iconFor(String id) => switch (id) {
    'specialist' => Icons.medical_services_outlined,
    'bot' => Icons.smart_toy_outlined,
    _ => Icons.support_agent_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('Центр поддержки', style: cultHeadline(30)),
        const SizedBox(height: 6),
        const Text(
          'Сначала CULT Агент (голос), затем администратор и врач.',
          style: TextStyle(color: Cult.muted),
        ),
        const SizedBox(height: 4),
        Text(
          'Сборка $cultBuildTag',
          style: const TextStyle(color: Cult.muted, fontSize: 11),
        ),
        if (store.hasUnreadChat) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                cultTapFeedback();
                store.markAllChatsRead();
                showCultSnack(context, 'Все чаты прочитаны');
              },
              child: const Text('Отметить все прочитанными'),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Semantics(
          button: true,
          label: 'CULT Агент голосом',
          child: Material(
            color: Cult.ink,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                cultTapFeedback();
                pushPage(context, const AgentVoicePage());
              },
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    Icon(Icons.mic, color: Colors.white, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CULT Агент',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Живой разговор — одна кнопка, без клавиатуры',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final contact in contacts.where((c) => c.id != 'bot'))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Semantics(
              button: true,
              label: '${contact.name}, ${contact.role}',
              hint: 'Удерживайте, чтобы скопировать',
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  cultTapFeedback();
                  pushPage(context, ChatThreadPage(contactId: contact.id));
                },
                onLongPress: () {
                  Clipboard.setData(
                    ClipboardData(text: '${contact.name} · ${contact.role}'),
                  );
                  cultTapFeedback();
                  showCultSnack(context, 'Контакт скопирован');
                },
                child: CultCard(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EFEA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_iconFor(contact.id), color: Cult.ink),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(contact.name, style: cultHeadline(20)),
                            Text(
                              contact.role,
                              style: const TextStyle(
                                color: Cult.muted,
                                fontSize: 13,
                              ),
                            ),
                            Builder(
                              builder: (_) {
                                final thread = store.threads[contact.id] ?? [];
                                final last = thread.isEmpty
                                    ? null
                                    : thread.last;
                                final preview = last?.text ?? contact.seed;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Cult.muted.withValues(alpha: 0.95),
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (store.isChatUnread(contact.id))
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                color: Cult.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          const Icon(Icons.chevron_right, color: Cult.muted),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        const CultSectionLabel('Альтернативная поддержка'),
        const SizedBox(height: 8),
        CultCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SupportLink(
                title: 'CULT Агент · одна кнопка',
                onTap: () => pushPage(context, const AgentVoicePage()),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _SupportLink(
                title: 'Экстренные протоколы',
                onTap: () =>
                    pushPage(context, const ChatThreadPage(contactId: 'admin')),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _SupportLink(
                title: 'Позвонить в клинику',
                onTap: () => openExternal(
                  'tel:+74950000007',
                  context: context,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportLink extends StatelessWidget {
  const _SupportLink({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        cultTapFeedback();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Cult.muted),
          ],
        ),
      ),
    );
  }
}

class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({super.key, required this.contactId});

  final String contactId;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _speech = SpeechToText();
  final _tts = CultTts();
  var _markedRead = false;
  var _listening = false;
  var _speechReady = false;
  var _speechDenied = false;
  var _speakReplies = true;
  var _bootedVoice = false;

  bool get _isAgent => widget.contactId == 'bot';

  static const _quick = <String>[
    'Сколько стоит RF',
    'Есть Mitochondrial Fuel',
    'Состав Veil Peptide',
    'Хочу записаться',
    'Часы работы',
    'Как добраться',
    'Бонусы',
    'Сертификат',
    'Трансфер',
    'Парковка',
    'Анализы',
    'Скидки',
    'Аппаратная',
    'Инфузии',
    'Массаж',
    'Доставка',
    'Лазер',
    'Эпиляция',
    'Мезотерапия',
    'Постакне',
    'Купероз',
    'Реабилитация',
    'Противопоказания',
    'Рассрочка',
    'Оплата',
    'Телефон клиники',
    'Подготовка к визиту',
    'Документы',
    'Аллергия',
    'Длительность',
    'Солнце',
    'Спорт',
    'Алкоголь',
    'Натощак',
    'Опоздание',
    'Что надеть',
    'Предоплата',
    'Активировать сертификат',
    'Блог CULT TV',
    'Кейсы',
    'Команда врачей',
    'ИИ-подбор',
    'Состав средств',
    'Голосом',
  ];

  static const _followUp = <String>[
    'Подготовка к визиту',
    'Оплата',
    'Телефон клиники',
    'Аллергия',
    'Солнце',
    'Предоплата',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bot uses AgentVoicePage — no classic chat voice boot here.
    if (_isAgent) return;
    if (_markedRead) return;
    _markedRead = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = ClinicScope.of(context);
      store.markChatRead(widget.contactId);
    });
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
          });
          showCultSnack(context, 'Микрофон: ${error.errorMsg}');
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

  Future<void> _bootAgentVoice() async {
    if (!_isAgent || _bootedVoice) return;
    _bootedVoice = true;
    await _tts.loadKey();
    await _tts.prepare();
    // Asks iOS for Microphone + Speech Recognition as soon as the chat opens.
    final ok = await _ensureSpeech();
    if (!mounted) return;
    if (!ok) {
      showCultSnack(
        context,
        'Разрешите Микрофон и «Распознавание речи» в Настройках → CULT.',
      );
    }
    final hasNeural = _tts.yandexApiKey?.trim().isNotEmpty ?? false;
    final voice = (_tts.selectedVoiceLabel ?? '').toLowerCase();
    final softSystem = !hasNeural &&
        !voice.contains('premium') &&
        !voice.contains('enhanced') &&
        !voice.contains('alena');
    if (softSystem) {
      showCultSnack(
        context,
        'Чтобы голос был как у человека: Профиль → Живой голос агента',
      );
    }
    if (_speakReplies) {
      // Short spoken line — full seed stays as text in the bubble.
      await _speak(CultTts.spokenGreeting);
    }
  }

  Future<void> _speak(
    String text, {
    bool tight = false,
    bool force = false,
  }) async {
    // Mic turns always get a spoken reply; the speaker toggle only gates text sends.
    if (!_isAgent || text.trim().isEmpty) return;
    if (!_speakReplies && !force) return;
    if (!mounted) return;
    await _tts.speak(text, tight: tight);
  }

  Future<void> _toggleListen(ClinicStore store) async {
    if (!_isAgent) return;
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    try {
      await _tts.stop();
    } catch (_) {}
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
    if (mounted) setState(() => _listening = true);
    HapticFeedback.mediumImpact();
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        _text.value = TextEditingValue(
          text: result.recognizedWords,
          selection: TextSelection.collapsed(
            offset: result.recognizedWords.length,
          ),
        );
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          setState(() => _listening = false);
          _send(store, result.recognizedWords, fromVoice: true);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: 'ru_RU',
        // Longer window so the user can finish a full phrase.
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(ClinicStore store, String raw, {bool fromVoice = false}) {
    final text = raw.trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    store.sendMessage(widget.contactId, text);
    store.markChatRead(widget.contactId);
    _text.clear();
    if (_isAgent && (_speakReplies || fromVoice)) {
      final reply = store.threads[widget.contactId]?.lastOrNull;
      if (reply != null && reply.from == 'them') {
        // Cut previous utterance so replies don't overlap on fast turns.
        final line = reply.text;
        final tight = fromVoice;
        () async {
          try {
            await _tts.stop();
          } catch (_) {}
          if (!mounted) return;
          await _speak(line, tight: tight, force: fromVoice);
        }();
      }
    }
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
        title: const Text('Очистить переписку?'),
        content: const Text(
          'История сообщений на этом телефоне будет сброшена к приветствию.',
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
    store.clearChat(widget.contactId);
    HapticFeedback.mediumImpact();
    showCultSnack(context, 'Переписка очищена');
  }

  IconData _iconFor(String id) => switch (id) {
    'specialist' => Icons.medical_services_outlined,
    'bot' => Icons.smart_toy_outlined,
    _ => Icons.support_agent_outlined,
  };

  @override
  Widget build(BuildContext context) {
    // Voice-first surface — distinct from admin/doctor chat threads.
    if (_isAgent) return const AgentVoicePage();

    final store = ClinicScope.of(context);
    final contact = contacts.firstWhere((item) => item.id == widget.contactId);
    final messages = store.threads[widget.contactId] ?? [];
    final canClear = messages.any((m) => m.from == 'me');
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(contact.name),
            Text(
              contact.role,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Cult.muted,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          if (_isAgent)
            IconButton(
              tooltip: _speakReplies
                  ? 'Ответы голосом включены'
                  : 'Ответы голосом выключены',
              onPressed: () async {
                cultTapFeedback();
                final next = !_speakReplies;
                setState(() => _speakReplies = next);
                if (!next) {
                  try {
                    await _tts.stop();
                  } catch (_) {}
                }
                if (!mounted) return;
                showCultSnack(
                  context,
                  next ? 'Ответы буду проговаривать' : 'Только текст',
                );
              },
              icon: Icon(
                _speakReplies
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
              ),
            ),
          if (messages.isNotEmpty)
            IconButton(
              tooltip: 'Скопировать переписку',
              onPressed: () {
                final text = store.chatTranscript(widget.contactId);
                if (text.isEmpty) return;
                Clipboard.setData(ClipboardData(text: text));
                cultTapFeedback();
                showCultSnack(context, 'Переписка скопирована');
              },
              icon: const Icon(Icons.copy_outlined),
            ),
          if (canClear)
            IconButton(
              tooltip: 'Очистить переписку',
              onPressed: () => _confirmClear(store),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isAgent)
            Material(
              color: _listening
                  ? Cult.gold.withValues(alpha: 0.45)
                  : (_speechDenied
                        ? const Color(0xFFF8E8E6)
                        : const Color(0xFFF3EFEA)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    Icon(
                      _listening
                          ? Icons.mic
                          : (_speechDenied
                                ? Icons.mic_off_outlined
                                : Icons.mic_none),
                      size: 20,
                      color: _speechDenied ? Cult.error : Cult.ink,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _listening
                            ? 'Слушаю до конца фразы… можно говорить спокойно'
                            : (_speechDenied
                                  ? 'Нет доступа к микрофону — включите в Настройках → CULT'
                                  : 'Нажмите «Голос» — можно просто поговорить'),
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: _speechDenied ? Cult.error : Cult.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        cultTapFeedback();
                        pushPage(context, const VoiceSettingsPage());
                      },
                      child: const Text('Живой'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _toggleListen(store),
                      style: FilledButton.styleFrom(
                        backgroundColor: _listening ? Cult.secondary : Cult.ink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      child: Text(_listening ? 'Стоп' : 'Голос'),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  FocusManager.instance.primaryFocus?.unfocus();
                }
                return false;
              },
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EFEA),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(_iconFor(contact.id), color: Cult.ink),
                        ),
                        const SizedBox(height: 10),
                        Text(contact.name, style: cultHeadline(20)),
                        Text(
                          contact.role,
                          style: const TextStyle(
                            color: Cult.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  if (messages.isEmpty)
                    _Bubble(text: contact.seed, mine: false),
                  for (final message in messages)
                    _Bubble(text: message.text, mine: message.from == 'me'),
                  if (!messages.any((m) => m.from == 'me')) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tip in _quick)
                          ActionChip(
                            label: Text(tip),
                            onPressed: () => _send(store, tip),
                          ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(
                            Icons.event_available_outlined,
                            size: 18,
                          ),
                          label: const Text('Записаться'),
                          onPressed: () {
                            cultTapFeedback();
                            pushPage(context, const BookingPage());
                          },
                        ),
                        for (final tip in _followUp)
                          ActionChip(
                            label: Text(tip),
                            onPressed: () => _send(store, tip),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Material(
            color: Colors.white,
            elevation: 6,
            shadowColor: const Color(0x14000000),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_isAgent) ...[
                      IconButton(
                        tooltip: _listening ? 'Стоп' : 'Спросить голосом',
                        onPressed: () => _toggleListen(store),
                        style: IconButton.styleFrom(
                          backgroundColor: _listening
                              ? Cult.secondary
                              : Cult.ink,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 48),
                        ),
                        icon: Icon(_listening ? Icons.stop : Icons.mic),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: TextField(
                        controller: _text,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(store, _text.text),
                        decoration: InputDecoration(
                          hintText: widget.contactId == 'bot'
                              ? (_listening
                                    ? 'Говорите…'
                                    : 'Или напишите: цена RF, состав…')
                              : widget.contactId == 'specialist'
                              ? 'Опишите симптом или вопрос врачу…'
                              : 'Напишите администратору…',
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _text,
                      builder: (_, value, _) {
                        final canSend = value.text.trim().isNotEmpty;
                        return IconButton(
                          tooltip: 'Отправить',
                          onPressed: canSend
                              ? () => _send(store, _text.text)
                              : null,
                          style: IconButton.styleFrom(
                            backgroundColor: canSend
                                ? Cult.ink
                                : Cult.ink.withValues(alpha: 0.35),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Cult.ink.withValues(
                              alpha: 0.35,
                            ),
                            disabledForegroundColor: Colors.white70,
                            minimumSize: const Size(48, 48),
                          ),
                          icon: const Icon(Icons.arrow_upward),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.mine});

  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: mine ? 'Ваше сообщение' : 'Ответ клиники',
        hint: 'Удерживайте, чтобы скопировать',
        child: GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: text));
            cultTapFeedback();
            showCultSnack(context, 'Сообщение скопировано');
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            constraints: const BoxConstraints(maxWidth: 290),
            decoration: BoxDecoration(
              color: mine ? Cult.ink : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(mine ? 18 : 4),
                bottomRight: Radius.circular(mine ? 4 : 18),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                color: mine ? Colors.white : Cult.ink,
                height: 1.35,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BookingPage extends StatefulWidget {
  const BookingPage({super.key, this.initialService, this.initialDoctor});

  final String? initialService;
  final String? initialDoctor;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late String _service = widget.initialService ?? '';
  late String _doctor = (widget.initialDoctor?.trim().isNotEmpty ?? false)
      ? widget.initialDoctor!.trim()
      : doctors.first.name;
  DateTime? _date;
  var _time = '10:30';
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  var _booted = false;
  var _error = '';
  var _done = false;
  var _loading = false;
  var _sending = false;
  var _askCode = false;
  var _datesLoaded = false;
  List<YcStaff> _staff = [];
  List<YcSlot> _slots = [];
  List<String> _openDates = [];
  int? _serviceId;
  int? _staffId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_booted) return;
    _booted = true;
    final store = ClinicScope.of(context);
    _name.text = store.profileName;
    _phone.text = store.profilePhone.trim().isEmpty
        ? '+7'
        : formatRuPhone(store.profilePhone);
    _email.text = store.profileEmail;
    if (_service.isEmpty) {
      final catalog = store.catalogServices;
      _service = catalog.isNotEmpty
          ? catalog.first.title
          : services.first.title;
    }
    if (!store.yclientsReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCatalog();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final store = ClinicScope.of(context);
    setState(() {
      _loading = true;
      _error = '';
    });
    final message = await store.refreshCatalog();
    if (!mounted) return;
    setState(() => _loading = false);
    if (message != null) {
      setState(() => _error = message);
      return;
    }
    _applyService(store.catalogLive);
    await _loadStaff();
  }

  void _applyService(List<YcService> list) {
    if (list.isEmpty) return;
    final wanted = widget.initialService?.trim().toLowerCase() ?? '';
    final match = wanted.isEmpty
        ? list.first
        : list
                  .where((item) => item.title.toLowerCase() == wanted)
                  .firstOrNull ??
              list
                  .where((item) => item.title.toLowerCase().contains(wanted))
                  .firstOrNull ??
              list.first;
    _serviceId = match.id;
    _service = match.title;
  }

  Future<void> _loadStaff() async {
    final store = ClinicScope.of(context);
    final companyId = store.companyIdInt;
    if (companyId == null || _serviceId == null) return;
    setState(() => _loading = true);
    try {
      var staff = await store.yclients.staff(
        store.partnerToken,
        companyId,
        serviceId: _serviceId,
      );
      if (staff.isEmpty)
        staff = await store.yclients.staff(store.partnerToken, companyId);
      if (!mounted) return;
      final bookable = staff.where((item) => item.bookable).toList();
      final next = bookable.isEmpty ? staff : bookable;
      final wantedDoctor = widget.initialDoctor?.trim().toLowerCase() ?? '';
      final preferred = wantedDoctor.isEmpty
          ? null
          : next
                .where((item) => item.name.toLowerCase().contains(wantedDoctor))
                .firstOrNull;
      setState(() {
        _staff = next;
        _staffId = preferred?.id ?? (next.isEmpty ? null : next.first.id);
        _doctor = preferred?.name ?? (next.isEmpty ? '' : next.first.name);
        _slots = [];
        _loading = false;
      });
      await _loadDates();
    } on YcException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    }
  }

  Future<void> _loadDates() async {
    final store = ClinicScope.of(context);
    final companyId = store.companyIdInt;
    if (companyId == null) return;
    try {
      final dates = await store.yclients.bookableDates(
        store.partnerToken,
        companyId,
        staffId: _staffId,
        serviceId: _serviceId,
      );
      if (mounted) setState(() => _openDates = dates);
    } on YcException {
      if (mounted) setState(() => _openDates = []);
    }
  }

  Future<void> _loadSlots() async {
    final store = ClinicScope.of(context);
    final companyId = store.companyIdInt;
    if (companyId == null || _staffId == null || _date == null) return;
    final iso = _iso(_date!);
    setState(() => _loading = true);
    try {
      final slots = await store.yclients.times(
        store.partnerToken,
        companyId,
        _staffId!,
        iso,
        serviceId: _serviceId,
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _time = slots.isEmpty ? '' : slots.first.time;
        _loading = false;
        if (slots.isEmpty) _error = 'На эту дату нет свободного времени.';
      });
    } on YcException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    }
  }

  String _iso(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    if (store.yclientsReady) return _live(store);
    return _local(store);
  }

  Widget _local(ClinicStore store) {
    final options = [
      ...store.catalogServices.map((item) => item.title),
      'Анализ крови',
      'ДНК-тест старения',
      'Консультация',
      if (store.gender != ClientGender.man) 'Прецизионный анализ кожи',
    ];
    if (!options.contains(_service)) options.insert(0, _service);
    return Scaffold(
      appBar: AppBar(title: const Text('Запись')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Запись на услугу', style: cultHeadline(30)),
            const SizedBox(height: 8),
            const Text(
              'Сначала услуга, затем врач и время. Запись сохраняется в кабинете.',
            ),
            const SizedBox(height: 12),
            const CultCard(
              child: Text(
                'Онлайн-запись к филиалу сейчас недоступна. Визит сохранится в приложении.',
                style: TextStyle(color: Cult.muted, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: _done
                ? KeyedSubtree(
                    key: const ValueKey('local-done'),
                    child: _doneCard(),
                  )
                : Column(
                    key: const ValueKey('local-form'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CultSelect(
                        label: 'Услуга',
                        value: _service,
                        onTap: () async {
                          final picked = await _pickText(options);
                          if (picked != null) setState(() => _service = picked);
                        },
                      ),
                      CultSelect(
                        label: 'Врач',
                        value: _doctor,
                        onTap: () async {
                          final picked = await _pickText(
                            doctors.map((item) => item.name).toList(),
                          );
                          if (picked != null) {
                            setState(() => _doctor = picked);
                          }
                        },
                      ),
                      _dateTile(),
                      const _FieldLabel('Время'),
                      _timeChips(const [
                        '09:00',
                        '10:30',
                        '12:00',
                        '15:00',
                        '17:30',
                      ]),
                      const SizedBox(height: 8),
                      AutofillGroup(
                        child: Column(
                          children: [
                            TextField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              decoration: const InputDecoration(
                                labelText: 'Имя',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              inputFormatters: const [
                                CultPhoneInputFormatter(),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Телефон',
                                hintText: '+7 (___) ___-__-__',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_error.isNotEmpty) CultErrorBanner(message: _error),
                      const SizedBox(height: 12),
                      CultButton(
                        label: 'Подтвердить запись',
                        onPressed: () => _submitLocal(store),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _live(ClinicStore store) {
    final serviceItems = store.catalogLive;
    final genderNote = store.gender == null
        ? ''
        : ' ${store.gender!.servicesTitle}.';
    return Scaffold(
      appBar: AppBar(title: const Text('Запись')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Запись в филиал', style: cultHeadline(30)),
            const SizedBox(height: 8),
            Text(
              store.signedIn
                  ? 'Запись в филиал CULT, Сочи.$genderNote Контакт уже в базе клиники.'
                  : 'Услуги филиала CULT в Сочи.$genderNote Войдите по телефону в кабинете, чтобы сохраниться в базе.',
            ),
            if (_staff.isNotEmpty && _staff.every((item) => !item.bookable))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Свободных окон для онлайн-записи сейчас нет: расписание в филиале закрыто.',
                ),
              ),
            const SizedBox(height: 12),
            if (_loading) const CultLoading(label: 'Загружаем слоты филиала…'),
            AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: _done
                ? KeyedSubtree(key: const ValueKey('done'), child: _doneCard())
                : serviceItems.isEmpty && !_loading
                ? CultEmpty(
                    key: const ValueKey('empty'),
                    title: 'Услуги недоступны',
                    note: _error.isEmpty
                        ? 'В филиале нет услуг для онлайн-записи.'
                        : _error,
                    actionLabel: 'Повторить',
                    onAction: _loadCatalog,
                  )
                : KeyedSubtree(
                    key: const ValueKey('form'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (serviceItems.isNotEmpty)
                          CultSelect(
                            label: 'Услуга',
                            value: _serviceDetail(serviceItems),
                            hint: 'Найти в прайсе',
                            onTap: () async {
                              final picked =
                                  await showModalBottomSheet<YcService>(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) => _ServiceSheet(
                                      items: serviceItems,
                                      selected: _serviceId,
                                    ),
                                  );
                              if (picked == null) return;
                              setState(() {
                                _serviceId = picked.id;
                                _service = picked.title;
                                _date = null;
                                _slots = [];
                                _error = '';
                              });
                              await _loadStaff();
                            },
                          ),
                        if (_staff.isNotEmpty) ...[
                          const _FieldLabel('Врач'),
                          for (final item in _staff)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: item.id == _staffId
                                    ? Cult.gold
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () async {
                                    cultTapFeedback();
                                    setState(() {
                                      _staffId = item.id;
                                      _doctor = item.name;
                                      _slots = [];
                                      _date = null;
                                      _error = '';
                                    });
                                    await _loadDates();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: cultHeadline(18),
                                        ),
                                        if (item.specialization.isNotEmpty)
                                          Text(
                                            item.specialization,
                                            style: const TextStyle(
                                              color: Cult.muted,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                        if (_staffId != null &&
                            _datesLoaded &&
                            _openDates.isEmpty) ...[
                          const SizedBox(height: 4),
                          CultErrorBanner(
                            message:
                                'На ближайшие дни нет открытых дат. Выберите другого врача или позвоните в филиал.',
                            onRetry: _loadDates,
                            retryLabel: 'Обновить даты',
                          ),
                        ],
                        _dateTile(restrict: _openDates),
                        if (_slots.isNotEmpty) ...[
                          const _FieldLabel('Свободное время'),
                          _timeChips(_slots.map((item) => item.time).toList()),
                        ],
                        const SizedBox(height: 6),
                        const _FieldLabel('Контакты'),
                        AutofillGroup(
                          child: Column(
                            children: [
                              TextField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                decoration: const InputDecoration(
                                  labelText: 'Имя',
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                inputFormatters: const [
                                  CultPhoneInputFormatter(),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Телефон',
                                  hintText: '+7 (___) ___-__-__',
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Почта',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_askCode) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _code,
                            decoration: const InputDecoration(
                              labelText: 'Код из СМС',
                            ),
                          ),
                        ],
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _askCode = !_askCode),
                            child: const Text('Есть код из СМС'),
                          ),
                        ),
                        if (_error.isNotEmpty) CultErrorBanner(message: _error),
                        const SizedBox(height: 8),
                        CultButton(
                          label: _sending ? 'Отправляем' : 'Подтвердить запись',
                          onPressed: _sending ? null : () => _submitLive(store),
                        ),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doneCard() {
    final iso = _iso(_date!);
    final weekday = formatVisitWeekday(iso);
    final wait = formatVisitCountdown(iso, _time);
    final summary =
        '$_service · $_doctor, ${formatVisitDate(iso)}'
        '${weekday.isEmpty ? '' : ' ($weekday)'}'
        ' в $_time · CULT Сочи, Черноморская, 6';
    return CultCard(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF3EFEA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available,
              color: Cult.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text('Запись создана', style: cultHeadline(24)),
          const SizedBox(height: 8),
          Text(
            '$_service · $_doctor\n${formatVisitDate(iso)}'
            '${weekday.isEmpty ? '' : ', $weekday'}'
            ' в $_time'
            '${wait.isEmpty ? '' : '\n$wait'}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Cult.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          CultButton(
            label: 'Мои записи',
            onPressed: () => pushPage(context, const VisitsPage()),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: summary));
              cultTapFeedback();
              showCultSnack(context, 'Детали записи скопированы');
            },
            child: const Text('Скопировать детали'),
          ),
          TextButton(
            onPressed: () {
              cultTapFeedback();
              openExternal(
                'https://maps.google.com/?q=${Uri.encodeComponent('Сочи, Черноморская, 6')}',
                context: context,
              );
            },
            child: const Text('Маршрут до клиники'),
          ),
          TextButton(
            onPressed: () {
              cultTapFeedback();
              pushPage(
                context,
                const ChatThreadPage(contactId: 'admin'),
              );
            },
            child: const Text('Написать администратору'),
          ),
          TextButton(
            onPressed: () {
              cultTapFeedback();
              ClinicScope.of(context).sendMessage(
                'admin',
                'Нужен трансфер к записи: $summary',
              );
              pushPage(
                context,
                const ChatThreadPage(contactId: 'admin'),
              );
              showCultSnack(
                context,
                'Напишите адрес подачи — оформим трансфер',
              );
            },
            child: const Text('Нужен трансфер'),
          ),
          TextButton(
            onPressed: () {
              cultTapFeedback();
              ClinicScope.of(context).sendMessage(
                'admin',
                'Могу опоздать к записи: $summary',
              );
              pushPage(
                context,
                const ChatThreadPage(contactId: 'admin'),
              );
              showCultSnack(context, 'Сообщите, на сколько опаздываете');
            },
            child: const Text('Сообщить об опоздании'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('На главную'),
          ),
        ],
      ),
    );
  }

  String _serviceDetail(List<YcService> items) {
    final item = items.where((service) => service.id == _serviceId).firstOrNull;
    if (item == null) return _service;
    final bits = [
      item.title,
      if (item.durationLabel.isNotEmpty) item.durationLabel,
      item.priceLabel,
    ];
    return bits.join(' · ');
  }

  Future<String?> _pickText(List<String> options) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final option in options)
              ListTile(
                title: Text(option),
                trailing: option == _service || option == _doctor
                    ? const Icon(Icons.check, color: Cult.primary)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
  }

  Widget _timeChips(List<String> times) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final time in times)
            ChoiceChip(
              label: Text(time),
              selected: _time == time,
              onSelected: (_) {
                cultTapFeedback();
                setState(() => _time = time);
              },
            ),
        ],
      ),
    );
  }

  Widget _dateTile({List<String> restrict = const []}) {
    final iso = _date == null ? '' : _iso(_date!);
    final weekday = iso.isEmpty ? '' : formatVisitWeekday(iso);
    return CultSelect(
      label: 'Дата',
      value: _date == null
          ? ''
          : '${formatVisitDate(iso)}${weekday.isEmpty ? '' : ', $weekday'}',
      hint: 'Выберите день',
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          locale: const Locale('ru'),
          firstDate: now,
          lastDate: now.add(const Duration(days: 180)),
          initialDate: _date ?? now.add(const Duration(days: 1)),
          selectableDayPredicate: restrict.isEmpty
              ? null
              : (day) => restrict.contains(_iso(day)),
        );
        if (picked == null || !mounted) return;
        setState(() {
          _date = picked;
          _error = '';
        });
        if (ClinicScope.of(context).yclientsReady) await _loadSlots();
      },
    );
  }

  void _submitLocal(ClinicStore store) {
    final phone = normalizePhone(_phone.text);
    if (_date == null || _name.text.trim().length < 2 || phone.length < 11) {
      setState(() => _error = 'Укажите дату, имя и телефон в формате +7.');
      return;
    }
    final iso = _iso(_date!);
    store.rememberContact(
      name: _name.text,
      phone: _phone.text.trim(),
      email: _email.text.trim(),
    );
    store.bookVisit(service: _service, doctor: _doctor, date: iso, time: _time);
    store.sendMessage(
      'admin',
      'Запись: $_service, $_doctor, $iso в $_time, ${_name.text}, +$phone.',
    );
    HapticFeedback.mediumImpact();
    setState(() {
      _error = '';
      _done = true;
    });
  }

  Future<void> _submitLive(ClinicStore store) async {
    if (_sending) return;
    final phone = normalizePhone(_phone.text);
    final email = _email.text.trim();
    final slot = _slots.where((item) => item.time == _time).firstOrNull;
    if (_date == null ||
        _serviceId == null ||
        _staffId == null ||
        slot == null ||
        _name.text.trim().length < 2 ||
        phone.length != 11 ||
        !email.contains('@')) {
      setState(
        () => _error =
            'Укажите услугу, врача, дату, время, имя, телефон и почту.',
      );
      return;
    }
    final companyId = store.companyIdInt;
    if (companyId == null) return;
    setState(() {
      _sending = true;
      _error = '';
    });
    try {
      if (!store.signedIn) {
        await store.registerWithPhone(
          name: _name.text.trim(),
          phone: phone,
          email: email,
        );
      }
      final booked = await store.yclients.book(
        partnerToken: store.partnerToken,
        companyId: companyId,
        phone: phone,
        fullname: _name.text.trim(),
        email: email,
        serviceId: _serviceId!,
        staffId: _staffId!,
        datetime: slot.datetime,
        code: _code.text,
      );
      final iso = _iso(_date!);
      store.rememberContact(
        name: _name.text,
        phone: _phone.text.trim(),
        email: _email.text.trim(),
      );
      store.bookVisit(
        service: _service,
        doctor: _doctor,
        date: iso,
        time: slot.time,
        recordId: booked.recordId,
        recordHash: booked.recordHash,
      );
      store.sendMessage(
        'admin',
        'Запись YClients №${booked.recordId}: $_service, $_doctor, $iso в ${slot.time}.',
      );
      await store.refreshVisits();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _sending = false;
        _done = true;
        _time = slot.time;
      });
    } on YcException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error.message;
        if (error.message.toLowerCase().contains('код')) _askCode = true;
      });
    }
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Cult.muted,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ServiceSheet extends StatefulWidget {
  const _ServiceSheet({required this.items, required this.selected});

  final List<YcService> items;
  final int? selected;

  @override
  State<_ServiceSheet> createState() => _ServiceSheetState();
}

class _ServiceSheetState extends State<_ServiceSheet> {
  final _query = TextEditingController();
  var _group = 'Все';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.86;
    final groups = <String>['Все'];
    for (final item in widget.items) {
      final name = item.category.isEmpty ? 'Без категории' : item.category;
      if (!groups.contains(name)) groups.add(name);
    }
    final needle = _query.text.trim().toLowerCase();
    final visible = widget.items.where((item) {
      final group = item.category.isEmpty ? 'Без категории' : item.category;
      final groupOk = _group == 'Все' || group == _group;
      final textOk =
          needle.isEmpty ||
          item.title.toLowerCase().contains(needle) ||
          group.toLowerCase().contains(needle);
      return groupOk && textOk;
    }).toList();
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Услуга', style: cultHeadline(28)),
            const SizedBox(height: 8),
            CultSearchField(
              controller: _query,
              hint: 'Название или категория',
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return ChoiceChip(
                    label: Text(group),
                    selected: _group == group,
                    onSelected: (_) {
                      cultTapFeedback();
                      setState(() => _group = group);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? ListView(
                      children: [
                        CultEmpty(
                          title: 'Ничего не найдено',
                          note: 'Смените категорию или короче запрос.',
                          actionLabel: 'Сбросить',
                          onAction: () => setState(() {
                            _group = 'Все';
                            _query.clear();
                          }),
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = visible[index];
                        final selected = item.id == widget.selected;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.category.isEmpty ? 'Филиал' : item.category}${item.durationLabel.isEmpty ? '' : ' · ${item.durationLabel}'}',
                          ),
                          trailing: Text(
                            item.priceLabel,
                            style: TextStyle(
                              color: selected ? Cult.primary : Cult.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
