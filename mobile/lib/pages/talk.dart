import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import '../yclients.dart';
import 'cabinet.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('Центр поддержки', style: cultHeadline(30)),
        const SizedBox(height: 6),
        const Text(
          'Администратор, бот или специалист — ответим по делу.',
          style: TextStyle(color: Cult.muted),
        ),
        const SizedBox(height: 16),
        for (final contact in contacts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () =>
                  pushPage(context, ChatThreadPage(contactId: contact.id)),
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
                      child: Icon(
                        contact.id == 'specialist'
                            ? Icons.medical_services_outlined
                            : contact.id == 'bot'
                            ? Icons.smart_toy_outlined
                            : Icons.support_agent_outlined,
                        color: Cult.ink,
                      ),
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
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Cult.muted),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text('Альтернативная поддержка', style: cultHeadline(20)),
        const SizedBox(height: 8),
        CultCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SupportLink(
                title: 'Часто задаваемые вопросы',
                onTap: () =>
                    pushPage(context, const ChatThreadPage(contactId: 'bot')),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _SupportLink(
                title: 'Экстренные протоколы',
                onTap: () =>
                    pushPage(context, const ChatThreadPage(contactId: 'admin')),
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
      onTap: onTap,
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

  static const _quick = <String>[
    'Хочу записаться',
    'Часы работы',
    'Как добраться',
    'Бонусы',
  ];

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(ClinicStore store, String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    store.sendMessage(widget.contactId, text);
    _text.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  IconData _iconFor(String id) => switch (id) {
    'specialist' => Icons.medical_services_outlined,
    'bot' => Icons.smart_toy_outlined,
    _ => Icons.support_agent_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final contact = contacts.firstWhere((item) => item.id == widget.contactId);
    final messages = store.threads[widget.contactId] ?? [];
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
      ),
      body: Column(
        children: [
          Expanded(
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
                        style: const TextStyle(color: Cult.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                if (messages.isEmpty) _Bubble(text: contact.seed, mine: false),
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
                ],
              ],
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
                    Expanded(
                      child: TextField(
                        controller: _text,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(store, _text.text),
                        decoration: const InputDecoration(
                          hintText: 'Напишите сообщение…',
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _send(store, _text.text),
                      style: IconButton.styleFrom(
                        backgroundColor: Cult.ink,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.arrow_upward),
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
          style: TextStyle(color: mine ? Colors.white : Cult.ink, height: 1.35),
        ),
      ),
    );
  }
}

class BookingPage extends StatefulWidget {
  const BookingPage({super.key, this.initialService});

  final String? initialService;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late String _service = widget.initialService ?? '';
  String _doctor = doctors.first.name;
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
    _phone.text = store.profilePhone;
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
    final wanted = widget.initialService?.toLowerCase();
    final match =
        list.where((item) => item.title.toLowerCase() == wanted).firstOrNull ??
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
      setState(() {
        _staff = next;
        _staffId = next.isEmpty ? null : next.first.id;
        _doctor = next.isEmpty ? '' : next.first.name;
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
      body: ListView(
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
          if (_done)
            _doneCard()
          else ...[
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
                if (picked != null) setState(() => _doctor = picked);
              },
            ),
            _dateTile(),
            const _FieldLabel('Время'),
            _timeChips(const ['09:00', '10:30', '12:00', '15:00', '17:30']),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
            if (_error.isNotEmpty) _errorBanner(_error),
            const SizedBox(height: 12),
            CultButton(
              label: 'Подтвердить запись',
              onPressed: () => _submitLocal(store),
            ),
          ],
        ],
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
      body: ListView(
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
          if (_done)
            _doneCard()
          else if (serviceItems.isEmpty && !_loading)
            CultEmpty(
              title: 'Услуги недоступны',
              note: _error.isEmpty
                  ? 'В филиале нет услуг для онлайн-записи.'
                  : _error,
              actionLabel: 'Повторить',
              onAction: _loadCatalog,
            )
          else ...[
            if (serviceItems.isNotEmpty)
              CultSelect(
                label: 'Услуга',
                value: _serviceDetail(serviceItems),
                hint: 'Найти в прайсе',
                onTap: () async {
                  final picked = await showModalBottomSheet<YcService>(
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
                    color: item.id == _staffId ? Cult.gold : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: cultHeadline(18)),
                            if (item.specialization.isNotEmpty)
                              Text(
                                item.specialization,
                                style: const TextStyle(color: Cult.muted),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            _dateTile(restrict: _openDates),
            if (_slots.isNotEmpty) ...[
              const _FieldLabel('Свободное время'),
              _timeChips(_slots.map((item) => item.time).toList()),
            ],
            const SizedBox(height: 6),
            const _FieldLabel('Контакты'),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Телефон'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Почта'),
            ),
            if (_askCode) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _code,
                decoration: const InputDecoration(labelText: 'Код из СМС'),
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _askCode = !_askCode),
                child: const Text('Есть код из СМС'),
              ),
            ),
            if (_error.isNotEmpty) _errorBanner(_error),
            const SizedBox(height: 8),
            CultButton(
              label: _sending ? 'Отправляем' : 'Подтвердить запись',
              onPressed: () => _submitLive(store),
            ),
          ],
        ],
      ),
    );
  }

  Widget _doneCard() {
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
            '$_service · $_doctor\n${formatVisitDate(_iso(_date!))} в $_time',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Cult.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          CultButton(
            label: 'Мои записи',
            onPressed: () => pushPage(context, const VisitsPage()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
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
              onSelected: (_) => setState(() => _time = time),
            ),
        ],
      ),
    );
  }

  Widget _errorBanner(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8E8E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Cult.error)),
    );
  }

  Widget _dateTile({List<String> restrict = const []}) {
    return CultSelect(
      label: 'Дата',
      value: _date == null ? '' : formatVisitDate(_iso(_date!)),
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
    if (_date == null || _name.text.trim().length < 2) {
      setState(() => _error = 'Укажите дату и имя.');
      return;
    }
    final iso = _iso(_date!);
    store.bookVisit(service: _service, doctor: _doctor, date: iso, time: _time);
    store.sendMessage(
      'admin',
      'Запись: $_service, $_doctor, $iso в $_time, ${_name.text}.',
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
            TextField(
              controller: _query,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Название или категория',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
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
                    onSelected: (_) => setState(() => _group = group),
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
