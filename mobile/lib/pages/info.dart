import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
          return false;
        },
        child: RefreshIndicator(
          color: Cult.primary,
          onRefresh: () => store.refreshCatalog(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                store.yclientsReady
                    ? 'Цены филиала CULT в Сочи.$genderNote Поиск ищет и по категориям.'
                    : 'Точная сумма подтверждается на консультации.$genderNote',
              ),
            if (store.liveError.isNotEmpty)
              CultErrorBanner(
                message: store.liveError,
                onRetry: store.refreshCatalog,
              ),
            if (store.yclientsReady &&
                store.liveServices.isEmpty &&
                store.liveError.isEmpty)
              const CultLoading(label: 'Загружаем прайс…'),
            const SizedBox(height: 8),
            CultSearchField(
              controller: _query,
              hint: 'Найти услугу',
              onChanged: () => setState(() {}),
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
                    onSelected: (_) {
                      cultTapFeedback();
                      setState(() => _chip = chip);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (rows.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${rows.length} позиц.',
                  style: const TextStyle(color: Cult.muted, fontSize: 12),
                ),
              ),
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
                      onTap: () {
                        cultTapFeedback();
                        pushPage(
                          context,
                          BookingPage(initialService: row.name),
                        );
                      },
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

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CULT')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const CultImage('interior', aspect: 16 / 9, radius: 18),
          const SizedBox(height: 16),
          Text('О клинике', style: cultHeadline(32)),
          const SizedBox(height: 8),
          const Text(
            'CULT — клиническое святилище: диагностика, аппараты, инъекции и инфузии в одном протоколе.',
            style: TextStyle(color: Cult.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          CultCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AboutRow(
                  Icons.place_outlined,
                  'Сочи, Черноморская, 6',
                  onTap: () => openExternal(
                    'https://maps.google.com/?q=${Uri.encodeComponent('Сочи, Черноморская, 6')}',
                    context: context,
                  ),
                ),
                const Divider(height: 20),
                const _AboutRow(Icons.schedule, 'Ежедневно 9:00–21:00'),
                const Divider(height: 20),
                _AboutRow(
                  Icons.phone_outlined,
                  '+7 495 000-00-07',
                  onTap: () =>
                      openExternal('tel:+74950000007', context: context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const CultSectionLabel('Как добраться'),
          const SizedBox(height: 8),
          const Text(
            'Клиника на Черноморской, 6. Парковка для гостей у входа.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Скопировать адрес'),
                onPressed: () {
                  Clipboard.setData(
                    const ClipboardData(text: 'Сочи, Черноморская, 6'),
                  );
                  cultTapFeedback();
                  showCultSnack(context, 'Адрес скопирован');
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.directions_car_outlined, size: 18),
                label: const Text('Трансфер'),
                onPressed: () {
                  cultTapFeedback();
                  pushPage(context, const TransferPage());
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const CultSectionLabel('Документы'),
          const SizedBox(height: 8),
          const Text(
            'Публичная оферта, согласие на процедуры и политика данных. Имя, визиты и заказы хранятся на телефоне.',
            style: TextStyle(color: Cult.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          CultButton(
            label: 'Записаться',
            onPressed: () => pushPage(context, const BookingPage()),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Cult.ink,
              side: const BorderSide(color: Cult.ink),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () {
              cultTapFeedback();
              openExternal(
                'https://www.youtube.com/results?search_query=CULT+Clinic',
                context: context,
              );
            },
            child: const Text('CULT TV · YouTube'),
          ),
          TextButton(
            onPressed: () {
              cultTapFeedback();
              openExternal('https://t.me/cultclinic', context: context);
            },
            child: const Text('Telegram'),
          ),
          TextButton(
            onPressed: () {
              cultTapFeedback();
              openExternal('https://wa.me/74950000007', context: context);
            },
            child: const Text('WhatsApp'),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow(this.icon, this.text, {this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(icon, color: Cult.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        if (onTap != null)
          const Icon(Icons.chevron_right, color: Cult.muted, size: 20),
      ],
    );
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              cultTapFeedback();
              onTap!();
            },
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: text));
        cultTapFeedback();
        showCultSnack(context, 'Скопировано');
      },
      child: row,
    );
  }
}

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needle = _query.text.trim().toLowerCase();
    final list = articles.where((article) {
      if (needle.isEmpty) return true;
      return article.title.toLowerCase().contains(needle) ||
          article.author.toLowerCase().contains(needle) ||
          article.kicker.toLowerCase().contains(needle);
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Блог')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text('CULT TV', style: cultHeadline(28)),
            const SizedBox(height: 6),
            const Text(
              'Короткие разборы протоколов и новости клиники.',
              style: TextStyle(color: Cult.muted),
            ),
            const SizedBox(height: 14),
            CultSearchField(
              controller: _query,
              hint: 'Найти материал',
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (list.isNotEmpty)
              Text(
                '${list.length} материал${list.length == 1 ? '' : 'ов'}',
                style: const TextStyle(color: Cult.muted, fontSize: 12),
              ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              CultEmpty(
                title: 'Ничего не найдено',
                note: 'Смягчите запрос или сбросьте поиск.',
                actionLabel: 'Сбросить',
                onAction: () {
                  _query.clear();
                  setState(() {});
                },
              )
            else
              for (final article in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Semantics(
                    button: true,
                    label: '${article.title}, ${article.author}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        cultTapFeedback();
                        pushPage(context, ArticlePage(article: article));
                      },
                      onLongPress: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: '${article.title} — ${article.author}',
                          ),
                        );
                        cultTapFeedback();
                        showCultSnack(context, 'Материал скопирован');
                      },
                      child: CultCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CultImage(
                              article.image,
                              aspect: 16 / 9,
                              radius: 16,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.kicker.toUpperCase(),
                                    style: const TextStyle(
                                      color: Cult.primary,
                                      letterSpacing: 1.1,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    article.title,
                                    style: cultHeadline(22),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    article.author,
                                    style: const TextStyle(
                                      color: Cult.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
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
      appBar: AppBar(title: const Text('CULT TV')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          CultImage(article.image, aspect: 16 / 9, radius: 16),
          const SizedBox(height: 14),
          Text(
            article.kicker.toUpperCase(),
            style: const TextStyle(
              color: Cult.primary,
              letterSpacing: 1.2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(
                ClipboardData(text: '${article.title} — ${article.author}'),
              );
              cultTapFeedback();
              showCultSnack(context, 'Заголовок скопирован');
            },
            child: Text(article.title, style: cultHeadline(28)),
          ),
          const SizedBox(height: 4),
          Text(article.author, style: const TextStyle(color: Cult.muted)),
          const SizedBox(height: 16),
          for (final paragraph in article.body)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(paragraph, style: const TextStyle(height: 1.45)),
            ),
          CultButton(
            label: 'Смотреть на YouTube',
            onPressed: () => openExternal(
              'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${article.title} CULT Clinic')}',
              context: context,
            ),
          ),
          TextButton(
            onPressed: () {
              final store = ClinicScope.of(context);
              store.sendMessage(
                'specialist',
                'Вопрос после материала «${article.title}».',
              );
              cultTapFeedback();
              showCultSnack(
                context,
                'Сообщение врачу отправлено — откройте Чат',
              );
            },
            child: const Text('Спросить врача по теме'),
          ),
        ],
      ),
      bottomNavigationBar: CultBookBar(
        label: 'Записаться на консультацию',
        onPressed: () => pushPage(context, const BookingPage()),
      ),
    );
  }
}

class CasesPage extends StatefulWidget {
  const CasesPage({super.key});

  @override
  State<CasesPage> createState() => _CasesPageState();
}

class _CasesPageState extends State<CasesPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needle = _query.text.trim().toLowerCase();
    final list = cases.where((item) {
      if (needle.isEmpty) return true;
      return item.title.toLowerCase().contains(needle) ||
          item.procedure.toLowerCase().contains(needle) ||
          item.doctor.toLowerCase().contains(needle);
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Кейсы')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text('Клинические кейсы', style: cultHeadline(28)),
            const SizedBox(height: 6),
            const Text(
              'Результаты протоколов CULT в филиале Сочи.',
              style: TextStyle(color: Cult.muted),
            ),
            const SizedBox(height: 14),
            CultSearchField(
              controller: _query,
              hint: 'Процедура или врач',
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (list.isNotEmpty)
              Text(
                '${list.length} кейс${list.length == 1 ? '' : 'ов'}',
                style: const TextStyle(color: Cult.muted, fontSize: 12),
              ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              CultEmpty(
                title: 'Ничего не найдено',
                note: 'Смягчите запрос или сбросьте поиск.',
                actionLabel: 'Сбросить',
                onAction: () {
                  _query.clear();
                  setState(() {});
                },
              )
            else
              for (final item in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Semantics(
                    button: true,
                    label: '${item.title}, ${item.procedure}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        cultTapFeedback();
                        pushPage(context, CasePage(item: item));
                      },
                      onLongPress: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                '${item.title} · ${item.procedure} · ${item.doctor}',
                          ),
                        );
                        cultTapFeedback();
                        showCultSnack(context, 'Кейс скопирован');
                      },
                      child: CultCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CultImage(item.image, aspect: 4 / 3, radius: 16),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: cultHeadline(22)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.procedure} · ${item.doctor}',
                                    style: const TextStyle(color: Cult.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class CasePage extends StatelessWidget {
  const CasePage({super.key, required this.item});

  final ClinicCase item;

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('CULT')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(
                ClipboardData(
                  text:
                      '${item.title} · ${item.procedure} · ${item.doctor} · CULT',
                ),
              );
              cultTapFeedback();
              showCultSnack(context, 'Кейс скопирован');
            },
            child: Text(item.title, style: cultHeadline(28)),
          ),
          Text(
            '${item.procedure} · ${item.doctor}',
            style: const TextStyle(color: Cult.muted),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              store.sendMessage(
                'specialist',
                'Вопрос по кейсу «${item.title}» (${item.procedure}).',
              );
              cultTapFeedback();
              showCultSnack(
                context,
                'Сообщение врачу отправлено — откройте Чат',
              );
            },
            child: const Text('Спросить врача о результате'),
          ),
          const SizedBox(height: 8),
          const CultSectionLabel('До'),
          const SizedBox(height: 8),
          const CultImage('before', aspect: 4 / 3, radius: 16),
          const SizedBox(height: 14),
          const CultSectionLabel('После'),
          const SizedBox(height: 8),
          CultImage(item.image, aspect: 4 / 3, radius: 16),
          const SizedBox(height: 16),
          Text(
            item.text,
            style: const TextStyle(height: 1.4, color: Cult.muted),
          ),
        ],
      ),
      bottomNavigationBar: CultBookBar(
        onPressed: () => pushPage(
          context,
          BookingPage(
            initialService: item.procedure,
            initialDoctor: item.doctor,
          ),
        ),
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
    final store = ClinicScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Трансфер')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text('VIP-такси до клиники', style: cultHeadline(28)),
            const SizedBox(height: 8),
            const Text(
              'Адрес клиники: Сочи, Черноморская, 6. Машина подаётся к указанному адресу.',
              style: TextStyle(color: Cult.muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Скопировать адрес клиники'),
                onPressed: () {
                  Clipboard.setData(
                    const ClipboardData(text: 'Сочи, Черноморская, 6'),
                  );
                  cultTapFeedback();
                  showCultSnack(context, 'Адрес скопирован');
                },
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _done
                ? CultCard(
                    key: const ValueKey('transfer-done'),
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
                            Icons.directions_car,
                            color: Cult.primary,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('Заявка принята', style: cultHeadline(22)),
                        const SizedBox(height: 8),
                        Text(
                          'Заберём с «${_from.text.trim()}». Водитель напишет в чат администратора.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Cult.muted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        CultButton(
                          label: 'Открыть чат',
                          onPressed: () => pushPage(
                            context,
                            const ChatThreadPage(contactId: 'admin'),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    key: const ValueKey('transfer-form'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _from,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Откуда забрать',
                          hintText: 'Отель, аэропорт или адрес',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final place in const [
                            'Аэропорт Сочи',
                            'ЖД вокзал',
                            'Отель Rixos',
                          ])
                            ActionChip(
                              label: Text(place),
                              onPressed: () {
                                cultTapFeedback();
                                setState(() {
                                  _from.text = place;
                                  _error = '';
                                });
                              },
                            ),
                        ],
                      ),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        CultErrorBanner(message: _error),
                      ],
                      const SizedBox(height: 12),
                      CultButton(
                        label: 'Заказать',
                        onPressed: () {
                          if (_from.text.trim().length < 5) {
                            setState(
                              () => _error = 'Укажите адрес, откуда забрать.',
                            );
                            return;
                          }
                          store.sendMessage(
                            'admin',
                            'Трансфер: забрать с «${_from.text.trim()}» → Черноморская, 6.',
                          );
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _error = '';
                            _done = true;
                          });
                        },
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
