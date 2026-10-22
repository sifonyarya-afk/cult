import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'shop.dart';
import 'talk.dart';
import 'yclients_page.dart';

class CabinetPage extends StatelessWidget {
  const CabinetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final next = store.upcoming.isEmpty ? null : store.upcoming.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Center(child: SizedBox(width: 96, child: CultImage('avatar', aspect: 1, radius: 48))),
        const SizedBox(height: 8),
        Center(child: Text(store.profileName, style: cultHeadline(26))),
        const Center(child: Text('ПЛАТИНОВЫЙ СТАТУС', style: TextStyle(letterSpacing: 1.2, color: Cult.muted))),
        if (next != null) ...[
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => pushPage(context, const VisitsPage()),
            child: CultCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('СЛЕДУЮЩИЙ ВИЗИТ', style: TextStyle(color: Cult.secondary, letterSpacing: 1.2, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(next.service, style: cultHeadline(22)),
                  Text('${formatVisitDate(next.date)} · ${next.time} · ${next.doctor}', style: const TextStyle(color: Cult.muted)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFFE7C98A), Color(0xFFC8A15A)]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('БОНУСНЫЙ БАЛАНС'),
              Text(rub(store.balance), style: cultHeadline(36)),
              const Text('В клубе с января 2023'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Row('Мои записи', next == null ? 'Предстоящих нет' : 'След: ${formatVisitDate(next.date)}, ${next.time}', () => pushPage(context, const VisitsPage())),
        _Row('История визитов', 'Чеки по прошлым визитам', () => pushPage(context, const VisitsPage())),
        _Row('Мои анализы', 'Назначен, сдан, готов', () => pushPage(context, const AnalysesPage())),
        _Row('Аптечка', 'Рекомендации врача', () => pushPage(context, const PharmacyPage())),
        _Row('Мои заказы', '${store.orders.length}', () => pushPage(context, const OrdersPage())),
        _Row('Сертификаты', 'Номинал и дизайн', () => pushPage(context, const CertificatesPage())),
        _Row('Избранное', '${store.favorites.length}', () => pushPage(context, const FavoritesPage())),
        _Row('Бонусы и правила', rub(store.balance), () => pushPage(context, const LoyaltyPage())),
        _Row('Чат с доктором', 'Клинические вопросы', () => pushPage(context, const ChatThreadPage(contactId: 'specialist'))),
        _Row('YClients', store.yclientsReady ? 'Филиал ${store.companyId}' : 'Подключить запись', () => pushPage(context, const YClientsPage())),
        _Row('Уведомления', 'Визиты, анализы, аптека', () => pushPage(context, const SettingsPage())),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.title, this.note, this.onTap);

  final String title;
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      minVerticalPadding: 12,
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      subtitle: Text(note, style: const TextStyle(color: Cult.muted)),
      trailing: const Icon(Icons.chevron_right, color: Cult.muted),
      onTap: onTap,
    );
  }
}

class VisitsPage extends StatelessWidget {
  const VisitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Визиты')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
                            if (!context.mounted || message == null) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          for (final visit in pastVisits)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(visit.title),
              subtitle: Text('${visit.date}\n${visit.doctor} · ${visit.place}'),
              isThreeLine: true,
              trailing: Text(visit.receipt),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(visit.title),
                    content: Text('Чек ${visit.receipt}. ${visit.doctor}, ${visit.place}.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть'))],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class AnalysesPage extends StatelessWidget {
  const AnalysesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои анализы')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final visit in labVisits)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(visit.title),
              subtitle: Text(visit.date),
              trailing: Text(visit.status, style: const TextStyle(color: Cult.primary, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 8),
          const Text('PDF результатов открывается здесь. В этой версии файл хранится на устройстве как заключение.'),
          const SizedBox(height: 8),
          CultButton(
            label: 'Открыть анализ крови',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Анализ крови'),
                  content: const Text('Заключение: показатели в референсе. Врач рекомендует продолжить текущий протокол.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть'))],
                ),
              );
            },
          ),
          TextButton(onPressed: () => pushPage(context, const BookingPage(initialService: 'Анализ крови')), child: const Text('Записать анализ')),
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
          ] else if (store.yclientsReady && store.userToken.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Карта филиала появится, когда в разделе YClients будет токен пользователя и телефон.'),
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
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Визиты'), value: store.notices['visits'] ?? true, onChanged: (value) => store.setNotice('visits', value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Анализы'), value: store.notices['analyses'] ?? true, onChanged: (value) => store.setNotice('analyses', value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Аптечка'), value: store.notices['pharmacy'] ?? true, onChanged: (value) => store.setNotice('pharmacy', value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Предложения'), value: store.notices['offers'] ?? false, onChanged: (value) => store.setNotice('offers', value)),
        ],
      ),
    );
  }
}
