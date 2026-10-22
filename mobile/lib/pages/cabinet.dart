import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
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
    final name = store.displayName.trim().isEmpty ? 'Гость CULT' : store.displayName;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(width: 108, height: 108, child: CultImage('avatar', aspect: 1, radius: 0)),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Material(
                  color: Cult.ink,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => pushPage(context, store.signedIn ? const SettingsPage() : const AuthPage(allowSkip: false)),
                    child: const SizedBox(width: 34, height: 34, child: Icon(Icons.edit_outlined, size: 16, color: Colors.white)),
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
            store.signedIn ? 'ПЛАТИНОВЫЙ СТАТУС' : (store.gender?.label.toUpperCase() ?? 'ГОСТЕВОЙ ПРОФИЛЬ'),
            style: const TextStyle(letterSpacing: 1.6, color: Cult.muted, fontSize: 12, fontWeight: FontWeight.w600),
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
                const Text('Сохраним профиль в филиале CULT Сочи.', style: TextStyle(color: Cult.muted)),
                const SizedBox(height: 12),
                CultButton(label: 'Войти', onPressed: () => pushPage(context, const AuthPage(allowSkip: false))),
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
                    child: Text('БОНУСНЫЙ БАЛАНС', style: TextStyle(letterSpacing: 1.1, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('VIP СТАТУС', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(rub(store.balance), style: cultHeadline(36)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'В клубе с  ', style: TextStyle(fontSize: 12)),
                          TextSpan(text: 'ЯНВ 2023', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                        ],
                      ),
                    ),
                  ),
                  Icon(Icons.auto_awesome, color: Cult.ink.withValues(alpha: 0.55), size: 20),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text('ОБЗОР АККАУНТА', style: TextStyle(letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _AccountRow(
          icon: Icons.calendar_today_outlined,
          title: 'Мои записи',
          note: next == null ? 'Предстоящих нет' : 'След: ${formatVisitDate(next.date)}, ${next.time}',
          onTap: () => pushPage(context, const VisitsPage()),
        ),
        _AccountRow(icon: Icons.history, title: 'История визитов', note: '', onTap: () => pushPage(context, const VisitsPage())),
        _AccountRow(icon: Icons.biotech_outlined, title: 'Мои анализы', note: '', onTap: () => pushPage(context, const AnalysesPage())),
        _AccountRow(icon: Icons.inventory_2_outlined, title: 'Мои пакеты услуг', note: '', onTap: () => pushPage(context, const FavoritesPage())),
        _AccountRow(icon: Icons.directions_car_outlined, title: 'Заказ трансфера', note: '', onTap: () => pushPage(context, const TransferPage())),
        _AccountRow(icon: Icons.card_giftcard_outlined, title: 'Купить сертификат', note: '', onTap: () => pushPage(context, const CertificatesPage())),
        _AccountRow(icon: Icons.medical_information_outlined, title: 'Рекомендации врача', note: '3 новых рекомендации', onTap: () => pushPage(context, const PharmacyPage())),
        _AccountRow(icon: Icons.rule_outlined, title: 'Правила лояльности', note: '', onTap: () => pushPage(context, const LoyaltyPage())),
        _AccountRow(icon: Icons.wc_outlined, title: 'Профиль услуг', note: store.gender?.servicesTitle ?? 'Не выбран', onTap: () => pushPage(context, const GenderPage())),
        if (store.signedIn) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Cult.error, side: BorderSide(color: Cult.error.withValues(alpha: 0.35))),
              onPressed: () => store.signOut(),
              child: const Text('ВЫЙТИ'),
            ),
          ),
        ],
      ],
    );
  }
}

String _phoneLabel(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11 && digits.startsWith('7')) {
    return '+7 ${digits.substring(1, 4)} ${digits.substring(4, 7)}-${digits.substring(7, 9)}-${digits.substring(9)}';
  }
  return raw.isEmpty ? 'Телефон' : raw;
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.icon, required this.title, required this.note, required this.onTap});

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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: const Color(0xFFF3EFEA), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: Cult.ink, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(note, style: const TextStyle(color: Cult.muted, fontSize: 13)),
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
        title: const Text('Визиты'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: store.signedIn ? () => store.refreshVisits() : null,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!store.signedIn)
            CultCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Войдите по телефону', style: cultHeadline(22)),
                  const SizedBox(height: 6),
                  const Text('Покажем ваши реальные записи из филиала CULT в Сочи.'),
                  const SizedBox(height: 12),
                  CultButton(label: 'Войти', onPressed: () => pushPage(context, const AuthPage(allowSkip: false))),
                ],
              ),
            )
          else ...[
            if (store.visitsLoading) const LinearProgressIndicator(),
            if (store.visitsError.isNotEmpty) Text(store.visitsError, style: const TextStyle(color: Cult.error)),
            Text('Предстоящие', style: cultHeadline(22)),
            if (store.upcoming.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Предстоящих визитов нет.'))
            else
              for (final visit in store.upcoming)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: CultCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${formatVisitDate(visit.date)} · ${visit.time}', style: const TextStyle(color: Cult.muted)),
                        Text(visit.service, style: cultHeadline(20)),
                        Text(visit.doctor),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () async {
                              final message = await store.cancelVisit(visit.id);
                              if (!context.mounted) return;
                              if (message != null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                              }
                            },
                            child: const Text('Отменить', style: TextStyle(color: Cult.error)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => pushPage(context, const BookingPage()), child: const Text('Записаться')),
            Text('История', style: cultHeadline(22)),
            if (store.past.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Истории визитов пока нет.'))
            else
              for (final visit in store.past)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(visit.service),
                  subtitle: Text('${formatVisitDate(visit.date)} · ${visit.time}\n${visit.doctor} · CULT Сочи'),
                  isThreeLine: true,
                ),
          ],
        ],
      ),
    );
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
            const Text('Войдите по телефону — покажем анализы и заборы из ваших записей в филиале.')
          else if (labs.isEmpty)
            const Text('В филиале пока нет записей с анализами на этом номере.')
          else
            for (final visit in labs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(visit.service),
                subtitle: Text('${formatVisitDate(visit.date)} · ${visit.time}'),
                trailing: Text(
                  visit.status == 'upcoming' ? 'Назначен' : 'Сдан',
                  style: const TextStyle(color: Cult.primary, fontWeight: FontWeight.w700),
                ),
              ),
          const SizedBox(height: 12),
          CultButton(
            label: 'Записать анализ',
            onPressed: () => pushPage(context, const BookingPage(initialService: 'Забор Анализов в клинике')),
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
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Врач оставил средства и короткую рекомендацию. «Купить сейчас» открывает корзину.'),
          const SizedBox(height: 12),
          for (final row in pharmacy)
            if (productById(row.productId) case final product?)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CultCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: cultHeadline(20)),
                      Text(row.dose),
                      Text(row.note),
                      Text('${row.doctor} · ${row.until}', style: const TextStyle(color: Cult.muted)),
                      const SizedBox(height: 8),
                      CultButton(
                        label: 'Купить сейчас',
                        onPressed: () {
                          store.addToCart(product.id, product.name, product.price);
                          pushPage(context, const CartPage());
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
          ? const Center(child: Text('Покупок пока нет.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final order in store.orders)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(order.title),
                    subtitle: Text('${order.at} · ${order.pay}'),
                    trailing: Text(rub(order.total)),
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
    final list = products.where((item) => store.favorites.contains(item.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: list.isEmpty
          ? const Center(child: Text('Отметьте товар сердцем на его странице.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final product in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(product.name),
                    subtitle: Text(rub(product.price)),
                    trailing: IconButton(onPressed: () => store.toggleFavorite(product.id), icon: const Icon(Icons.favorite, color: Cult.primary)),
                    onTap: () => pushPage(context, ProductPage(product: product)),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    final store = ClinicScope.of(context);
    if (!store.yclientsReady || store.userToken.isEmpty) return;
    _started = true;
    store.refreshLoyalty().then((message) {
      if (!mounted) return;
      setState(() => _note = message ?? (store.loyaltyCards.isEmpty ? 'Карт лояльности по этому телефону нет.' : ''));
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Лояльность')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(rub(store.balance), style: cultHeadline(36)),
          const SizedBox(height: 8),
          const Text('Баланс клуба CULT на этом телефоне.'),
          if (store.loyaltyCards.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Карты YClients', style: cultHeadline(22)),
            for (final card in store.loyaltyCards)
              ListTile(contentPadding: EdgeInsets.zero, title: Text(card.title), trailing: Text(rub(card.balance))),
          ] else if (!store.signedIn)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Войдите по телефону в кабинете — карта филиала подтянется к номеру.'),
            )
          else if (_note.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 12), child: Text(_note)),
          const SizedBox(height: 12),
          for (final rule in loyaltyRules) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(rule)),
          const SizedBox(height: 8),
          const Text('Янв 2023 · Вступление в клуб · +2 000 ₽'),
          const Text('Фев 2026 · Morpheus8 · +8 800 ₽'),
          const Text('Фев 2026 · Списание на уход · −1 200 ₽'),
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
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CULT', style: TextStyle(color: foreground, letterSpacing: 3)),
                const SizedBox(height: 24),
                Text(rub(_nominal), style: cultHeadline(32).copyWith(color: foreground)),
                Text(_design, style: TextStyle(color: foreground)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final value in certificateNominals)
                ChoiceChip(label: Text(rub(value)), selected: _nominal == value, onSelected: (_) => setState(() => _nominal = value)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final name in ['Песок', 'Золото', 'Ночь'])
                ChoiceChip(label: Text(name), selected: _design == name, onSelected: (_) => setState(() => _design = name)),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Оплатить бонусами, баланс ${rub(store.balance)}'),
            value: _bonus,
            onChanged: (value) => setState(() => _bonus = value),
          ),
          if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Cult.error)),
          if (_code.isNotEmpty) Text('Код отправлен в WhatsApp и на почту: $_code'),
          CultButton(
            label: 'Оплатить сертификат',
            onPressed: () {
              if (_bonus && !store.spendBonus(_nominal)) {
                setState(() => _error = 'Бонусов не хватает на этот номинал.');
                return;
              }
              final code = store.buyGift(_nominal, _design);
              setState(() {
                _error = '';
                _code = code;
              });
            },
          ),
          const SizedBox(height: 16),
          Text('Уже купленные', style: cultHeadline(22)),
          for (final gift in store.gifts) ListTile(contentPadding: EdgeInsets.zero, title: Text('${rub(gift.nominal)} · ${gift.design}'), subtitle: Text(gift.code)),
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
      appBar: AppBar(title: const Text('Уведомления')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Имя в кабинете')),
          const SizedBox(height: 12),
          CultButton(label: 'Сохранить имя', onPressed: () => store.setProfileName(_name.text)),
          const SizedBox(height: 12),
          const Text('Профиль услуг', style: TextStyle(color: Cult.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Женские'),
                selected: store.gender == ClientGender.woman,
                onSelected: (_) => store.setGender(ClientGender.woman),
              ),
              ChoiceChip(
                label: const Text('Мужские'),
                selected: store.gender == ClientGender.man,
                onSelected: (_) => store.setGender(ClientGender.man),
              ),
            ],
          ),
          if (store.signedIn) ...[
            const SizedBox(height: 8),
            Text('Телефон ${_phoneLabel(store.profilePhone)}', style: const TextStyle(color: Cult.muted)),
            TextButton(
              onPressed: () => pushPage(context, const AuthPage(allowSkip: false)),
              child: const Text('Сменить номер'),
            ),
          ] else
            TextButton(
              onPressed: () => pushPage(context, const AuthPage(allowSkip: false)),
              child: const Text('Войти по телефону'),
            ),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Визиты'), value: store.notices['visits'] ?? true, onChanged: (value) => store.setNotice('visits', value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Анализы'), value: store.notices['analyses'] ?? true, onChanged: (value) => store.setNotice('analyses', value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Аптечка'), value: store.notices['pharmacy'] ?? true, onChanged: (value) => store.setNotice('pharmacy', value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Предложения'), value: store.notices['offers'] ?? false, onChanged: (value) => store.setNotice('offers', value)),
        ],
      ),
    );
  }
}
