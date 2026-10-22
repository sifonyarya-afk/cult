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
    final hello = first.isEmpty || first == 'Гость' ? 'Доброго дня' : '$first, доброго дня';
    final status = store.signedIn ? 'ВАШ СТАТУС: PLATINUM' : (store.gender?.servicesTitle.toUpperCase() ?? 'CULT CLINIC');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => pushPage(context, const VisitsPage()),
          child: CultCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Cult.gold, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        status,
                        style: const TextStyle(color: Cult.secondary, letterSpacing: 1.3, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(hello, style: cultHeadline(28)),
                const SizedBox(height: 8),
                Text(
                  next == null
                      ? 'Рады видеть вас в CULT Clinic. Выберите услугу и врача.'
                      : 'Следующая процедура: ${formatVisitDate(next.date)} в ${next.time}.',
                  style: const TextStyle(color: Cult.muted, height: 1.4),
                ),
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
          childAspectRatio: 1.12,
          children: [
            _Quick(
              icon: Icons.calendar_month_outlined,
              label: 'Онлайн запись',
              filled: true,
              onTap: () => pushPage(context, const BookingPage()),
            ),
            _Quick(icon: Icons.biotech_outlined, label: 'Мои анализы', onTap: () => pushPage(context, const AnalysesPage())),
            _Quick(icon: Icons.shopping_basket_outlined, label: 'Магазин биохакинга', onTap: onShop),
            _Quick(
              icon: Icons.chat_bubble_outline,
              label: 'Чат с врачом',
              onTap: () => pushPage(context, const ChatThreadPage(contactId: 'specialist')),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _LinkChip('Врачи', () => pushPage(context, const DoctorsPage())),
              _LinkChip('Аппараты', () => pushPage(context, const EquipmentPage())),
              _LinkChip('Инъекции', () => pushPage(context, const CategoryHubPage(slug: 'injections'))),
              _LinkChip('Инфузии', () => pushPage(context, const CategoryHubPage(slug: 'infusions'))),
              _LinkChip('Наука', () => pushPage(context, const CategoryHubPage(slug: 'science'))),
              _LinkChip('Прайс', () => pushPage(context, const PricesPage())),
            ],
          ),
        ),
        const SizedBox(height: 20),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => pushPage(context, const BookingPage(initialService: 'Прецизионный анализ кожи')),
          child: Stack(
            children: [
              CultCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CultImage('offer', aspect: 16 / 10, radius: 0),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Cult.secondary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ОГРАНИЧЕННОЕ ПРЕДЛОЖЕНИЕ',
                              style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text('Прецизионный анализ кожи', style: cultHeadline(24)),
                          const SizedBox(height: 6),
                          const Text(
                            'Мультиспектральная диагностика и прогноз на 10 лет.',
                            style: TextStyle(color: Cult.muted, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Material(
                  color: Cult.ink,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => pushPage(context, const BookingPage(initialService: 'Прецизионный анализ кожи')),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Text('CULT TV', style: cultHeadline(22)),
            const Spacer(),
            TextButton(onPressed: () => pushPage(context, const BlogPage()), child: const Text('Все')),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: articles.length.clamp(0, 6),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final article = articles[index];
              return SizedBox(
                width: 220,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => pushPage(context, ArticlePage(article: article)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CultImage(article.image, aspect: 16 / 9, radius: 12),
                      const SizedBox(height: 8),
                      Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.25)),
                    ],
                  ),
                ),
              );
            },
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Cult.ink, size: 28),
              const SizedBox(height: 10),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500, height: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Cult.line),
        onPressed: onTap,
      ),
    );
  }
}
