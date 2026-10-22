import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import '../yclients.dart';
import 'auth_page.dart';
import 'gender_page.dart';
import 'info.dart';
import 'shop.dart';
import 'talk.dart';

class CabinetPage extends StatelessWidget {
  const CabinetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final next = store.upcoming.isEmpty ? null : store.upcoming.first;
    final name = store.displayName.trim().isEmpty
        ? 'Гость CULT'
        : store.displayName;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 108,
                  height: 108,
                  child: CultImage('avatar', aspect: 1, radius: 0),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Material(
                  color: Cult.ink,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      cultTapFeedback();
                      pushPage(
                        context,
                        store.signedIn
                            ? const SettingsPage()
                            : const AuthPage(allowSkip: false),
                      );
                    },
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(child: Text(name, style: cultHeadline(28))),
        const SizedBox(height: 4),
        Center(
          child: Text(
            store.signedIn
                ? 'ПЛАТИНОВЫЙ СТАТУС'
                : (store.gender?.label.toUpperCase() ?? 'ГОСТЕВОЙ ПРОФИЛЬ'),
            style: const TextStyle(
              letterSpacing: 1.6,
              color: Cult.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (!store.signedIn) ...[
          const SizedBox(height: 16),
          CultCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Войдите по телефону', style: cultHeadline(22)),
                const SizedBox(height: 6),
                const Text(
                  'Сохраним профиль в филиале CULT Сочи.',
                  style: TextStyle(color: Cult.muted),
                ),
                const SizedBox(height: 12),
                CultButton(
                  label: 'Войти',
                  onPressed: () =>
                      pushPage(context, const AuthPage(allowSkip: false)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8CB8E), Color(0xFFC49A4E)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'БОНУСНЫЙ БАЛАНС',
                      style: TextStyle(
                        letterSpacing: 1.1,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'VIP СТАТУС',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(rub(store.balance), style: cultHeadline(36)),
              if (store.welcomeGranted) ...[
                const SizedBox(height: 6),
                Text(
                  'включая welcome-бонус ${rub(store.welcomeBonus)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Cult.ink.withValues(alpha: 0.7),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'В клубе с  ',
                            style: TextStyle(fontSize: 12),
                          ),
                          TextSpan(
                            text: 'ЯНВ 2023',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.auto_awesome,
                    color: Cult.ink.withValues(alpha: 0.55),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const CultSectionLabel('Обзор аккаунта'),
        const SizedBox(height: 10),
        _AccountRow(
          icon: Icons.calendar_today_outlined,
          title: 'Мои записи',
          note: next == null
              ? 'Предстоящих нет'
              : 'След: ${formatVisitDate(next.date)}, ${next.time}',
          onTap: () => pushPage(context, const VisitsPage()),
        ),
        _AccountRow(
          icon: Icons.history,
          title: 'История визитов',
          note: store.past.isEmpty ? 'Пусто' : '${store.past.length} в архиве',
          onTap: () => pushPage(context, const VisitsPage()),
        ),
        _AccountRow(
          icon: Icons.biotech_outlined,
          title: 'Мои анализы',
          note: '',
          onTap: () => pushPage(context, const AnalysesPage()),
        ),
        _AccountRow(
          icon: Icons.shopping_bag_outlined,
          title: 'Мои заказы',
          note: store.orders.isEmpty
              ? 'Пока пусто'
              : '${store.orders.length} заказ(ов)',
          onTap: () => pushPage(context, const OrdersPage()),
        ),
        _AccountRow(
          icon: Icons.favorite_border,
          title: 'Избранное',
          note: store.favorites.isEmpty
              ? ''
              : '${store.favorites.length} формул',
          onTap: () => pushPage(context, const FavoritesPage()),
        ),
        _AccountRow(
          icon: Icons.directions_car_outlined,
          title: 'Заказ трансфера',
          note: '',
          onTap: () => pushPage(context, const TransferPage()),
        ),
        _AccountRow(
          icon: Icons.card_giftcard_outlined,
          title: 'Купить сертификат',
          note: '',
          onTap: () => pushPage(context, const CertificatesPage()),
        ),
        _AccountRow(
          icon: Icons.medical_information_outlined,
          title: 'Рекомендации врача',
          note: 'Аптека и уход',
          onTap: () => pushPage(context, const PharmacyPage()),
        ),
        _AccountRow(
          icon: Icons.rule_outlined,
          title: 'Правила лояльности',
          note: '',
          onTap: () => pushPage(context, const LoyaltyPage()),
        ),
        _AccountRow(
          icon: Icons.wc_outlined,
          title: 'Профиль услуг',
          note: store.gender?.servicesTitle ?? 'Не выбран',
          onTap: () => pushPage(context, const GenderPage()),
        ),
        if (store.signedIn) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Cult.error,
                side: BorderSide(color: Cult.error.withValues(alpha: 0.35)),
              ),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Выйти из профиля?'),
                    content: const Text(
                      'Записи филиала скроются, пока снова не войдёте по телефону. Корзина и избранное останутся на устройстве.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Остаться'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text(
                          'Выйти',
                          style: TextStyle(color: Cult.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  store.signOut();
                  if (context.mounted) {
                    showCultSnack(context, 'Вы вышли из профиля');
                  }
                }
              },
              child: const Text('ВЫЙТИ'),
            ),
          ),
        ],
      ],
    );
  }
}

String _phoneLabel(String raw) {
  if (raw.trim().isEmpty) return 'Телефон';
  final digits = normalizePhone(raw);
  return digits.length >= 11 ? formatRuPhone(digits) : raw;
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.title,
    required this.note,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            cultTapFeedback();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFEA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Cult.ink, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          note,
                          style: const TextStyle(
                            color: Cult.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Cult.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VisitsPage extends StatefulWidget {
  const VisitsPage({super.key});

  @override
  State<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends State<VisitsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ClinicScope.of(context);
      if (store.signedIn) store.refreshVisits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои записи'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: store.signedIn ? () => store.refreshVisits() : null,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Cult.primary,
        onRefresh: () async {
          if (store.signedIn) await store.refreshVisits();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!store.signedIn)
              CultEmpty(
                title: 'Войдите по телефону',
                note: 'Покажем ваши реальные записи из филиала CULT в Сочи.',
                actionLabel: 'Войти',
                onAction: () =>
                    pushPage(context, const AuthPage(allowSkip: false)),
              )
            else ...[
              if (store.visitsLoading)
                const CultLoading(label: 'Обновляем записи…'),
              if (store.visitsError.isNotEmpty)
                CultErrorBanner(
                  message: store.visitsError,
                  onRetry: () {
                    store.refreshVisits();
                  },
                ),
              Text('Предстоящие', style: cultHeadline(22)),
              if (store.upcoming.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: CultEmpty(
                    title: 'Записей пока нет',
                    note: 'Выберите услугу и врача — визит появится здесь.',
                    actionLabel: 'Записаться',
                    onAction: () => pushPage(context, const BookingPage()),
                  ),
                )
              else
                for (final visit in store.upcoming)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: CultCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${formatVisitDate(visit.date)} · ${visit.time}',
                            style: const TextStyle(
                              color: Cult.secondary,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(visit.service, style: cultHeadline(20)),
                          Text(
                            visit.doctor,
                            style: const TextStyle(color: Cult.muted),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'CULT · Сочи',
                            style: TextStyle(color: Cult.muted, fontSize: 12),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _confirmCancel(store, visit.id),
                              child: const Text(
                                'Отменить',
                                style: TextStyle(color: Cult.error),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (store.upcoming.isNotEmpty) ...[
                const SizedBox(height: 12),
                CultButton(
                  label: 'Новая запись',
                  onPressed: () => pushPage(context, const BookingPage()),
                ),
              ],
              const SizedBox(height: 20),
              Text('История', style: cultHeadline(22)),
              if (store.past.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CultEmpty(
                    title: 'История пуста',
                    note: 'После визитов здесь появятся прошлые процедуры.',
                  ),
                )
              else
                for (final visit in store.past)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: CultCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(visit.service, style: cultHeadline(18)),
                          const SizedBox(height: 4),
                          Text(
                            '${formatVisitDate(visit.date)} · ${visit.time}',
                            style: const TextStyle(color: Cult.muted),
                          ),
                          Text(
                            '${visit.doctor} · CULT Сочи',
                            style: const TextStyle(
                              color: Cult.muted,
                              fontSize: 13,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => pushPage(
                                context,
                                BookingPage(initialService: visit.service),
                              ),
                              child: const Text('Повторить запись'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(ClinicStore store, String visitId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Отменить запись?'),
        content: const Text(
          'Слот освободится в филиале. При необходимости можно записаться снова.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Оставить'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Отменить', style: TextStyle(color: Cult.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final message = await store.cancelVisit(visitId);
    if (!mounted) return;
    showCultSnack(context, message ?? 'Запись отменена');
  }
}

class AnalysesPage extends StatelessWidget {
  const AnalysesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final labs = store.labHistory;
    return Scaffold(
      appBar: AppBar(title: const Text('Мои анализы')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!store.signedIn)
            CultEmpty(
              title: 'Войдите по телефону',
              note: 'Покажем анализы и заборы из ваших записей в филиале Сочи.',
              actionLabel: 'Войти',
              onAction: () =>
                  pushPage(context, const AuthPage(allowSkip: false)),
            )
          else if (labs.isEmpty)
            CultEmpty(
              title: 'Анализов пока нет',
              note:
                  'Когда в филиале появятся заборы на этом номере — они будут здесь.',
              actionLabel: 'Записаться',
              onAction: () => pushPage(context, const BookingPage()),
            )
          else
            for (final visit in labs)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CultCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(visit.service, style: cultHeadline(18)),
                          ),
                          Text(
                            visit.status == 'upcoming' ? 'Назначен' : 'Сдан',
                            style: const TextStyle(
                              color: Cult.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatVisitDate(visit.date)} · ${visit.time}',
                        style: const TextStyle(color: Cult.muted),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => pushPage(
                            context,
                            BookingPage(initialService: visit.service),
                          ),
                          child: const Text('Записать снова'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 12),
          CultButton(
            label: 'Записать анализ',
            onPressed: () => pushPage(
              context,
              const BookingPage(initialService: 'Забор Анализов в клинике'),
            ),
          ),
        ],
      ),
    );
  }
}

class PharmacyPage extends StatelessWidget {
  const PharmacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Аптечка')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text('Рекомендации врача', style: cultHeadline(26)),
          const SizedBox(height: 6),
          const Text(
            'Средства и короткая схема. «Купить сейчас» откроет корзину.',
            style: TextStyle(color: Cult.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          for (final row in pharmacy)
            if (productById(row.productId) case final product?)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CultCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: cultHeadline(20)),
                      const SizedBox(height: 4),
                      Text(
                        row.dose,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        row.note,
                        style: const TextStyle(color: Cult.muted, height: 1.35),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${row.doctor} · до ${row.until}',
                        style: const TextStyle(color: Cult.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      CultButton(
                        label: 'Купить сейчас · ${rub(product.price)}',
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          store.addToCart(
                            product.id,
                            product.name,
                            product.price,
                          );
                          showCultSnack(
                            context,
                            '${product.name} в корзине',
                            actionLabel: 'Корзина',
                            onAction: () => pushPage(context, const CartPage()),
                          );
                        },
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

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Мои заказы')),
      body: store.orders.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CultEmpty(
                  title: 'Покупок пока нет',
                  note:
                      'Формулы из биохакинг-шопа появятся здесь после оформления.',
                  actionLabel: 'В магазин',
                  onAction: () => Navigator.pop(context),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final order in store.orders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CultCard(
                      child: InkWell(
                        onTap: () {
                          cultTapFeedback();
                          showCultSnack(
                            context,
                            'Заказ от ${order.at} · ${order.pay}',
                          );
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(order.title, style: cultHeadline(18)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order.at} · ${order.pay}',
                                    style: const TextStyle(
                                      color: Cult.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              rub(order.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final list = products
        .where((item) => store.favorites.contains(item.id))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: list.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CultEmpty(
                  title: 'Список пуст',
                  note: 'Отметьте формулу сердцем на странице товара.',
                  actionLabel: 'В магазин',
                  onAction: () => Navigator.pop(context),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final product in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            pushPage(context, ProductPage(product: product)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: CultImage(
                                    product.image,
                                    aspect: 1,
                                    radius: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name, style: cultHeadline(18)),
                                    Text(
                                      rub(product.price),
                                      style: const TextStyle(
                                        color: Cult.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'В корзину',
                                onPressed: () {
                                  cultTapFeedback();
                                  store.addToCart(
                                    product.id,
                                    product.name,
                                    product.price,
                                  );
                                  showCultSnack(
                                    context,
                                    '${product.name} в корзине',
                                    actionLabel: 'Оформить',
                                    onAction: () =>
                                        pushPage(context, const CartPage()),
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_shopping_cart_outlined,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  store.toggleFavorite(product.id);
                                },
                                icon: const Icon(
                                  Icons.favorite,
                                  color: Cult.primary,
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
    );
  }
}

class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key});

  @override
  State<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage> {
  var _note = '';
  var _started = false;
  var _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    final store = ClinicScope.of(context);
    if (!store.yclientsReady || store.userToken.isEmpty) return;
    _started = true;
    _loading = true;
    store.refreshLoyalty().then((message) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _note =
            message ??
            (store.loyaltyCards.isEmpty
                ? 'Карт лояльности по этому телефону нет.'
                : '');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Лояльность')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8CB8E), Color(0xFFC49A4E)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'БАЛАНС КЛУБА',
                  style: TextStyle(
                    letterSpacing: 1.2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(rub(store.balance), style: cultHeadline(36)),
                if (store.welcomeGranted)
                  Text(
                    'включая welcome ${rub(store.welcomeBonus)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Cult.ink.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          if (!store.signedIn) ...[
            const SizedBox(height: 14),
            CultEmpty(
              title: 'Войдите по телефону',
              note: 'Карта филиала и бонусы YClients подтянутся к номеру.',
              actionLabel: 'Войти',
              onAction: () =>
                  pushPage(context, const AuthPage(allowSkip: false)),
            ),
          ] else if (store.loyaltyCards.isNotEmpty) ...[
            const SizedBox(height: 18),
            const CultSectionLabel('Карты YClients'),
            for (final card in store.loyaltyCards)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CultCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(card.title, style: cultHeadline(18)),
                      ),
                      Text(
                        rub(card.balance),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
          ] else if (_loading) ...[
            const SizedBox(height: 14),
            const CultLoading(label: 'Обновляем карты…'),
          ] else if (_note.isNotEmpty) ...[
            const SizedBox(height: 14),
            CultEmpty(
              title: 'Карт лояльности нет',
              note: _note,
              actionLabel: 'Записаться в филиал',
              onAction: () => pushPage(context, const BookingPage()),
            ),
          ],
          const SizedBox(height: 18),
          const CultSectionLabel('Правила'),
          const SizedBox(height: 8),
          for (final rule in loyaltyRules)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CultCard(
                child: Text(rule, style: const TextStyle(height: 1.35)),
              ),
            ),
          const SizedBox(height: 10),
          const CultSectionLabel('История'),
          const SizedBox(height: 8),
          for (final row in const [
            ('Янв 2023', 'Вступление в клуб', '+2 000 ₽'),
            ('Фев 2026', 'Morpheus8', '+8 800 ₽'),
            ('Фев 2026', 'Списание на уход', '−1 200 ₽'),
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
                          Text(
                            row.$2,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            row.$1,
                            style: const TextStyle(
                              color: Cult.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      row.$3,
                      style: const TextStyle(fontWeight: FontWeight.w700),
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

class CertificatesPage extends StatefulWidget {
  const CertificatesPage({super.key});

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  int _nominal = 15000;
  var _design = 'Песок';
  var _bonus = false;
  var _error = '';
  var _code = '';

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final color = switch (_design) {
      'Золото' => Cult.gold,
      'Ночь' => Cult.ink,
      _ => Cult.sand,
    };
    final foreground = _design == 'Ночь' ? Colors.white : Cult.ink;
    return Scaffold(
      appBar: AppBar(title: const Text('Сертификаты')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CULT',
                  style: TextStyle(color: foreground, letterSpacing: 3),
                ),
                const SizedBox(height: 24),
                Text(
                  rub(_nominal),
                  style: cultHeadline(32).copyWith(color: foreground),
                ),
                Text(_design, style: TextStyle(color: foreground)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final value in certificateNominals)
                ChoiceChip(
                  label: Text(rub(value)),
                  selected: _nominal == value,
                  onSelected: (_) {
                    cultTapFeedback();
                    setState(() => _nominal = value);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final name in ['Песок', 'Золото', 'Ночь'])
                ChoiceChip(
                  label: Text(name),
                  selected: _design == name,
                  onSelected: (_) {
                    cultTapFeedback();
                    setState(() => _design = name);
                  },
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Оплатить бонусами, баланс ${rub(store.balance)}'),
            value: _bonus,
            onChanged: (value) => setState(() => _bonus = value),
          ),
          if (_error.isNotEmpty) CultErrorBanner(message: _error),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _code.isEmpty
                ? const SizedBox.shrink(key: ValueKey('idle'))
                : CultCard(
                    key: ValueKey(_code),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.card_giftcard,
                          color: Cult.primary,
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text('Сертификат готов', style: cultHeadline(22)),
                        const SizedBox(height: 6),
                        Text(
                          'Код $_code',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Сохраните код — отправим также в WhatsApp и на почту.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Cult.muted, height: 1.35),
                        ),
                        TextButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _code));
                            showCultSnack(context, 'Код скопирован');
                          },
                          child: const Text('Скопировать код'),
                        ),
                      ],
                    ),
                  ),
          ),
          if (_code.isNotEmpty) const SizedBox(height: 12),
          CultButton(
            label: _code.isEmpty ? 'Оплатить сертификат' : 'Купить ещё',
            onPressed: () {
              if (_bonus && !store.spendBonus(_nominal)) {
                setState(() => _error = 'Бонусов не хватает на этот номинал.');
                return;
              }
              final code = store.buyGift(_nominal, _design);
              HapticFeedback.mediumImpact();
              setState(() {
                _error = '';
                _code = code;
              });
            },
          ),
          const SizedBox(height: 18),
          const CultSectionLabel('Уже купленные'),
          const SizedBox(height: 8),
          if (store.gifts.isEmpty)
            const CultEmpty(
              title: 'Сертификатов пока нет',
              note: 'Купите номинал выше — код появится в списке.',
            )
          else
            for (final gift in store.gifts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CultCard(
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: gift.code));
                      showCultSnack(context, 'Код ${gift.code} скопирован');
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${rub(gift.nominal)} · ${gift.design}',
                          style: cultHeadline(18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gift.code,
                          style: const TextStyle(
                            color: Cult.muted,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Нажмите, чтобы скопировать',
                          style: TextStyle(color: Cult.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _name;
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _name = TextEditingController(text: ClinicScope.of(context).profileName);
  }

  @override
  void dispose() {
    if (_ready) _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CultSectionLabel('Профиль'),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Имя в кабинете'),
          ),
          const SizedBox(height: 12),
          CultButton(
            label: 'Сохранить имя',
            onPressed: () {
              store.setProfileName(_name.text);
              showCultSnack(context, 'Имя сохранено');
            },
          ),
          const SizedBox(height: 18),
          const CultSectionLabel('Профиль услуг'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Женские'),
                selected: store.gender == ClientGender.woman,
                onSelected: (_) {
                  cultTapFeedback();
                  store.setGender(ClientGender.woman);
                },
              ),
              ChoiceChip(
                label: const Text('Мужские'),
                selected: store.gender == ClientGender.man,
                onSelected: (_) {
                  cultTapFeedback();
                  store.setGender(ClientGender.man);
                },
              ),
            ],
          ),
          if (store.signedIn) ...[
            const SizedBox(height: 8),
            Text(
              'Телефон ${_phoneLabel(store.profilePhone)}',
              style: const TextStyle(color: Cult.muted),
            ),
            TextButton(
              onPressed: () =>
                  pushPage(context, const AuthPage(allowSkip: false)),
              child: const Text('Сменить номер'),
            ),
          ] else
            TextButton(
              onPressed: () =>
                  pushPage(context, const AuthPage(allowSkip: false)),
              child: const Text('Войти по телефону'),
            ),
          const SizedBox(height: 12),
          const CultSectionLabel('Уведомления'),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Визиты'),
            value: store.notices['visits'] ?? true,
            onChanged: (value) {
              cultTapFeedback();
              store.setNotice('visits', value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Анализы'),
            value: store.notices['analyses'] ?? true,
            onChanged: (value) {
              cultTapFeedback();
              store.setNotice('analyses', value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Аптечка'),
            value: store.notices['pharmacy'] ?? true,
            onChanged: (value) {
              cultTapFeedback();
              store.setNotice('pharmacy', value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Предложения'),
            value: store.notices['offers'] ?? false,
            onChanged: (value) {
              cultTapFeedback();
              store.setNotice('offers', value);
            },
          ),
        ],
      ),
    );
  }
}
