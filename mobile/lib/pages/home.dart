import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'browse.dart';
import 'cabinet.dart';
import 'info.dart';
import 'talk.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onShop, this.scrollController});

  final VoidCallback onShop;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final next = store.upcoming.isEmpty ? null : store.upcoming.first;
    final first = store.displayName.trim().split(RegExp(r'\s+')).first;
    final part = _dayPartGreeting();
    final hello = first.isEmpty || first == 'Гость'
        ? part
        : '$first, ${part[0].toLowerCase()}${part.substring(1)}';
    final nextLine = next == null
        ? 'Рады видеть вас снова в CULT Clinic. Выберите услугу и врача.'
        : () {
            final wait = formatVisitCountdown(next.date, next.time);
            final weekday = formatVisitWeekday(next.date);
            return 'Следующая: ${formatVisitDate(next.date)}'
                '${weekday.isEmpty ? '' : ', $weekday'}'
                ' в ${next.time}'
                '${next.doctor.trim().isEmpty ? '' : ' · ${next.doctor}'}'
                '${wait.isEmpty ? '' : ' · $wait'}.';
          }();
    return RefreshIndicator(
      color: Cult.primary,
      onRefresh: () => store.syncClinic(),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (store.syncing)
            const CultLoading(label: 'Синхронизация с филиалом…'),
          if (store.liveError.isNotEmpty)
            CultErrorBanner(
              message: store.liveError,
              onRetry: () => store.syncClinic(),
              retryLabel: 'Обновить',
            ),
          CultCard(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Cult.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      store.signedIn ? 'ВАШ СТАТУС: PLATINUM' : 'CULT CLINIC',
                      style: const TextStyle(
                        color: Cult.secondary,
                        letterSpacing: 1.4,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(hello, style: cultHeadline(28)),
                const SizedBox(height: 8),
                GestureDetector(
                  onLongPress: next == null
                      ? null
                      : () {
                          final weekday = formatVisitWeekday(next.date);
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  '${next.service} · ${next.doctor}, ${formatVisitDate(next.date)}'
                                  '${weekday.isEmpty ? '' : ' ($weekday)'}'
                                  ' в ${next.time} · CULT Сочи',
                            ),
                          );
                          cultTapFeedback();
                          showCultSnack(context, 'Визит скопирован');
                        },
                  child: Text(
                    nextLine,
                    style: const TextStyle(color: Cult.muted, height: 1.4),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Cult.primary,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () {
                    cultTapFeedback();
                    pushPage(
                      context,
                      next == null ? const BookingPage() : const VisitsPage(),
                    );
                  },
                  child: Text(next == null ? 'Записаться →' : 'Мои записи →'),
                ),
              ],
            ),
          ),
          if (store.welcomeGranted) ...[
            const SizedBox(height: 12),
            Semantics(
              label: 'Welcome-бонус ${rub(store.welcomeBonus)}',
              child: GestureDetector(
                onLongPress: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          'Welcome-бонус CULT: ${rub(store.welcomeBonus)} на балансе',
                    ),
                  );
                  cultTapFeedback();
                  showCultSnack(context, 'Бонус скопирован');
                },
                child: CultCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.card_giftcard_outlined,
                        color: Cult.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Welcome-бонус ${rub(store.welcomeBonus)} на балансе.',
                          style: const TextStyle(height: 1.35),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          cultTapFeedback();
                          pushPage(context, const CertificatesPage());
                        },
                        child: const Text('Сертификат'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                icon: Icons.calendar_month,
                label: 'Онлайн запись',
                filled: true,
                onTap: () => pushPage(context, const BookingPage()),
              ),
              _Quick(
                icon: Icons.biotech,
                label: 'Мои анализы',
                onTap: () => pushPage(context, const AnalysesPage()),
              ),
              _Quick(
                icon: Icons.shopping_basket_outlined,
                label: 'Магазин биохакинга',
                onTap: onShop,
              ),
              _Quick(
                icon: Icons.forum_outlined,
                label: 'Чат с врачом',
                onTap: () => pushPage(
                  context,
                  const ChatThreadPage(contactId: 'specialist'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _LinkChip(
                  'Специалисты',
                  () => pushPage(context, const DoctorsPage()),
                ),
                _LinkChip(
                  'Аппаратная',
                  () => pushPage(
                    context,
                    const CategoryHubPage(slug: 'hardware'),
                  ),
                ),
                _LinkChip(
                  'Инъекции',
                  () => pushPage(
                    context,
                    const CategoryHubPage(slug: 'injections'),
                  ),
                ),
                _LinkChip(
                  'Инфузии',
                  () => pushPage(
                    context,
                    const CategoryHubPage(slug: 'infusions'),
                  ),
                ),
                _LinkChip(
                  'Наука',
                  () =>
                      pushPage(context, const CategoryHubPage(slug: 'science')),
                ),
                _LinkChip(
                  'Прайс',
                  () => pushPage(context, const PricesPage()),
                ),
                _LinkChip(
                  'Кейсы',
                  () => pushPage(context, const CasesPage()),
                ),
                _LinkChip(
                  'О клинике',
                  () => pushPage(context, const AboutPage()),
                ),
                _LinkChip(
                  'Трансфер',
                  () => pushPage(context, const TransferPage()),
                ),
                _LinkChip(
                  'Анализы',
                  () => pushPage(context, const AnalysesPage()),
                ),
                _LinkChip(
                  'Лояльность',
                  () => pushPage(context, const LoyaltyPage()),
                ),
                _LinkChip(
                  'Сертификаты',
                  () => pushPage(context, const CertificatesPage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          CultCard(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Cult.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ОГРАНИЧЕННОЕ ПРЕДЛОЖЕНИЕ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  store.gender == ClientGender.man
                      ? 'Мужской уход за лицом'
                      : 'Прецизионный анализ кожи',
                  style: cultHeadline(24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  store.gender == ClientGender.man
                      ? 'Очищение, тонус и уход без тяжёлого блеска.'
                      : 'Мультиспектральная диагностика и прогноз на 10 лет.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Cult.muted, height: 1.35),
                ),
                const SizedBox(height: 12),
                const CultImage('offer', aspect: 1, radius: 90),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      store.gender == ClientGender.man ? '6 500 ₽' : '295 ₽',
                      style: cultHeadline(26).copyWith(color: Cult.secondary),
                    ),
                    if (store.gender != ClientGender.man) ...[
                      const SizedBox(width: 10),
                      const Text(
                        '450 ₽',
                        style: TextStyle(
                          color: Cult.muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                CultButton(
                  label: 'Получить предложение',
                  onPressed: () => pushPage(
                    context,
                    BookingPage(
                      initialService: store.gender == ClientGender.man
                          ? 'Мужской уход за лицом'
                          : 'Прецизионный анализ кожи',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CULT TV',
                      style: TextStyle(
                        color: Cult.secondary,
                        letterSpacing: 1.5,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('Свежие новости', style: cultHeadline(22)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  cultTapFeedback();
                  pushPage(context, const BlogPage());
                },
                child: const Text('Все материалы'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: articles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final article = articles[index];
                return SizedBox(
                  width: 260,
                  child: Semantics(
                    button: true,
                    label: article.title,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        cultTapFeedback();
                        pushPage(context, ArticlePage(article: article));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CultImage(
                                article.image,
                                aspect: 16 / 9,
                                radius: 12,
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white54),
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            article.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            article.author,
                            style: const TextStyle(
                              color: Cult.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _dayPartGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 5) return 'Доброй ночи!';
  if (hour < 12) return 'Доброе утро!';
  if (hour < 18) return 'Добрый день!';
  return 'Добрый вечер!';
}

class _Quick extends StatelessWidget {
  const _Quick({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: filled ? Cult.gold : const Color(0xFFF3EFEA),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            cultTapFeedback();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Cult.ink, size: 28),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ),
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
        onPressed: () {
          cultTapFeedback();
          onTap();
        },
      ),
    );
  }
}
