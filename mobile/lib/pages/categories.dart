import 'package:flutter/material.dart';

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
          body: const Center(child: Text('Раздел не найден')),
        ),
    };
  }
}

class HardwareCosmeticsPage extends StatelessWidget {
  const HardwareCosmeticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CULT')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Cult.ink,
        foregroundColor: Colors.white,
        onPressed: () => pushPage(context, const BookingPage()),
        child: const Icon(Icons.calendar_month_outlined),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          CultImage('science', aspect: 4 / 5, radius: 18),
          const SizedBox(height: 18),
          Text('Аппаратная\nкосметология', style: cultHeadline(34), textAlign: TextAlign.center),
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
              Chip(label: const Text('ЛИЦО'), backgroundColor: Cult.ink, labelStyle: const TextStyle(color: Colors.white, letterSpacing: 1.2)),
              const SizedBox(width: 8),
              const Chip(label: Text('ТЕЛО')),
            ],
          ),
          const SizedBox(height: 22),
          Text('ПРОЦЕДУРЫ', style: cultHeadline(18).copyWith(letterSpacing: 2, color: Cult.primary), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          for (final device in devices) ...[
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => pushPage(context, DevicePage(device: device)),
              child: CultCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CultImage(device.image, aspect: 16 / 10, radius: 16),
                        if (device.badge.isNotEmpty)
                          Positioned(
                            left: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Cult.primary, borderRadius: BorderRadius.circular(20)),
                              child: Text(device.badge.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1)),
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
                              Expanded(child: Text(device.title, style: cultHeadline(22))),
                              Text(device.price, style: const TextStyle(color: Cult.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(device.text, style: const TextStyle(color: Cult.muted, height: 1.35)),
                          const SizedBox(height: 10),
                          Text('${device.meta} · ${device.tag}', style: const TextStyle(color: Cult.muted, fontSize: 12, letterSpacing: 0.8)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: Cult.primary, borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                Text('Готовы к преображению?', style: cultHeadline(24).copyWith(color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Запишитесь на консультацию.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Cult.ink),
                  onPressed: () => pushPage(context, const BookingPage()),
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

class InjectionCosmeticsPage extends StatelessWidget {
  const InjectionCosmeticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final items = store.catalogServices.where((s) {
      final t = '${s.category} ${s.group} ${s.title}'.toLowerCase();
      return t.contains('инъек') || t.contains('бот') || t.contains('мезо') || t.contains('контур');
    }).toList();
    final fallback = services.where((s) => s.group == 'Инъекции').toList();
    final list = items.isEmpty ? fallback : items;

    return Scaffold(
      appBar: AppBar(title: const Text('CULT')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Cult.primary,
        foregroundColor: Colors.white,
        onPressed: () => pushPage(context, const BookingPage()),
        icon: const Icon(Icons.calendar_month_outlined),
        label: const Text('Записаться'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Stack(
            children: [
              CultImage('botox', aspect: 4 / 5, radius: 18),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Text('Инъекционная\nкосметология', style: cultHeadline(30).copyWith(color: Colors.white, shadows: const [Shadow(blurRadius: 10, color: Colors.black54)])),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Естественное преображение с медицинской точностью.', style: TextStyle(color: Cult.muted, height: 1.4)),
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
                      Text('Стандарт безопасности CULT', style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Сертифицированные препараты и врачи высшей категории.', style: TextStyle(color: Cult.muted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Услуги', style: cultHeadline(22)),
          const SizedBox(height: 10),
          for (final service in list) ...[
            InkWell(
              onTap: () => pushPage(context, BookingPage(initialService: service.title)),
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
                              Expanded(child: Text(service.title, style: cultHeadline(20))),
                              Text(service.priceLabel, style: const TextStyle(color: Cult.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${service.duration} · ${service.category}', style: const TextStyle(color: Cult.muted, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(service.blurb, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Cult.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
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
  var _chip = 'Energy';

  @override
  Widget build(BuildContext context) {
    final chips = const ['Energy', 'Detox', 'Longevity', 'Beauty'];
    final list = infusions.where((item) => _chip == 'Longevity' ? true : item.chip == _chip || (_chip == 'Energy' && item.chip == 'Energy')).toList();
    final shown = _chip == 'Longevity' || _chip == 'Detox' || _chip == 'Beauty' || _chip == 'Energy'
        ? infusions.where((item) {
            if (_chip == 'Energy') return item.chip == 'Energy';
            if (_chip == 'Detox') return item.chip == 'Detox';
            if (_chip == 'Beauty') return item.chip == 'Beauty';
            return true;
          }).toList()
        : list;

    return Scaffold(
      appBar: AppBar(title: const Text('CULT')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Инфузионная терапия', style: cultHeadline(30), textAlign: TextAlign.center),
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
                  onSelected: (_) => setState(() => _chip = chip),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          for (final item in shown) ...[
            CultCard(
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
                            Expanded(child: Text(item.title, style: cultHeadline(22))),
                            Text(item.price, style: const TextStyle(color: Cult.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(item.blurb, style: const TextStyle(color: Cult.muted)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 16, color: Cult.muted),
                            const SizedBox(width: 4),
                            Text(item.duration, style: const TextStyle(color: Cult.muted)),
                            const Spacer(),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Cult.ink, shape: const StadiumBorder()),
                              onPressed: () => pushPage(context, BookingPage(initialService: item.title)),
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
            const SizedBox(height: 12),
          ],
          CultCard(
            child: Column(
              children: [
                Text('Нужна консультация?', style: cultHeadline(20)),
                const SizedBox(height: 6),
                const Text('Подберём коктейль под ваши задачи.', textAlign: TextAlign.center, style: TextStyle(color: Cult.muted)),
                TextButton(
                  onPressed: () => pushPage(context, const ChatThreadPage(contactId: 'specialist')),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text('АКТУАЛЬНОЕ', style: TextStyle(color: Cult.secondary, letterSpacing: 1.6, fontSize: 11)),
          const SizedBox(height: 8),
          Text('Будущее клеточной регенерации', style: cultHeadline(28)),
          const SizedBox(height: 8),
          const Text('Короткие разборы протоколов CULT.', style: TextStyle(color: Cult.muted)),
          const SizedBox(height: 12),
          CultButton(label: 'Читать исследование', onPressed: () => pushPage(context, ArticlePage(article: articles.first))),
          const SizedBox(height: 22),
          Row(
            children: [
              Text('Клинические исследования', style: cultHeadline(20)),
              const Spacer(),
              TextButton(onPressed: () => pushPage(context, const BlogPage()), child: const Text('Смотреть все')),
            ],
          ),
          for (final title in const ['Терапия удлинения теломер', 'Микродозы пептидов', 'Ось микробиом-кожа'])
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CultCard(child: Text(title, style: cultHeadline(18))),
            ),
          const SizedBox(height: 18),
          Text('Новые технологии', style: cultHeadline(20)),
          const SizedBox(height: 8),
          for (final device in devices.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => pushPage(context, DevicePage(device: device)),
                child: CultCard(
                  child: Row(
                    children: [
                      Expanded(child: Text(device.title, style: cultHeadline(18))),
                      const Text('Открыть', style: TextStyle(color: Cult.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text('Протоколы долголетия', style: cultHeadline(20)),
          const SizedBox(height: 8),
          for (final row in const [
            ('Уровень 01', 'Циркадная перезагрузка'),
            ('Уровень 02', 'Обогащение NAD+'),
            ('Уровень 03', 'Сенолитическое очищение'),
            ('Золотой уровень', 'Генная модуляция'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CultCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.$1, style: const TextStyle(color: Cult.muted, fontSize: 12, letterSpacing: 1)),
                          Text(row.$2, style: cultHeadline(18)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Cult.muted),
                  ],
                ),
              ),
            ),
          TextButton(onPressed: () => pushPage(context, const CasesPage()), child: const Text('Клинические кейсы')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Аппарат')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          CultImage(device.image, aspect: 16 / 10, radius: 18),
          const SizedBox(height: 14),
          const Text('ADVANCED HARDWARE', style: TextStyle(color: Cult.secondary, letterSpacing: 1.5, fontSize: 11)),
          const SizedBox(height: 6),
          Text(device.title, style: cultHeadline(32)),
          Text(device.text, style: const TextStyle(color: Cult.muted, height: 1.35)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Meta(Icons.schedule, device.meta),
              _Meta(Icons.place_outlined, device.zone),
              _Meta(Icons.payments_outlined, device.price),
            ],
          ),
          if (device.indications.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Показания', style: cultHeadline(22)),
            for (final item in device.indications)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text('· $item')),
          ],
          if (device.benefits.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Преимущества', style: cultHeadline(22)),
            for (final item in device.benefits)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Cult.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 20),
          CultButton(label: 'Записаться', onPressed: () => pushPage(context, BookingPage(initialService: device.title))),
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
        Text(text.toUpperCase(), style: const TextStyle(color: Cult.muted, fontSize: 12, letterSpacing: 0.8)),
      ],
    );
  }
}
