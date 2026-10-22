import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'browse.dart';
import 'cabinet.dart';
import 'info.dart';
import 'talk.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final next = store.upcoming.isEmpty ? null : store.upcoming.first;
    final first = store.displayName.trim().split(RegExp(r'\s+')).first;
    final hello = first.isEmpty ? 'Добрый день' : first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text('Сочи · Черноморская, 6', style: const TextStyle(color: Cult.muted, letterSpacing: 0.3)),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => pushPage(context, const VisitsPage()),
          child: CultCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.gender == null ? 'ПЛАТИНОВЫЙ СТАТУС' : store.gender!.servicesTitle.toUpperCase(),
                  style: const TextStyle(color: Cult.secondary, letterSpacing: 1.2, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(hello, style: cultHeadline(28)),
                const SizedBox(height: 8),
                Text(next == null ? 'Ближайшей записи нет. Можно выбрать услугу и врача.' : 'Дальше: ${next.service}, ${formatVisitDate(next.date)} в ${next.time}.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            _Quick(
              icon: Icons.calendar_month,
              label: 'Запись онлайн',
              filled: true,
              onTap: () => pushPage(context, const BookingPage()),
            ),
            _Quick(icon: Icons.biotech, label: 'Мои анализы', onTap: () => pushPage(context, const AnalysesPage())),
            _Quick(icon: Icons.shopping_basket_outlined, label: 'Биохакерский магазин', onTap: onShop),
            _Quick(icon: Icons.forum_outlined, label: 'Чат с доктором', onTap: () => pushPage(context, const ChatThreadPage(contactId: 'specialist'))),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ChipLink('Врачи', () => pushPage(context, const DoctorsPage())),
            _ChipLink('Прайс', () => pushPage(context, const PricesPage())),
            _ChipLink('Блог', () => pushPage(context, const BlogPage())),
            _ChipLink('Кейсы', () => pushPage(context, const CasesPage())),
            _ChipLink('О клинике', () => pushPage(context, const AboutPage())),
            _ChipLink('Оборудование', () => pushPage(context, const EquipmentPage())),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => pushPage(context, const EquipmentPage()),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Cult.ink, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('НОВЫЕ ТЕХНОЛОГИИ', style: TextStyle(color: Cult.gold, letterSpacing: 1.4, fontSize: 12)),
                const SizedBox(height: 8),
                Text('Обзор аппаратов и протоколов', style: cultHeadline(24).copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Morpheus8, Ultherapy и свежие разборы сезона.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        CultCard(
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('ПРЕДЛОЖЕНИЕ ДНЯ', style: TextStyle(color: Cult.secondary, letterSpacing: 1.2, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Text('Прецизионный анализ кожи', style: cultHeadline(26), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Мультиспектральная диагностика: прогноз состояния кожи на 10 лет.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const CultImage('offer', aspect: 1, radius: 80),
              const SizedBox(height: 12),
              CultButton(label: 'Получить предложение', onPressed: () => pushPage(context, const BookingPage(initialService: 'Прецизионный анализ кожи'))),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('CULT TV', style: cultHeadline(22)),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final article in articles)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 240,
                    child: InkWell(
                      onTap: () => pushPage(context, ArticlePage(article: article)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CultImage(article.image, aspect: 16 / 9, radius: 12),
                          const SizedBox(height: 8),
                          Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({required this.icon, required this.label, required this.onTap, this.filled = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Cult.gold : const Color(0xFFF3EFEA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Cult.ink),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(label, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipLink extends StatelessWidget {
  const _ChipLink(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Cult.line),
      onPressed: onTap,
    );
  }
}
