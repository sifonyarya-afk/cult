import 'package:cult_clinic/data.dart';
import 'package:cult_clinic/main.dart';
import 'package:cult_clinic/pages/browse.dart';
import 'package:cult_clinic/pages/home.dart';
import 'package:cult_clinic/pages/shop.dart';
import 'package:cult_clinic/pages/talk.dart';
import 'package:cult_clinic/store.dart';
import 'package:cult_clinic/theme.dart';
import 'package:cult_clinic/widgets.dart';
import 'package:cult_clinic/yclients.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Главная ведёт в анализы и магазин биохакинга', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    await store.setGender(ClientGender.woman);
    await tester.pumpWidget(CultApp(store: store, splash: Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('Онлайн запись'), findsOneWidget);
    expect(find.text('Магазин биохакинга'), findsOneWidget);
    expect(find.text('Чат с врачом'), findsOneWidget);

    await tester.ensureVisible(find.text('Мои анализы'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Мои анализы'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Войдите по телефону'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Магазин биохакинга'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Магазин биохакинга'));
    await tester.pumpAndSettle();
    expect(find.text('Home Bio-Scan Kit'), findsOneWidget);
  });

  testWidgets('После сплэша спрашивает пол', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    await tester.pumpWidget(CultApp(store: store, splash: Duration.zero));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ваш путь к совершенству'), findsOneWidget);
    expect(find.text('ЖЕНЩИНА'), findsOneWidget);
    expect(find.text('МУЖЧИНА'), findsOneWidget);
    expect(find.text('НАЧАТЬ'), findsOneWidget);
  });

  testWidgets('Сплэш можно пропустить тапом', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    await tester.pumpWidget(
      CultApp(store: store, splash: const Duration(seconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Нажмите, чтобы продолжить'), findsOneWidget);
    await tester.tap(find.text('CULT').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Ваш путь к совершенству'), findsOneWidget);
  });

  test('Запись отменяется, бонусов не хватает на крупный сертификат', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.bookVisit(
      service: 'Анализ крови',
      doctor: 'AlethiaPro',
      date: '2026-04-12',
      time: '10:30',
    );
    expect(store.upcoming.length, 1);
    await store.cancelVisit(store.upcoming.first.id);
    expect(
      store.upcoming.where((visit) => visit.service == 'Анализ крови'),
      isEmpty,
    );
    expect(store.spendBonus(30000), isFalse);
    final code = store.buyGift(5000, 'Песок');
    expect(code, startsWith('CULT-5-'));
    expect(store.gifts, isNotEmpty);
  });

  test('Welcome-бонус учитывается в балансе и сохраняется', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    final before = store.balance;
    store.welcomeBonus = 3000;
    store.welcomeGranted = true;
    expect(store.balance, before + 3000);
    await store.setGender(ClientGender.woman);
    final restored = ClinicStore();
    await restored.load();
    expect(restored.welcomeGranted, isTrue);
    expect(restored.welcomeBonus, 3000);
    expect(restored.balance, before + 3000);
  });

  test('Бот отвечает на быстрые вопросы в чате', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    final before = store.threads['bot']!.length;
    store.sendMessage('bot', 'Хочу записаться');
    final thread = store.threads['bot']!;
    expect(thread.length, before + 2);
    expect(thread[thread.length - 2].from, 'me');
    expect(thread.last.from, 'them');
    expect(thread.last.text.toLowerCase(), contains('запись'));
  });

  test('Корзина оформляет заказ и очищается', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.addToCart('p1', 'Serum CULT', 4500);
    store.addToCart('p1', 'Serum CULT', 4500);
    expect(store.cartCount, 2);
    expect(store.cartTotal, 9000);
    store.placeOrder(title: 'Serum CULT', total: 9000, pay: 'Карта');
    expect(store.cart, isEmpty);
    expect(store.orders, isNotEmpty);
    expect(store.orders.first.title, 'Serum CULT');
    expect(store.orders.first.total, 9000);
  });

  testWidgets('Поиск услуг очищается крестиком', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    await store.setGender(ClientGender.woman);
    await tester.pumpWidget(CultApp(store: store, splash: Duration.zero));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Услуги'));
    await tester.pumpAndSettle();
    expect(find.text('Поиск процедур...'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'морфеус');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Очистить'), findsOneWidget);
    await tester.tap(find.byTooltip('Очистить'));
    await tester.pumpAndSettle();
    expect(find.text('морфеус'), findsNothing);
  });

  test('Уведомления и избранное сохраняются', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.setNotice('offers', true);
    store.toggleFavorite('serum-cult');
    expect(store.notices['offers'], isTrue);
    expect(store.favorites, contains('serum-cult'));
    final restored = ClinicStore();
    await restored.load();
    expect(restored.notices['offers'], isTrue);
    expect(restored.favorites, contains('serum-cult'));
  });

  test('Заявка на трансфер уходит администратору', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    final before = store.threads['admin']!.length;
    store.sendMessage(
      'admin',
      'Трансфер: забрать с «Адлер, отель» → Черноморская, 6.',
    );
    final thread = store.threads['admin']!;
    expect(thread.length, greaterThan(before));
    expect(thread.any((m) => m.text.contains('Адлер')), isTrue);
  });

  testWidgets('Запись принимает выбранного врача', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.partnerToken = '';
    store.userToken = '';
    store.companyId = '';
    await tester.pumpWidget(
      ClinicScope(
        store: store,
        child: const MaterialApp(
          home: BookingPage(initialDoctor: 'Д-р Элара Торн'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Элара'), findsWidgets);
  });

  testWidgets('Карточка услуги держит кнопку записи внизу', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    await tester.pumpWidget(
      ClinicScope(
        store: store,
        child: MaterialApp(home: ServicePage(service: services.first)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('ЗАПИСАТЬСЯ'), findsOneWidget);
    expect(find.byType(CultBookBar), findsOneWidget);
    expect(find.textContaining(services.first.priceLabel), findsWidgets);
  });

  test('Бот отвечает про выходные', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Работаете в воскресенье?');
    expect(
      store.threads['bot']!.last.text.toLowerCase(),
      contains('выходн'),
    );
  });

  test('Бот отвечает про сертификат и трансфер', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Нужен сертификат');
    expect(
      store.threads['bot']!.last.text.toLowerCase(),
      contains('сертификат'),
    );
    store.sendMessage('bot', 'Нужен трансфер');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('трансфер'));
    store.sendMessage('admin', 'такси к отелю');
    expect(
      store.threads['admin']!.last.text.toLowerCase(),
      contains('трансфер'),
    );
  });

  test('Бот отвечает про парковку и анализы', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Где парковка?');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('парков'));
    store.sendMessage('bot', 'Хочу сдать анализы');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('анализ'));
    store.sendMessage('admin', 'Есть парковка?');
    expect(
      store.threads['admin']!.last.text.toLowerCase(),
      contains('парков'),
    );
  });

  test('Бот отвечает про скидки, корзина очищается', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Какие скидки?');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('бонус'));
    store.addToCart('p1', 'Serum CULT', 4500);
    store.addToCart('p2', 'Kit', 9000);
    expect(store.cartCount, 2);
    expect(store.hasUnreadChat, isTrue);
    store.clearCart();
    expect(store.cart, isEmpty);
    expect(store.cartCount, 0);
  });

  test('Прочтение чата снимает непрочитанное', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    expect(store.hasUnreadChat, isFalse);
    store.sendMessage('bot', 'Нужен врач');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('врач'));
    expect(store.isChatUnread('bot'), isTrue);
    store.markChatRead('bot');
    expect(store.isChatUnread('bot'), isFalse);
    final restored = ClinicStore();
    await restored.load();
    expect(restored.isChatUnread('bot'), isFalse);
  });

  test('Бот отвечает про аппаратную косметологию', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Расскажите про аппаратную');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('аппарат'));
    store.sendMessage('bot', 'Хочу филлеры');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('инъек'));
  });

  test('Корзина сохраняет контакт при оформлении', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.rememberContact(
      name: 'Ирина К.',
      phone: '+7 (900) 111-22-33',
      email: 'irina@cult.sochi',
    );
    expect(store.profileName, 'Ирина К.');
    expect(normalizePhone(store.profilePhone), '79001112233');
    expect(store.profileEmail, 'irina@cult.sochi');
  });

  test('formatVisitDate понимает дату со временем', () {
    expect(formatVisitDate('2026-04-12T10:30:00'), '12 апреля');
    expect(formatVisitDate('2026-04-12 10:30:00'), '12 апреля');
    final now = DateTime.now();
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    expect(formatVisitDate(iso(now)), 'сегодня');
    expect(formatVisitDate(iso(now.add(const Duration(days: 1)))), 'завтра');
    expect(
      formatVisitDate(iso(now.subtract(const Duration(days: 1)))),
      'вчера',
    );
  });

  test('formatVisitCountdown считает ожидание', () {
    final soon = DateTime.now().add(const Duration(hours: 3, minutes: 5));
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final clock =
        '${soon.hour.toString().padLeft(2, '0')}:${soon.minute.toString().padLeft(2, '0')}';
    expect(formatVisitCountdown(iso(soon), clock), 'через 3 ч');
    final past = DateTime.now().subtract(const Duration(hours: 2));
    final pastClock =
        '${past.hour.toString().padLeft(2, '0')}:${past.minute.toString().padLeft(2, '0')}';
    expect(formatVisitCountdown(iso(past), pastClock), isEmpty);
  });

  test('Бот отвечает про консультацию', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Нужна консультация');
    expect(
      store.threads['bot']!.last.text.toLowerCase(),
      contains('консультац'),
    );
    store.sendMessage('bot', 'Можно ли детям?');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('18'));
  });

  test('Переписку можно очистить', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Хочу записаться');
    expect(store.threads['bot']!.length, greaterThan(1));
    store.clearChat('bot');
    expect(store.threads['bot']!.length, 1);
    expect(store.threads['bot']!.first.from, 'them');
    expect(store.isChatUnread('bot'), isFalse);
  });

  test('Покупка сертификата пишет администратору', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    final before = store.threads['admin']!.length;
    final code = store.buyGift(5000, 'Песок');
    store.sendMessage('admin', 'Сертификат $code на ${rub(5000)}, дизайн Песок.');
    expect(store.threads['admin']!.length, greaterThan(before));
    expect(store.threads['admin']!.any((m) => m.text.contains(code)), isTrue);
  });

  test('Бот отвечает про инфузии', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Хочу капельницу');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('инфуз'));
    store.sendMessage('bot', 'Интересует NAD+');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('nad'));
  });

  test('Позицию корзины можно обнулить', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.addToCart('p1', 'Serum CULT', 4500);
    store.addToCart('p2', 'Kit', 9000);
    expect(store.cartCount, 2);
    store.setQty('p1', 0);
    expect(store.cart.where((item) => item.id == 'p1'), isEmpty);
    expect(store.cartCount, 1);
  });

  testWidgets('Товар держит кнопку «В корзину» внизу', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    await tester.pumpWidget(
      ClinicScope(
        store: store,
        child: MaterialApp(home: ProductPage(product: products.first)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CultBookBar), findsOneWidget);
    expect(find.textContaining('В КОРЗИНУ'), findsOneWidget);
  });

  test('Бот отвечает про массаж, доставку и лазер', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Нужен массаж');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('массаж'));
    store.sendMessage('bot', 'Как работает доставка?');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('шоп'));
    store.sendMessage('bot', 'Интересует лазер');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('лазер'));
    store.sendMessage('specialist', 'Синяк после процедуры');
    expect(
      store.threads['specialist']!.last.text.toLowerCase(),
      contains('активн'),
    );
    store.sendMessage('admin', 'Где мой заказ?');
    expect(store.threads['admin']!.last.text.toLowerCase(), contains('заказ'));
  });

  test('Избранное очищается, заказ повторяется в корзину', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    final product = products.first;
    store.toggleFavorite(product.id);
    expect(store.favorites, contains(product.id));
    expect(store.addFavoritesToCart(), 1);
    expect(store.cart.any((item) => item.id == product.id), isTrue);
    store.clearCart();
    store.clearFavorites();
    expect(store.favorites, isEmpty);
    store.placeOrder(
      title: product.name,
      total: product.price,
      pay: 'Карта',
    );
    final added = store.reorderFromTitle(store.orders.first.title);
    expect(added, greaterThan(0));
    expect(store.cart.any((item) => item.id == product.id), isTrue);
  });

  test('formatVisitWeekday знает день недели', () {
    expect(formatVisitWeekday('2026-04-12'), 'воскресенье');
    expect(formatVisitWeekday('не дата'), isEmpty);
  });

  test('Бот отвечает про ресепшен и контур', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Где ресепшен?');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('ресепшен'));
    store.sendMessage('bot', 'Интересует контурная пластика');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('контурн'));
  });

  test('Бот отвечает про постакне и купероз', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Как убрать постакне?');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('постакне'));
    store.sendMessage('bot', 'Беспокоит купероз');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('купероз'));
    store.sendMessage('bot', 'Что умеет приложение?');
    expect(
      store.threads['bot']!.last.text.toLowerCase(),
      contains('приложен'),
    );
  });

  test('Бот отвечает про рассрочку и оплату', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Есть рассрочка?');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('рассрочк'));
    store.sendMessage('bot', 'Как оплатить картой?');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('оплат'));
    store.sendMessage('bot', 'Какой телефон клиники?');
    expect(store.threads['bot']!.last.text, contains('495'));
  });

  test('Бот отвечает про подготовку, документы и аллергию', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Какая подготовка к визиту?');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('перед'));
    store.sendMessage('bot', 'Какие документы нужны?');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('паспорт'));
    store.sendMessage('bot', 'У меня аллергия на анестезию');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('аллерг'));
    store.sendMessage('bot', 'Сколько длится процедура?');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('длительн'));
    store.sendMessage('bot', 'Есть телеграм клиники?');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('чат'));
    store.sendMessage('admin', 'Какой телефон клиники?');
    expect(store.threads['admin']!.last.text, contains('495'));
    store.sendMessage('specialist', 'Как подготовиться к процедуре?');
    expect(
      store.threads['specialist']!.last.text.toLowerCase(),
      contains('подготов'),
    );
  });

  test('Бот и админ отвечают про отмену записи', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Как отменить запись?');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('отмен'));
    store.sendMessage('admin', 'Нужно перенести визит');
    expect(store.threads['admin']!.last.text.toLowerCase(), contains('перенос'));
  });

  test('Бот отвечает про реабилитацию и анестезию', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Какая реабилитация после?');
    expect(
      store.threads['bot']!.last.text.toLowerCase(),
      contains('реабилитац'),
    );
    store.sendMessage('bot', 'Делают ли обезболивание?');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('анестез'));
    store.sendMessage('specialist', 'Сильное шелушение');
    expect(
      store.threads['specialist']!.last.text.toLowerCase(),
      contains('шелушен'),
    );
  });

  test('Переписку можно скопировать текстом', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Хочу записаться');
    final text = store.chatTranscript('bot');
    expect(text, contains('CULT'));
    expect(text, contains('Вы:'));
    expect(text.toLowerCase(), contains('запись'));
  });

  test('Бот отвечает про эпиляцию и мезотерапию', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Хочу эпиляцию');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('эпиляц'));
    store.sendMessage('bot', 'Нужна мезотерапия');
    expect(store.threads['bot']!.last.text.toLowerCase(), contains('мезотерап'));
  });

  test('Оформление заказа пишет администратору', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    final before = store.threads['admin']!.length;
    store.addToCart(products.first.id, products.first.name, products.first.price);
    store.placeOrder(
      title: products.first.name,
      total: products.first.price,
      pay: 'Карта',
    );
    store.sendMessage(
      'admin',
      'Заказ шопа: ${products.first.name} · к оплате ${rub(products.first.price)} · Карта · самовывоз.',
    );
    expect(store.threads['admin']!.length, greaterThan(before));
    expect(
      store.threads['admin']!.any((m) => m.text.contains(products.first.name)),
      isTrue,
    );
  });

  test('Все чаты можно отметить прочитанными', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Нужен массаж');
    store.sendMessage('admin', 'Где парковка?');
    expect(store.hasUnreadChat, isTrue);
    store.markAllChatsRead();
    expect(store.hasUnreadChat, isFalse);
    expect(store.isChatUnread('bot'), isFalse);
    expect(store.isChatUnread('admin'), isFalse);
  });

  testWidgets('Мужской профиль меняет оффер на главной', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    await store.setGender(ClientGender.man);
    await tester.pumpWidget(
      ClinicScope(
        store: store,
        child: MaterialApp(
          home: Scaffold(body: HomePage(onShop: () {})),
        ),
      ),
    );
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('Мужской уход за лицом'), findsOneWidget);
    expect(find.text('Прецизионный анализ кожи'), findsNothing);
  });
}
