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
  var _askedLive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = ClinicScope.of(context);
    if (_askedLive || !store.yclientsReady) return;
    _askedLive = true;
    store.refreshCatalog();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final needle = _query.text.trim().toLowerCase();
    final live = store.catalogLive;
    final local = store.catalogServices;
    final rows =
        <({String group, String name, String meta, String price})>[
          for (final item in live)
            (
              group: item.category.isEmpty ? 'YClients' : item.category,
              name: item.title,
              meta: item.durationLabel.isEmpty ? 'филиал' : item.durationLabel,
              price: item.priceLabel,
            ),
          for (final item in local)
            (
              group: item.group,
              name: item.title,
              meta: item.duration,
              price: item.priceLabel,
            ),
          for (final item in devices)
            (
              group: 'Оборудование',
              name: item.title,
              meta: item.meta,
              price: item.price,
            ),
          (
            group: 'Инфузии',
            name: 'NAD+ Energy',
            meta: '60 мин',
            price: '15 000 ₽',
          ),
          (
            group: 'Инфузии',
            name: 'Immunity Boost',
            meta: '45 мин',
            price: '12 000 ₽',
          ),
          if (store.gender != ClientGender.man)
            (
              group: 'Инфузии',
              name: 'Beauty & Glow',
              meta: '60 мин',
              price: '18 000 ₽',
            ),
        ].where((row) {
          final groupOk = _chip == 'Все' || row.group == _chip;
          final textOk =
              needle.isEmpty ||
              row.name.toLowerCase().contains(needle) ||
              row.group.toLowerCase().contains(needle);
          return groupOk && textOk;
        }).toList();
    final liveGroups = <String>[];
    for (final item in live) {
      final group = item.category.isEmpty ? 'YClients' : item.category;
      if (!liveGroups.contains(group)) liveGroups.add(group);
    }
    final chips = [
      'Все',
      ...liveGroups,
      'Эстетика и уход',
      'Инъекции',
      'Оборудование',
      'Инфузии',
    ];
    final genderNote = store.gender == null
        ? ''
        : ' Сейчас: ${store.gender!.servicesTitle.toLowerCase()}.';
    return Scaffold(
      appBar: AppBar(title: const Text('Прайс')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            store.yclientsReady
                ? 'Цены филиала CULT в Сочи.$genderNote Поиск ищет и по категориям.'
                : 'Точная сумма подтверждается на консультации.$genderNote',
          ),
          if (store.liveError.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(store.liveError, style: const TextStyle(color: Cult.error)),
            TextButton(
              onPressed: store.refreshCatalog,
              child: const Text('Повторить'),
            ),
          ],
          if (store.yclientsReady &&
              store.liveServices.isEmpty &&
              store.liveError.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _query,
            decoration: const InputDecoration(
              hintText: 'Найти услугу',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final chip = chips[index];
                return ChoiceChip(
                  label: Text(chip),
                  selected: _chip == chip,
                  onSelected: (_) => setState(() => _chip = chip),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            CultEmpty(
              title: 'Ничего не найдено',
              note: 'Смените категорию или короче запрос.',
              actionLabel: 'Сбросить',
              onAction: () => setState(() {
                _chip = 'Все';
                _query.clear();
              }),
            )
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    minVerticalPadding: 10,
                    title: Text(row.name),
                    subtitle: Text(
                      '${row.group} · ${row.meta}',
                      style: const TextStyle(color: Cult.muted),
                    ),
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 108),
                      child: Text(
                        row.price,
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
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
          const Text(
            'CULT — клиническое святилище: диагностика, аппараты, инъекции и инфузии в одном протоколе.',
          ),
          const SizedBox(height: 12),
          const Text('Адрес: Сочи, Черноморская, 6'),
          const Text('Часы: ежедневно 9:00–21:00'),
          const Text('Телефон: +7 495 000-00-07'),
          const SizedBox(height: 12),
          Text('Как добраться', style: cultHeadline(22)),
          const Text(
            'Клиника на Черноморской, 6. Парковка для гостей у входа.',
          ),
          const SizedBox(height: 12),
          Text('Документы', style: cultHeadline(22)),
          const Text(
            'Публичная оферта, согласие на процедуры и политика данных. В приложении имя, визиты и заказы хранятся только на телефоне.',
          ),
          const SizedBox(height: 12),
          CultButton(
            label: 'YouTube',
            onPressed: () => openExternal(
              'https://www.youtube.com/results?search_query=CULT+Clinic',
            ),
          ),
          TextButton(
            onPressed: () => openExternal('https://t.me/cultclinic'),
            child: const Text('Telegram'),
          ),
          TextButton(
            onPressed: () => openExternal('https://wa.me/74950000007'),
            child: const Text('WhatsApp'),
          ),
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
                    Text(
                      article.kicker.toUpperCase(),
                      style: const TextStyle(
                        color: Cult.primary,
                        letterSpacing: 1,
                      ),
                    ),
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
          for (final paragraph in article.body)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(paragraph),
            ),
          CultButton(
            label: 'Смотреть',
            onPressed: () => openExternal(
              'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${article.title} CULT Clinic')}',
            ),
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
          CultButton(
            label: 'Записаться',
            onPressed: () =>
                pushPage(context, BookingPage(initialService: item.procedure)),
          ),
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
  var _error = '';

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
          const Text(
            'Адрес клиники: Сочи, Черноморская, 6. Машина подаётся к указанному адресу.',
          ),
          if (_done)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Заявка у консьержа. Водитель напишет в чат администратора.',
              ),
            )
          else ...[
            TextField(
              controller: _from,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Откуда забрать'),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error, style: const TextStyle(color: Cult.error)),
              ),
            const SizedBox(height: 12),
            CultButton(
              label: 'Заказать',
              onPressed: () {
                if (_from.text.trim().length < 5) {
                  setState(() => _error = 'Укажите адрес, откуда забрать.');
                  return;
                }
                setState(() => _done = true);
              },
            ),
          ],
        ],
      ),
    );
  }
}
