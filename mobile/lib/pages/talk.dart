import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cabinet.dart';

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
  final _name = TextEditingController(text: 'Александра');
  var _error = '';
  var _done = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
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
          if (_done)
            CultCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Запись создана', style: cultHeadline(22)),
                  const SizedBox(height: 8),
                  Text('${_name.text}: $_service, $_doctor, ${formatVisitDate(_date!.toIso8601String().split('T').first)} в $_time.'),
                  TextButton(onPressed: () => pushPage(context, const VisitsPage()), child: const Text('Мои записи')),
                ],
              ),
            )
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Дата'),
              subtitle: Text(_date == null ? 'Выберите день' : formatVisitDate(_date!.toIso8601String().split('T').first)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  locale: const Locale('ru'),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
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
            CultButton(
              label: 'Подтвердить запись',
              onPressed: () {
                if (_date == null || _name.text.trim().length < 2) {
                  setState(() => _error = 'Укажите дату и имя.');
                  return;
                }
                final iso = _date!.toIso8601String().split('T').first;
                store.bookVisit(service: _service, doctor: _doctor, date: iso, time: _time);
                store.sendMessage('admin', 'Запись: $_service, $_doctor, $iso в $_time, ${_name.text}.');
                setState(() {
                  _error = '';
                  _done = true;
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}
