import 'package:flutter/material.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import '../yclients.dart';
import 'cabinet.dart';
import 'yclients_page.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final closed = hour < 9 || hour >= 21;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CultCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(closed ? 'Клиника сейчас закрыта' : 'Если линия занята', style: cultHeadline(22)),
              const SizedBox(height: 6),
              Text(closed
                  ? 'До 9:00 и после 21:00 первым отвечает ИИ-бот. Врач увидит переписку утром.'
                  : 'При нагрузке первым отвечает ИИ-бот, затем подключается администратор или врач.'),
              TextButton(onPressed: () => pushPage(context, const ChatThreadPage(contactId: 'bot')), child: const Text('Написать боту')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Центр поддержки', style: cultHeadline(32)),
        const SizedBox(height: 12),
        for (final contact in contacts)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => pushPage(context, ChatThreadPage(contactId: contact.id)),
              child: CultCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contact.name, style: cultHeadline(22)),
                    Text(contact.role.toUpperCase(), style: const TextStyle(color: Cult.primary, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(contact.seed),
                  ],
                ),
              ),
            ),
          ),
      ],
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

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final contact = contacts.firstWhere((item) => item.id == widget.contactId);
    final messages = store.threads[widget.contactId] ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(contact.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final message in messages)
                  Align(
                    alignment: message.from == 'me' ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: message.from == 'me' ? Cult.ink : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(message.text, style: TextStyle(color: message.from == 'me' ? Colors.white : Cult.ink)),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _text, decoration: const InputDecoration(hintText: 'Сообщение'))),
                  IconButton(
                    onPressed: () {
                      store.sendMessage(widget.contactId, _text.text);
                      _text.clear();
                    },
                    icon: const Icon(Icons.send),
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

class BookingPage extends StatefulWidget {
  const BookingPage({super.key, this.initialService});

  final String? initialService;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late String _service = widget.initialService ?? services.first.title;
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
    _applyService(store.liveServices);
    await _loadStaff();
  }

  void _applyService(List<YcService> list) {
    if (list.isEmpty) return;
    final wanted = widget.initialService?.toLowerCase();
    final match = list.where((item) => item.title.toLowerCase() == wanted).firstOrNull ?? list.first;
    _serviceId = match.id;
    _service = match.title;
  }

  Future<void> _loadStaff() async {
    final store = ClinicScope.of(context);
    final companyId = store.companyIdInt;
    if (companyId == null || _serviceId == null) return;
    setState(() => _loading = true);
    try {
      var staff = await store.yclients.staff(store.partnerToken, companyId, serviceId: _serviceId);
      if (staff.isEmpty) staff = await store.yclients.staff(store.partnerToken, companyId);
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
      final dates = await store.yclients.bookableDates(store.partnerToken, companyId, staffId: _staffId, serviceId: _serviceId);
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
      final slots = await store.yclients.times(store.partnerToken, companyId, _staffId!, iso, serviceId: _serviceId);
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
    final options = [...services.map((item) => item.title), 'Анализ крови', 'ДНК-тест старения', 'Консультация', 'Прецизионный анализ кожи'];
    if (!options.contains(_service)) options.insert(0, _service);
    return Scaffold(
      appBar: AppBar(title: const Text('Запись')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Запись на услугу', style: cultHeadline(30)),
          const SizedBox(height: 8),
          const Text('Сначала услуга, затем врач и время. Запись сохраняется в кабинете.'),
          const SizedBox(height: 12),
          CultCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('YClients ещё не подключён. Визит останется только в приложении.'),
                TextButton(onPressed: () => pushPage(context, const YClientsPage()), child: const Text('Подключить филиал')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_done)
            _doneCard()
          else ...[
            DropdownButtonFormField<String>(
              initialValue: _service,
              decoration: const InputDecoration(labelText: 'Услуга'),
              items: [for (final item in options) DropdownMenuItem(value: item, child: Text(item))],
              onChanged: (value) => setState(() => _service = value ?? _service),
            ),
            DropdownButtonFormField<String>(
              initialValue: _doctor,
              decoration: const InputDecoration(labelText: 'Врач'),
              items: [for (final item in doctors) DropdownMenuItem(value: item.name, child: Text(item.name))],
              onChanged: (value) => setState(() => _doctor = value ?? _doctor),
            ),
            _dateTile(),
            DropdownButtonFormField<String>(
              initialValue: _time,
              decoration: const InputDecoration(labelText: 'Время'),
              items: const [
                DropdownMenuItem(value: '09:00', child: Text('09:00')),
                DropdownMenuItem(value: '10:30', child: Text('10:30')),
                DropdownMenuItem(value: '12:00', child: Text('12:00')),
                DropdownMenuItem(value: '15:00', child: Text('15:00')),
                DropdownMenuItem(value: '17:30', child: Text('17:30')),
              ],
              onChanged: (value) => setState(() => _time = value ?? _time),
            ),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Имя')),
            if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Cult.error)),
            const SizedBox(height: 12),
            CultButton(label: 'Подтвердить запись', onPressed: () => _submitLocal(store)),
          ],
        ],
      ),
    );
  }

  Widget _live(ClinicStore store) {
    final serviceItems = store.liveServices;
    return Scaffold(
      appBar: AppBar(title: const Text('Запись')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Запись в филиал', style: cultHeadline(30)),
          const SizedBox(height: 8),
          Text('Услуги и врачи из YClients, филиал ${store.companyId}, CULT, Сочи.'),
          if (_staff.isNotEmpty && _staff.every((item) => !item.bookable))
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Свободных окон для онлайн-записи сейчас нет: расписание в филиале закрыто.'),
            ),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          if (_done)
            _doneCard()
          else if (serviceItems.isEmpty && !_loading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_error.isEmpty ? 'В филиале нет услуг для онлайн-записи.' : _error, style: const TextStyle(color: Cult.error)),
                TextButton(onPressed: _loadCatalog, child: const Text('Повторить')),
              ],
            )
          else ...[
            if (serviceItems.isNotEmpty)
              DropdownButtonFormField<int>(
                key: ValueKey(serviceItems.map((item) => item.id).join(',')),
                isExpanded: true,
                initialValue: _serviceId,
                decoration: const InputDecoration(labelText: 'Услуга'),
                items: [
                  for (final item in serviceItems)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text('${item.title}${item.durationLabel.isEmpty ? '' : ' · ${item.durationLabel}'} · ${item.priceLabel}'),
                    ),
                ],
                onChanged: (value) async {
                  final picked = serviceItems.where((item) => item.id == value).firstOrNull;
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
            if (_staff.isNotEmpty && _staffId != null)
              DropdownButtonFormField<int>(
                key: ValueKey('$_serviceId-${_staff.map((item) => item.id).join(',')}'),
                isExpanded: true,
                initialValue: _staffId,
                decoration: const InputDecoration(labelText: 'Врач'),
                items: [
                  for (final item in _staff)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text(item.specialization.isEmpty ? item.name : '${item.name}, ${item.specialization}'),
                    ),
                ],
                onChanged: (value) async {
                  final picked = _staff.where((item) => item.id == value).firstOrNull;
                  if (picked == null) return;
                  setState(() {
                    _staffId = picked.id;
                    _doctor = picked.name;
                    _slots = [];
                    _date = null;
                    _error = '';
                  });
                  await _loadDates();
                },
              ),
            _dateTile(restrict: _openDates),
            if (_slots.isNotEmpty)
              DropdownButtonFormField<String>(
                key: ValueKey(_slots.map((item) => item.time).join(',')),
                isExpanded: true,
                initialValue: _slots.any((item) => item.time == _time) ? _time : _slots.first.time,
                decoration: const InputDecoration(labelText: 'Время'),
                items: [for (final item in _slots) DropdownMenuItem(value: item.time, child: Text(item.time))],
                onChanged: (value) => setState(() => _time = value ?? _time),
              ),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Имя')),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Телефон')),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Почта')),
            if (_askCode) TextField(controller: _code, decoration: const InputDecoration(labelText: 'Код из СМС')),
            TextButton(onPressed: () => setState(() => _askCode = !_askCode), child: const Text('Есть код из СМС')),
            if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Cult.error)),
            const SizedBox(height: 12),
            CultButton(label: _sending ? 'Отправляем' : 'Подтвердить запись', onPressed: () => _submitLive(store)),
          ],
        ],
      ),
    );
  }

  Widget _doneCard() {
    return CultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Запись создана', style: cultHeadline(22)),
          const SizedBox(height: 8),
          Text('${_name.text}: $_service, $_doctor, ${formatVisitDate(_iso(_date!))} в $_time.'),
          TextButton(onPressed: () => pushPage(context, const VisitsPage()), child: const Text('Мои записи')),
        ],
      ),
    );
  }

  Widget _dateTile({List<String> restrict = const []}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Дата'),
      subtitle: Text(_date == null ? 'Выберите день' : formatVisitDate(_iso(_date!))),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          locale: const Locale('ru'),
          firstDate: now,
          lastDate: now.add(const Duration(days: 180)),
          initialDate: _date ?? now.add(const Duration(days: 1)),
          selectableDayPredicate: restrict.isEmpty ? null : (day) => restrict.contains(_iso(day)),
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
    store.sendMessage('admin', 'Запись: $_service, $_doctor, $iso в $_time, ${_name.text}.');
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
    if (_date == null || _serviceId == null || _staffId == null || slot == null || _name.text.trim().length < 2 || phone.length != 11 || !email.contains('@')) {
      setState(() => _error = 'Укажите услугу, врача, дату, время, имя, телефон и почту.');
      return;
    }
    final companyId = store.companyIdInt;
    if (companyId == null) return;
    setState(() {
      _sending = true;
      _error = '';
    });
    try {
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
      store.rememberContact(name: _name.text, phone: _phone.text.trim(), email: _email.text.trim());
      store.bookVisit(service: _service, doctor: _doctor, date: iso, time: slot.time, recordId: booked.recordId, recordHash: booked.recordHash);
      store.sendMessage('admin', 'Запись YClients №${booked.recordId}: $_service, $_doctor, $iso в ${slot.time}.');
      if (!mounted) return;
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
