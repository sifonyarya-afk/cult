import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import '../yclients.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 3,
    vsync: this,
    initialIndex: widget.initialTab,
  );

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) cultTapFeedback();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Биохакинг-шоп', style: cultHeadline(28)),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.smart_toy_outlined, size: 18),
                    label: const Text('ИИ Помощник'),
                    onPressed: () {
                      cultTapFeedback();
                      _openAiPicker(context, store);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Уход, БАДы и наборы для дома.',
                style: TextStyle(color: Cult.muted),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          labelColor: Cult.ink,
          unselectedLabelColor: Cult.muted,
          indicatorColor: Cult.ink,
          tabs: const [
            Tab(text: 'Косметика'),
            Tab(text: 'БАДы'),
            Tab(text: 'Биохакинг'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _ProductList(tab: 'cosmetics'),
              _ProductList(tab: 'supplements'),
              _ProductList(tab: 'biohack'),
            ],
          ),
        ),
        if (store.cartCount > 0)
          Material(
            color: Cult.bg,
            elevation: 8,
            shadowColor: const Color(0x14000000),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: CultButton(
                  label:
                      'Корзина · ${store.cartCount} · ${rub(store.cartTotal)}',
                  onPressed: () => pushPage(context, const CartPage()),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

void _openAiPicker(BuildContext context, ClinicStore store) {
  final pool = products.where((item) {
    if (store.gender == ClientGender.man) {
      return item.tab == 'biohack' || item.tab == 'supplements';
    }
    if (store.gender == ClientGender.woman) {
      return item.tab == 'cosmetics' || item.tab == 'supplements';
    }
    return true;
  }).toList();
  final source = pool.isEmpty ? products : pool;
  final pick = source.isEmpty
      ? null
      : source[DateTime.now().millisecond % source.length];
  showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ИИ-подбор', style: cultHeadline(26)),
            const SizedBox(height: 8),
            Text(
              store.gender == null
                  ? 'По вашему профилю CULT рекомендуем формулу для домашнего протокола.'
                  : 'Подбор для профиля «${store.gender!.label}»: формула под домашний протокол.',
              style: const TextStyle(color: Cult.muted, height: 1.4),
            ),
            if (pick != null) ...[
              const SizedBox(height: 16),
              CultCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pick.name, style: cultHeadline(20)),
                    const SizedBox(height: 4),
                    Text(
                      pick.blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Cult.muted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rub(pick.price),
                      style: cultHeadline(22).copyWith(color: Cult.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CultButton(
                label: 'В корзину · ${rub(pick.price)}',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  store.addToCart(pick.id, pick.name, pick.price);
                  Navigator.pop(sheet);
                  showCultSnack(
                    context,
                    '${pick.name} в корзине',
                    actionLabel: 'Оформить',
                    onAction: () => pushPage(context, const CartPage()),
                  );
                },
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheet);
                  pushPage(context, ProductPage(product: pick));
                },
                child: const Text('Открыть карточку'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _ProductList extends StatefulWidget {
  const _ProductList({required this.tab});

  final String tab;

  @override
  State<_ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<_ProductList> {
  final _query = TextEditingController();
  var _cheapFirst = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final needle = _query.text.trim().toLowerCase();
    final list = products.where((item) {
      if (item.tab != widget.tab) return false;
      if (needle.isEmpty) return true;
      return item.name.toLowerCase().contains(needle) ||
          item.blurb.toLowerCase().contains(needle);
    }).toList();
    if (_cheapFirst) {
      list.sort((a, b) => a.price.compareTo(b.price));
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          CultSearchField(
            controller: _query,
            hint: 'Найти формулу',
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              label: const Text('Сначала дешевле'),
              selected: _cheapFirst,
              onSelected: (value) {
                cultTapFeedback();
                setState(() => _cheapFirst = value);
              },
            ),
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
            for (final product in list) ...[
              Semantics(
                button: true,
                label: '${product.name}, ${rub(product.price)}',
                child: InkWell(
                  onTap: () {
                    cultTapFeedback();
                    pushPage(context, ProductPage(product: product));
                  },
                  onLongPress: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: '${product.name} · ${rub(product.price)}',
                      ),
                    );
                    cultTapFeedback();
                    showCultSnack(context, 'Формула скопирована');
                  },
                  child: Column(
                    children: [
                      CultImage(product.image, radius: 12),
                      const SizedBox(height: 10),
                      Text(
                        product.name,
                        style: cultHeadline(22),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.blurb,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Cult.muted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rub(product.price),
                        style: cultHeadline(22).copyWith(color: Cult.primary),
                      ),
                      if (product.stock == 'low') ...[
                        const SizedBox(height: 4),
                        Text(
                          'Осталось мало',
                          style: TextStyle(
                            color: Cult.error.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CultButton(
                label: 'В корзину',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  store.addToCart(product.id, product.name, product.price);
                  showCultSnack(
                    context,
                    '${product.name} в корзине',
                    actionLabel: 'Оформить',
                    onAction: () => pushPage(context, const CartPage()),
                  );
                },
              ),
              const SizedBox(height: 28),
            ],
        ],
      ),
    );
  }
}

class ProductPage extends StatelessWidget {
  const ProductPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final liked = store.favorites.contains(product.id);
    final kind = product.tab == 'cosmetics'
        ? 'Косметика'
        : product.tab == 'biohack'
        ? 'Биохакинг'
        : 'БАДы';
    return Scaffold(
      appBar: AppBar(title: const Text('CULT')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          CultImage(product.image, aspect: 1, radius: 18),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$kind · ${product.stock == 'low' ? 'Мало' : 'В наличии'}'
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Cult.primary,
                    letterSpacing: 1.2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: liked ? 'Убрать из избранного' : 'В избранное',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  store.toggleFavorite(product.id);
                  showCultSnack(
                    context,
                    liked ? 'Убрали из избранного' : 'В избранном',
                  );
                },
                icon: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  color: Cult.primary,
                ),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(
                ClipboardData(
                  text:
                      '${product.name} · ${rub(product.price)} · CULT Clinic',
                ),
              );
              cultTapFeedback();
              showCultSnack(context, 'Формула скопирована');
            },
            child: Text(product.name, style: cultHeadline(28)),
          ),
          const SizedBox(height: 6),
          Text(
            product.blurb,
            style: const TextStyle(color: Cult.muted, height: 1.4),
          ),
          const SizedBox(height: 10),
          Text(
            rub(product.price),
            style: cultHeadline(28).copyWith(color: Cult.primary),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              store.sendMessage(
                'specialist',
                'Вопрос по формуле «${product.name}» (${rub(product.price)}).',
              );
              showCultSnack(
                context,
                'Сообщение врачу отправлено — откройте Чат',
              );
            },
            child: const Text('Спросить врача о формуле'),
          ),
          const SizedBox(height: 8),
          const CultSectionLabel('Состав'),
          const SizedBox(height: 8),
          Text(product.composition, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 16),
          const CultSectionLabel('О формуле'),
          const SizedBox(height: 8),
          Text(
            product.about,
            style: const TextStyle(color: Cult.muted, height: 1.4),
          ),
          if (store.cartCount > 0) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                cultTapFeedback();
                pushPage(context, const CartPage());
              },
              child: Text('В корзине ${store.cartCount} · оформить'),
            ),
          ],
        ],
      ),
      bottomNavigationBar: CultBookBar(
        label: 'В корзину · ${rub(product.price)}',
        onPressed: () {
          HapticFeedback.mediumImpact();
          store.addToCart(product.id, product.name, product.price);
          showCultSnack(
            context,
            '${product.name} в корзине',
            actionLabel: 'Оформить',
            onAction: () => pushPage(context, const CartPage()),
          );
        },
      ),
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _name = TextEditingController(text: 'Александра В.');
  final _phone = TextEditingController();
  final _address = TextEditingController();
  var _courier = false;
  var _pay = 'card';
  var _error = '';
  var _done = false;
  var _due = 0;
  var _filled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    final store = ClinicScope.of(context);
    if (store.profileName.trim().isNotEmpty) _name.text = store.profileName;
    if (store.profilePhone.trim().isNotEmpty) {
      _phone.text = formatRuPhone(store.profilePhone);
    } else {
      _phone.text = '+7';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        actions: [
          if (!_done && store.cart.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(store),
              child: const Text('Очистить'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_done)
            CultCard(
              key: const ValueKey('cart-done'),
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
                      Icons.check_circle,
                      color: Cult.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Заказ оформлен', style: cultHeadline(26)),
                  const SizedBox(height: 8),
                  Text(
                    'К оплате ${rub(_due)}. ${_courier ? 'Курьер приедет по адресу ${_address.text}.' : 'Заберите на ресепшен клиники.'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Cult.muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  CultButton(
                    label: 'Готово',
                    onPressed: () {
                      showCultSnack(
                        context,
                        'Заказ сохранён в профиле → Мои заказы',
                      );
                      Navigator.pop(context);
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      final summary =
                          'Заказ CULT · ${rub(_due)} · ${_courier ? 'Курьер: ${_address.text.trim()}' : 'Самовывоз'} · ${_name.text.trim()}';
                      Clipboard.setData(ClipboardData(text: summary));
                      cultTapFeedback();
                      showCultSnack(context, 'Чек скопирован');
                    },
                    child: const Text('Скопировать чек'),
                  ),
                  TextButton(
                    onPressed: () {
                      cultTapFeedback();
                      showCultSnack(
                        context,
                        'Заказ уже у администратора — откройте вкладку Чат',
                      );
                    },
                    child: const Text('Статус в чате'),
                  ),
                ],
              ),
            )
          else if (store.cart.isEmpty) ...[
            CultEmpty(
              title: 'Корзина пуста',
              note: 'Добавьте формулу из биохакинг-шопа.',
              actionLabel: 'В магазин',
              onAction: () => Navigator.pop(context),
            ),
          ] else ...[
            const Text(
              'Смахните позицию влево, чтобы удалить.',
              style: TextStyle(color: Cult.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            for (final item in store.cart)
              Dismissible(
                key: ValueKey('cart-${item.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Cult.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline, color: Cult.error),
                ),
                onDismissed: (_) {
                  store.setQty(item.id, 0);
                  HapticFeedback.mediumImpact();
                  showCultSnack(context, '${item.name} удалено');
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CultCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: cultHeadline(18)),
                              const SizedBox(height: 4),
                              Text(
                                rub(item.price),
                                style: const TextStyle(
                                  color: Cult.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Меньше',
                          onPressed: () {
                            cultTapFeedback();
                            store.setQty(item.id, item.qty - 1);
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                        Semantics(
                          label: 'Количество ${item.qty}',
                          child: Text(
                            '${item.qty}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Больше',
                          onPressed: () {
                            cultTapFeedback();
                            store.setQty(item.id, item.qty + 1);
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            CultCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Итого ${rub(store.cartTotal)}',
                    style: cultHeadline(22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Бонусы ${rub(store.balance)}',
                    style: const TextStyle(color: Cult.muted),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        final lines = store.cart
                            .map(
                              (item) =>
                                  '· ${item.name} ×${item.qty} — ${rub(item.price * item.qty)}',
                            )
                            .join('\n');
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                'Корзина CULT\n$lines\nИтого ${rub(store.cartTotal)}',
                          ),
                        );
                        cultTapFeedback();
                        showCultSnack(context, 'Состав корзины скопирован');
                      },
                      child: const Text('Скопировать состав'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: const [CultPhoneInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Телефон',
                hintText: '+7 (___) ___-__-__',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Курьер'),
              subtitle: const Text('Иначе самовывоз в клинике'),
              value: _courier,
              onChanged: (value) {
                cultTapFeedback();
                setState(() => _courier = value);
              },
            ),
            if (_courier) ...[
              const SizedBox(height: 4),
              TextField(
                controller: _address,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Адрес'),
              ),
            ],
            RadioGroup<String>(
              groupValue: _pay,
              onChanged: (value) {
                cultTapFeedback();
                setState(() => _pay = value ?? _pay);
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    title: Text('Картой при получении'),
                    value: 'card',
                  ),
                  RadioListTile<String>(
                    title: Text('Бонусами'),
                    value: 'bonus',
                  ),
                  RadioListTile<String>(
                    title: Text('Смешанная оплата, бонусами до 30%'),
                    value: 'mixed',
                  ),
                ],
              ),
            ),
            if (_error.isNotEmpty) CultErrorBanner(message: _error),
            const SizedBox(height: 8),
            CultButton(
              label: 'Оформить заказ',
              onPressed: () {
                final digits = normalizePhone(_phone.text);
                if (_name.text.trim().length < 2 || digits.length < 11) {
                  setState(
                    () => _error = 'Укажите имя и телефон в формате +7.',
                  );
                  return;
                }
                if (_courier && _address.text.trim().length < 5) {
                  setState(() => _error = 'Для курьера нужен адрес.');
                  return;
                }
                final total = store.cartTotal;
                final bonusPay = _pay == 'card'
                    ? 0
                    : (_pay == 'bonus' ? total : (total * 0.3).round()).clamp(
                        0,
                        store.balance,
                      );
                if (_pay != 'card' && !store.spendBonus(bonusPay)) {
                  setState(() => _error = 'Бонусов не хватает.');
                  return;
                }
                final due = total - bonusPay;
                store.rememberContact(
                  name: _name.text,
                  phone: _phone.text.trim(),
                  email: store.profileEmail,
                );
                final title = store.cart.map((item) => item.name).join(', ');
                final payLabel = _pay == 'card'
                    ? 'Карта'
                    : _pay == 'bonus'
                    ? 'Бонусы'
                    : 'Карта и бонусы';
                store.placeOrder(
                  title: title,
                  total: due,
                  pay: payLabel,
                );
                store.sendMessage(
                  'admin',
                  'Заказ шопа: $title · к оплате ${rub(due)} · $payLabel'
                  '${_courier ? ' · курьер: ${_address.text.trim()}' : ' · самовывоз'}'
                  ' · ${_name.text.trim()}.',
                );
                HapticFeedback.mediumImpact();
                setState(() {
                  _error = '';
                  _due = due;
                  _done = true;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmClear(ClinicStore store) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Очистить корзину?'),
        content: const Text('Все формулы будут удалены из заказа.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Оставить'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Очистить', style: TextStyle(color: Cult.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    store.clearCart();
    HapticFeedback.mediumImpact();
    showCultSnack(context, 'Корзина очищена');
  }
}
