import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'info.dart';
import 'talk.dart';

class CategoryHubPage extends StatelessWidget {
  const CategoryHubPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return switch (slug) {
      'hardware' => const HardwareCosmeticsPage(),
      'injections' => const InjectionCosmeticsPage(),
      'infusions' => const InfusionTherapyPage(),
      'science' => const SciencePage(),
      _ => Scaffold(
        appBar: AppBar(title: const Text('CULT')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            CultEmpty(
              title: 'Раздел не найден',
              note: 'Откройте услуги из меню или с главной.',
            ),
          ],
        ),
      ),
    };
  }
}

class HardwareCosmeticsPage extends StatefulWidget {
  const HardwareCosmeticsPage({super.key});

  @override
  State<HardwareCosmeticsPage> createState() => _HardwareCosmeticsPageState();
}

class _HardwareCosmeticsPageState extends State<HardwareCosmeticsPage> {
  final _query = TextEditingController();
  var _zone = 'Лицо';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matchesZone(Device device) {
    final zone = device.zone.toLowerCase();
    return switch (_zone) {
      'Тело' => zone.contains('тело'),
      'Лицо' =>
        zone.contains('лицо') || zone.contains('шея') || !zone.contains('тело'),
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final needle = _query.text.trim().toLowerCase();
    final filtered = devices.where((device) {
      if (!_matchesZone(device)) return false;
      if (needle.isEmpty) return true;
      final hay =
          '${device.title} ${device.zone} ${device.badge} ${device.text}'
              .toLowerCase();
      return hay.contains(needle);
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('CULT')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Cult.ink,
        foregroundColor: Colors.white,
        tooltip: 'Запись',
        onPressed: () {
          cultTapFeedback();
          pushPage(context, const BookingPage());
        },
        child: const Icon(Icons.calendar_month_outlined),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          const CultImage('science', aspect: 4 / 5, radius: 18),
          const SizedBox(height: 18),
          Text(
            'Аппаратная\nкосметология',
            style: cultHeadline(34),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'RF, IPL и SMAS-лифтинг. Результат без долгой реабилитации.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Cult.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final zone in const ['Лицо', 'Тело']) ...[
                if (zone != 'Лицо') const SizedBox(width: 8),
                FilterChip(
                  label: Text(zone.toUpperCase()),
                  selected: _zone == zone,
                  showCheckmark: false,
                  selectedColor: Cult.ink,
                  labelStyle: TextStyle(
                    color: _zone == zone ? Colors.white : Cult.ink,
                    letterSpacing: 1.2,
                  ),
                  backgroundColor: const Color(0xFFF3EFEA),
                  side: BorderSide.none,
                  onSelected: (_) {
                    cultTapFeedback();
                    setState(() => _zone = zone);
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          CultSearchField(
            controller: _query,
            hint: 'Найти аппарат',
            onChanged: () => setState(() {}),
          ),
          if (filtered.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  final text = filtered
                      .map(
                        (device) =>
                            '· ${device.title} — ${device.price} (${device.meta})',
                      )
                      .join('\n');
                  Clipboard.setData(
                    ClipboardData(text: 'Аппаратная CULT\n$text'),
                  );
                  cultTapFeedback();
                  showCultSnack(context, 'Список скопирован');
                },
                child: Text('Скопировать список · ${filtered.length}'),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            'ПРОЦЕДУРЫ',
            style: cultHeadline(
              18,
            ).copyWith(letterSpacing: 2, color: Cult.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            CultEmpty(
              title: needle.isEmpty
                  ? 'Аппараты для тела скоро'
                  : 'Ничего не найдено',
              note: needle.isEmpty
                  ? 'Запишитесь — подберём протокол для тела в филиале.'
                  : 'Смягчите запрос или сбросьте поиск.',
              actionLabel: needle.isEmpty ? 'Записаться' : 'Сбросить',
              onAction: () {
                if (needle.isEmpty) {
                  pushPage(context, const BookingPage());
                  return;
                }
                _query.clear();
                setState(() {});
              },
            )
          else
            for (final device in filtered) ...[
              Semantics(
                button: true,
                label: '${device.title}, ${device.price}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    cultTapFeedback();
                    pushPage(context, DevicePage(device: device));
                  },
                  onLongPress: () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            '${device.title} · ${device.price} · ${device.meta}',
                      ),
                    );
                    cultTapFeedback();
                    showCultSnack(context, 'Процедура скопирована');
                  },
                  child: CultCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            CultImage(
                              device.image,
                              aspect: 16 / 10,
                              radius: 16,
                            ),
                            if (device.badge.isNotEmpty)
                              Positioned(
                                left: 12,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Cult.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    device.badge.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      device.title,
                                      style: cultHeadline(22),
                                    ),
                                  ),
                                  Text(
                                    device.price,
                                    style: const TextStyle(
                                      color: Cult.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                device.text,
                                style: const TextStyle(
                                  color: Cult.muted,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${device.meta} · ${device.tag}',
                                style: const TextStyle(
                                  color: Cult.muted,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
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
              const SizedBox(height: 14),
            ],
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Cult.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  'Готовы к преображению?',
                  style: cultHeadline(24).copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Запишитесь на консультацию к нашим экспертам сегодня.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Cult.ink,
                  ),
                  onPressed: () {
                    cultTapFeedback();
                    pushPage(context, const BookingPage());
                  },
                  child: const Text('ЗАПИСАТЬСЯ'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InjectionCosmeticsPage extends StatefulWidget {
  const InjectionCosmeticsPage({super.key});

  @override
  State<InjectionCosmeticsPage> createState() => _InjectionCosmeticsPageState();
}

class _InjectionCosmeticsPageState extends State<InjectionCosmeticsPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final items = store.catalogServices.where((s) {
      final t = '${s.category} ${s.group} ${s.title}'.toLowerCase();
      return t.contains('инъек') ||
          t.contains('бот') ||
          t.contains('мезо') ||
          t.contains('контур');
    }).toList();
    final fallback = services.where((s) => s.group == 'Инъекции').toList();
    final base = items.isEmpty ? fallback : items;
    final needle = _query.text.trim().toLowerCase();
    final list = needle.isEmpty
        ? base
        : base
              .where(
                (s) =>
                    s.title.toLowerCase().contains(needle) ||
                    s.category.toLowerCase().contains(needle) ||
                    s.blurb.toLowerCase().contains(needle),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('CULT')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Cult.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          cultTapFeedback();
          pushPage(context, const BookingPage());
        },
        icon: const Icon(Icons.calendar_month_outlined),
        label: const Text('Записаться'),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            Stack(
              children: [
                const CultImage('botox', aspect: 4 / 5, radius: 18),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Text(
                    'Инъекционная\nкосметология',
                    style: cultHeadline(30).copyWith(
                      color: Colors.white,
                      shadows: const [
                        Shadow(blurRadius: 10, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Естественное преображение с медицинской точностью.',
              style: TextStyle(color: Cult.muted, height: 1.4),
            ),
            const SizedBox(height: 14),
          CultCard(
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: Cult.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Стандарт безопасности CULT',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Сертифицированные препараты и врачи высшей категории.',
                        style: TextStyle(color: Cult.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Услуги', style: cultHeadline(22)),
          const SizedBox(height: 10),
          CultSearchField(
            controller: _query,
            hint: 'Найти инъекцию',
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (list.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${list.length} услуг',
                style: const TextStyle(color: Cult.muted, fontSize: 12),
              ),
            ),
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
            for (final service in list) ...[
              Semantics(
                button: true,
                label: '${service.title}, ${service.priceLabel}',
                child: InkWell(
                  onTap: () {
                    cultTapFeedback();
                    pushPage(
                      context,
                      BookingPage(initialService: service.title),
                    );
                  },
                  onLongPress: () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            '${service.title} · ${service.priceLabel} · CULT',
                      ),
                    );
                    cultTapFeedback();
                    showCultSnack(context, 'Услуга скопирована');
                  },
                  child: CultCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CultImage(service.image, aspect: 4 / 3, radius: 16),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      service.title,
                                      style: cultHeadline(20),
                                    ),
                                  ),
                                  Text(
                                    service.priceLabel,
                                    style: const TextStyle(
                                      color: Cult.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${service.duration} · ${service.category}',
                                style: const TextStyle(
                                  color: Cult.muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                service.blurb,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class InfusionTherapyPage extends StatefulWidget {
  const InfusionTherapyPage({super.key});

  @override
  State<InfusionTherapyPage> createState() => _InfusionTherapyPageState();
}

class _InfusionTherapyPageState extends State<InfusionTherapyPage> {
  final _query = TextEditingController();
  var _chip = 'Energy';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chips = const ['Energy', 'Detox', 'Longevity', 'Beauty'];
    final needle = _query.text.trim().toLowerCase();
    final list = infusions
        .where(
          (item) => _chip == 'Longevity'
              ? true
              : item.chip == _chip ||
                    (_chip == 'Energy' && item.chip == 'Energy'),
        )
        .toList();
    final byChip =
        _chip == 'Longevity' ||
            _chip == 'Detox' ||
            _chip == 'Beauty' ||
            _chip == 'Energy'
        ? infusions.where((item) {
            if (_chip == 'Energy') return item.chip == 'Energy';
            if (_chip == 'Detox') return item.chip == 'Detox';
            if (_chip == 'Beauty') return item.chip == 'Beauty';
            return true;
          }).toList()
        : list;
    final shown = needle.isEmpty
        ? byChip
        : byChip
              .where(
                (item) =>
                    item.title.toLowerCase().contains(needle) ||
                    item.blurb.toLowerCase().contains(needle) ||
                    item.chip.toLowerCase().contains(needle),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('CULT')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Инфузионная терапия',
            style: cultHeadline(30),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Коктейли нутриентов для восстановления и клеточного здоровья.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Cult.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final chip = chips[index];
                final selected = _chip == chip;
                return ChoiceChip(
                  label: Text(chip.toUpperCase()),
                  selected: selected,
                  onSelected: (_) {
                    cultTapFeedback();
                    setState(() => _chip = chip);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          CultSearchField(
            controller: _query,
            hint: 'Найти коктейль',
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (shown.isEmpty)
            CultEmpty(
              title: needle.isEmpty ? 'В этой группе пусто' : 'Ничего не найдено',
              note: needle.isEmpty
                  ? 'Выберите другую категорию коктейлей.'
                  : 'Смягчите запрос или сбросьте поиск.',
              actionLabel: needle.isEmpty ? 'Все' : 'Сбросить',
              onAction: () {
                if (needle.isEmpty) {
                  setState(() => _chip = 'Longevity');
                  return;
                }
                _query.clear();
                setState(() {});
              },
            )
          else
            for (final item in shown) ...[
              Semantics(
                button: true,
                label: '${item.title}, ${item.price}',
                child: GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: '${item.title} · ${item.price} · ${item.duration}',
                      ),
                    );
                    cultTapFeedback();
                    showCultSnack(context, 'Коктейль скопирован');
                  },
                  child: CultCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CultImage(item.image, aspect: 16 / 10, radius: 16),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: cultHeadline(22),
                                    ),
                                  ),
                                  Text(
                                    item.price,
                                    style: const TextStyle(
                                      color: Cult.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.blurb,
                                style: const TextStyle(color: Cult.muted),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: Cult.muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.duration,
                                    style: const TextStyle(color: Cult.muted),
                                  ),
                                  const Spacer(),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Cult.ink,
                                      shape: const StadiumBorder(),
                                    ),
                                    onPressed: () {
                                      cultTapFeedback();
                                      pushPage(
                                        context,
                                        BookingPage(
                                          initialService: item.title,
                                        ),
                                      );
                                    },
                                    child: const Text('ЗАБРОНИРОВАТЬ'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          CultCard(
            child: Column(
              children: [
                Text('Нужна консультация?', style: cultHeadline(20)),
                const SizedBox(height: 6),
                const Text(
                  'Подберём коктейль под ваши задачи.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Cult.muted),
                ),
                TextButton(
                  onPressed: () {
                    cultTapFeedback();
                    pushPage(
                      context,
                      const ChatThreadPage(contactId: 'specialist'),
                    );
                  },
                  child: const Text('НАПИСАТЬ СПЕЦИАЛИСТУ'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SciencePage extends StatelessWidget {
  const SciencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Наука')),
      bottomNavigationBar: CultBookBar(
        label: 'Консультация по протоколу',
        onPressed: () => pushPage(context, const BookingPage()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const CultImage('science', aspect: 16 / 9, radius: 18),
          const SizedBox(height: 16),
          const Text(
            'АКТУАЛЬНОЕ',
            style: TextStyle(
              color: Cult.secondary,
              letterSpacing: 1.6,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(
                const ClipboardData(
                  text: 'Будущее клеточной регенерации · CULT Clinic',
                ),
              );
              cultTapFeedback();
              showCultSnack(context, 'Заголовок скопирован');
            },
            child: Text(
              'Будущее клеточной регенерации',
              style: cultHeadline(28),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Короткие разборы протоколов CULT.',
            style: TextStyle(color: Cult.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          CultButton(
            label: 'Читать исследование',
            onPressed: () =>
                pushPage(context, ArticlePage(article: articles.first)),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: CultSectionLabel('Клинические исследования'),
              ),
              TextButton(
                onPressed: () {
                  cultTapFeedback();
                  pushPage(context, const BlogPage());
                },
                child: const Text('Смотреть все'),
              ),
            ],
          ),
          for (final title in const [
            'Терапия удлинения теломер',
            'Микродозы пептидов',
            'Ось микробиом-кожа',
          ])
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  cultTapFeedback();
                  pushPage(context, const BlogPage());
                },
                child: CultCard(
                  child: Row(
                    children: [
                      Expanded(child: Text(title, style: cultHeadline(18))),
                      const Icon(Icons.chevron_right, color: Cult.muted),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          const CultSectionLabel('Новые технологии'),
          const SizedBox(height: 8),
          for (final device in devices.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  cultTapFeedback();
                  pushPage(context, DevicePage(device: device));
                },
                child: CultCard(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: CultImage(device.image, aspect: 1, radius: 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(device.title, style: cultHeadline(18)),
                      ),
                      const Text(
                        'Открыть',
                        style: TextStyle(
                          color: Cult.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const CultSectionLabel('Протоколы долголетия'),
          const SizedBox(height: 8),
          for (final row in const [
            ('Уровень 01', 'Циркадная перезагрузка'),
            ('Уровень 02', 'Обогащение NAD+'),
            ('Уровень 03', 'Сенолитическое очищение'),
            ('Золотой уровень', 'Генная модуляция'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                button: true,
                label: '${row.$1}, ${row.$2}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    cultTapFeedback();
                    pushPage(context, BookingPage(initialService: row.$2));
                  },
                  onLongPress: () {
                    Clipboard.setData(
                      ClipboardData(text: '${row.$2} · CULT longevity'),
                    );
                    cultTapFeedback();
                    showCultSnack(context, 'Протокол скопирован');
                  },
                  child: CultCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.$1.toUpperCase(),
                                style: const TextStyle(
                                  color: Cult.muted,
                                  fontSize: 11,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(row.$2, style: cultHeadline(18)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Cult.muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          CultButton(
            label: 'Клинические кейсы',
            onPressed: () => pushPage(context, const CasesPage()),
          ),
        ],
      ),
    );
  }
}

class DevicePage extends StatelessWidget {
  const DevicePage({super.key, required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final summary =
        '${device.title} · ${device.price} · ${device.meta} · CULT Сочи';
    return Scaffold(
      appBar: AppBar(title: const Text('CULT')),
      bottomNavigationBar: CultBookBar(
        label: device.price.isEmpty
            ? 'Записаться'
            : 'Записаться · ${device.price}',
        onPressed: () =>
            pushPage(context, BookingPage(initialService: device.title)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          CultImage(device.image, aspect: 16 / 10, radius: 18),
          const SizedBox(height: 14),
          const Text(
            'ADVANCED HARDWARE',
            style: TextStyle(
              color: Cult.secondary,
              letterSpacing: 1.5,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: summary));
              cultTapFeedback();
              showCultSnack(context, 'Процедура скопирована');
            },
            child: Text(device.title, style: cultHeadline(32)),
          ),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: device.text));
              cultTapFeedback();
              showCultSnack(context, 'Описание скопировано');
            },
            child: Text(
              device.text,
              style: const TextStyle(color: Cult.muted, height: 1.35),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              store.sendMessage(
                'specialist',
                'Вопрос по аппарату «${device.title}» (${device.price}).',
              );
              cultTapFeedback();
              pushPage(
                context,
                const ChatThreadPage(contactId: 'specialist'),
              );
            },
            child: const Text('Спросить врача'),
          ),
          TextButton(
            onPressed: () {
              final bits = <String>[
                summary,
                if (device.text.isNotEmpty) device.text,
                if (device.indications.isNotEmpty)
                  'Показания: ${device.indications.join(', ')}',
                if (device.benefits.isNotEmpty)
                  'Эффект: ${device.benefits.join(', ')}',
              ];
              Clipboard.setData(ClipboardData(text: bits.join('\n')));
              cultTapFeedback();
              showCultSnack(context, 'Карточка скопирована');
            },
            child: const Text('Скопировать карточку'),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Meta(Icons.schedule, device.meta),
              _Meta(Icons.place_outlined, device.zone),
              _Meta(Icons.payments_outlined, device.price),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFEA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text('98%', style: cultHeadline(22)),
                      const Text(
                        'ДОВОЛЬНЫХ',
                        style: TextStyle(
                          color: Cult.muted,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFEA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text('2–3 года', style: cultHeadline(22)),
                      const Text(
                        'СТОЙКИЙ ЭФФЕКТ',
                        style: TextStyle(
                          color: Cult.muted,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (device.indications.isNotEmpty) ...[
            const SizedBox(height: 20),
            const CultSectionLabel('Показания'),
            for (final item in device.indications)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: item));
                    cultTapFeedback();
                    showCultSnack(context, 'Показание скопировано');
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Cult.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(item, style: const TextStyle(height: 1.35)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (device.benefits.isNotEmpty) ...[
            const SizedBox(height: 18),
            const CultSectionLabel('Преимущества'),
            for (final item in device.benefits)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: item));
                    cultTapFeedback();
                    showCultSnack(context, 'Пункт скопирован');
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Cult.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item, style: const TextStyle(height: 1.35)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Cult.muted),
        const SizedBox(width: 4),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Cult.muted,
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
