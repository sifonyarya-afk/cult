import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Биохакинг-шоп', style: cultHeadline(28))),
                  ActionChip(
                    avatar: const Icon(Icons.smart_toy_outlined, size: 18),
                    label: const Text('ИИ'),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Уход, БАДы и наборы для дома.', style: TextStyle(color: Cult.muted)),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          labelColor: Cult.ink,
          unselectedLabelColor: Cult.muted,
          indicatorColor: Cult.ink,
          tabs: const [Tab(text: 'Косметика'), Tab(text: 'БАДы'), Tab(text: 'Биохакинг')],
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
      ],
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.tab});

  final String tab;

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final list = products.where((item) => item.tab == tab).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final product in list) ...[
          InkWell(
            onTap: () => pushPage(context, ProductPage(product: product)),
            child: Column(
              children: [
                CultImage(product.image, radius: 12),
                const SizedBox(height: 10),
                Text(product.name, style: cultHeadline(22), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  product.blurb,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Cult.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(rub(product.price), style: cultHeadline(22).copyWith(color: Cult.primary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CultButton(
            label: 'В корзину',
            onPressed: () {
              store.addToCart(product.id, product.name, product.price);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} в корзине')));
            },
          ),
          const SizedBox(height: 28),
        ],
      ],
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
    final kind = product.tab == 'cosmetics' ? 'Косметика' : product.tab == 'biohack' ? 'Биохакинг' : 'БАДы';
    return Scaffold(
      appBar: AppBar(title: const Text('Товар')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CultImage(product.image, radius: 12),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('$kind · ${product.stock == 'low' ? 'Мало' : 'В наличии'}'.toUpperCase(), style: const TextStyle(color: Cult.primary, letterSpacing: 1))),
              IconButton(
                onPressed: () => store.toggleFavorite(product.id),
                icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: Cult.primary),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
          Text(product.name, style: cultHeadline(28)),
          const SizedBox(height: 6),
          Text(product.blurb),
          const SizedBox(height: 8),
          Text(rub(product.price), style: cultHeadline(26).copyWith(color: Cult.primary)),
          const SizedBox(height: 12),
          Text('Состав', style: cultHeadline(20)),
          const SizedBox(height: 4),
          Text(product.composition),
          const SizedBox(height: 12),
          Text(product.about),
          const SizedBox(height: 20),
          CultButton(
            label: 'В корзину',
            onPressed: () {
              store.addToCart(product.id, product.name, product.price);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Добавлено в корзину')));
            },
          ),
          TextButton(onPressed: () => pushPage(context, const CartPage()), child: const Text('Перейти к оформлению')),
        ],
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
    if (store.profilePhone.trim().isNotEmpty) _phone.text = store.profilePhone;
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
      appBar: AppBar(title: const Text('Корзина')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_done) ...[
            Text('Заказ оформлен', style: cultHeadline(28)),
            const SizedBox(height: 8),
            Text('К оплате ${rub(_due)}. ${_courier ? 'Курьер приедет по адресу ${_address.text}.' : 'Заберите на ресепшен клиники.'}'),
            const SizedBox(height: 16),
            CultButton(label: 'Готово', onPressed: () => Navigator.pop(context)),
          ] else if (store.cart.isEmpty) ...[
            Text('Корзина пуста', style: cultHeadline(28)),
            const SizedBox(height: 8),
            const Text('Добавьте формулу из магазина.'),
            const SizedBox(height: 16),
            CultButton(label: 'В магазин', onPressed: () => Navigator.pop(context)),
          ] else ...[
            for (final item in store.cart)
              ListTile(
                contentPadding: EdgeInsets.zero,
                minVerticalPadding: 12,
                title: Text(item.name),
                subtitle: Text(rub(item.price)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => store.setQty(item.id, item.qty - 1),
                      icon: const Icon(Icons.remove),
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                    Text('${item.qty}'),
                    IconButton(
                      onPressed: () => store.setQty(item.id, item.qty + 1),
                      icon: const Icon(Icons.add),
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text('Итого ${rub(store.cartTotal)}', style: cultHeadline(22)),
            const SizedBox(height: 4),
            Text('Бонусы ${rub(store.balance)}', style: const TextStyle(color: Cult.muted)),
            const SizedBox(height: 16),
            TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Имя')),
            const SizedBox(height: 12),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Телефон')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Курьер'),
              subtitle: const Text('Иначе самовывоз в клинике'),
              value: _courier,
              onChanged: (value) => setState(() => _courier = value),
            ),
            if (_courier) ...[
              const SizedBox(height: 4),
              TextField(controller: _address, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Адрес')),
            ],
            RadioGroup<String>(
              groupValue: _pay,
              onChanged: (value) => setState(() => _pay = value ?? _pay),
              child: const Column(
                children: [
                  RadioListTile<String>(title: Text('Картой при получении'), value: 'card'),
                  RadioListTile<String>(title: Text('Бонусами'), value: 'bonus'),
                  RadioListTile<String>(title: Text('Смешанная оплата, бонусами до 30%'), value: 'mixed'),
                ],
              ),
            ),
            if (_error.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8E8E6), borderRadius: BorderRadius.circular(12)),
                child: Text(_error, style: const TextStyle(color: Cult.error)),
              ),
            const SizedBox(height: 8),
            CultButton(
              label: 'Оформить заказ',
              onPressed: () {
                final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
                if (_name.text.trim().length < 2 || digits.length < 11) {
                  setState(() => _error = 'Укажите имя и телефон в формате +7.');
                  return;
                }
                if (_courier && _address.text.trim().length < 5) {
                  setState(() => _error = 'Для курьера нужен адрес.');
                  return;
                }
                final total = store.cartTotal;
                final bonusPay = _pay == 'card' ? 0 : (_pay == 'bonus' ? total : (total * 0.3).round()).clamp(0, store.balance);
                if (_pay != 'card' && !store.spendBonus(bonusPay)) {
                  setState(() => _error = 'Бонусов не хватает.');
                  return;
                }
                final due = total - bonusPay;
                store.placeOrder(
                  title: store.cart.map((item) => item.name).join(', '),
                  total: due,
                  pay: _pay == 'card' ? 'Карта' : _pay == 'bonus' ? 'Бонусы' : 'Карта и бонусы',
                );
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
}
