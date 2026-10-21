import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'talk.dart';

class PricesPage extends StatefulWidget {
  const PricesPage({super.key});

  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> {
  final _query = TextEditingController();
  var _chip = 'Все';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needle = _query.text.trim().toLowerCase();
    final rows = <({String group, String name, String meta, String price})>[
      for (final item in services) (group: item.group, name: item.title, meta: item.duration, price: item.priceLabel),
      for (final item in devices) (group: 'Оборудование', name: item.title, meta: item.meta, price: item.price),
      (group: 'Инфузии', name: 'NAD+ Energy', meta: '60 мин', price: '15 000 ₽'),
      (group: 'Инфузии', name: 'Immunity Boost', meta: '45 мин', price: '12 000 ₽'),
      (group: 'Инфузии', name: 'Beauty & Glow', meta: '60 мин', price: '18 000 ₽'),
    ].where((row) {
      final groupOk = _chip == 'Все' || row.group == _chip;
      final textOk = needle.isEmpty || row.name.toLowerCase().contains(needle);
      return groupOk && textOk;
    }).toList();
    final chips = ['Все', 'Эстетика и уход', 'Инъекции', 'Оборудование', 'Инфузии'];
    return Scaffold(
      appBar: AppBar(title: const Text('Прайс')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Интерактивный список. Точная сумма подтверждается на консультации.'),
          TextField(
            controller: _query,
            decoration: const InputDecoration(labelText: 'Найти услугу'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final chip in chips)
                ChoiceChip(label: Text(chip), selected: _chip == chip, onSelected: (_) => setState(() => _chip = chip)),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty) const Text('Ничего не найдено.') else
            for (final row in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(row.name),
                subtitle: Text('${row.group} · ${row.meta}'),
                trailing: Text(row.price),
              ),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('О клинике')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CultImage('interior', aspect: 16 / 9, radius: 16),
          const SizedBox(height: 12),
          Text('О клинике', style: cultHeadline(32)),
          const SizedBox(height: 8),
          const Text('CULT — клиническое святилище: диагностика, аппараты, инъекции и инфузии в одном протоколе.'),
          const SizedBox(height: 12),
          const Text('Адрес: Клинический переулок, 7'),
          const Text('Часы: ежедневно 9:00–21:00'),
          const Text('Телефон: +7 495 000-00-07'),
          const SizedBox(height: 12),
          Text('Как добраться', style: cultHeadline(22)),
          const Text('От метро «Кропоткинская» семь минут пешком. Парковка для гостей у ресепшен.'),
          const SizedBox(height: 12),
          Text('Документы', style: cultHeadline(22)),
          const Text('Публичная оферта, согласие на процедуры и политика данных. В приложении имя, визиты и заказы хранятся только на телефоне.'),
          const SizedBox(height: 12),
          CultButton(label: 'YouTube', onPressed: () => openExternal('https://www.youtube.com/results?search_query=CULT+Clinic')),
          TextButton(onPressed: () => openExternal('https://t.me/cultclinic'), child: const Text('Telegram')),
          TextButton(onPressed: () => openExternal('https://wa.me/74950000007'), child: const Text('WhatsApp')),
        ],
      ),
    );
  }
}

class BlogPage extends StatelessWidget {
  const BlogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Блог')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final article in articles)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => pushPage(context, ArticlePage(article: article)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CultImage(article.image, aspect: 16 / 9, radius: 12),
                    const SizedBox(height: 8),
                    Text(article.kicker.toUpperCase(), style: const TextStyle(color: Cult.primary, letterSpacing: 1)),
                    Text(article.title, style: cultHeadline(24)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ArticlePage extends StatelessWidget {
  const ArticlePage({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.kicker)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CultImage(article.image, aspect: 16 / 9, radius: 12),
          const SizedBox(height: 12),
          Text(article.title, style: cultHeadline(30)),
          Text(article.author, style: const TextStyle(color: Cult.muted)),
          const SizedBox(height: 12),
          for (final paragraph in article.body) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(paragraph)),
          CultButton(
            label: 'Смотреть',
            onPressed: () => openExternal('https://www.youtube.com/results?search_query=${Uri.encodeComponent('${article.title} CULT Clinic')}'),
          ),
        ],
      ),
    );
  }
}

class CasesPage extends StatelessWidget {
  const CasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Кейсы')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final item in cases)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => pushPage(context, CasePage(item: item)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CultImage(item.image, aspect: 4 / 3, radius: 12),
                    const SizedBox(height: 8),
                    Text(item.title, style: cultHeadline(24)),
                    Text('${item.procedure} · ${item.doctor}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CasePage extends StatelessWidget {
  const CasePage({super.key, required this.item});

  final ClinicCase item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Кейс')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('До', style: cultHeadline(20)),
          const CultImage('before', aspect: 4 / 3, radius: 12),
          const SizedBox(height: 12),
          Text('После', style: cultHeadline(20)),
          CultImage(item.image, aspect: 4 / 3, radius: 12),
          const SizedBox(height: 12),
          Text(item.title, style: cultHeadline(28)),
          Text('${item.procedure} · ${item.doctor}'),
          const SizedBox(height: 8),
          Text(item.text),
          const SizedBox(height: 16),
          CultButton(label: 'Записаться', onPressed: () => pushPage(context, BookingPage(initialService: item.procedure))),
        ],
      ),
    );
  }
}

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _from = TextEditingController();
  var _done = false;

  @override
  void dispose() {
    _from.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Трансфер')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('VIP-такси до клиники', style: cultHeadline(28)),
          const SizedBox(height: 8),
          const Text('Адрес клиники: Клинический переулок, 7. Машина подаётся к указанному адресу.'),
          if (_done)
            const Padding(padding: EdgeInsets.only(top: 16), child: Text('Заявка у консьержа. Водитель напишет в чат администратора.'))
          else ...[
            TextField(controller: _from, decoration: const InputDecoration(labelText: 'Откуда забрать')),
            const SizedBox(height: 12),
            CultButton(
              label: 'Заказать',
              onPressed: () {
                if (_from.text.trim().length < 5) return;
                setState(() => _done = true);
              },
            ),
          ],
        ],
      ),
    );
  }
}
