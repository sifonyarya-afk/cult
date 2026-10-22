import 'package:cult_clinic/data.dart';
import 'package:cult_clinic/main.dart';
import 'package:cult_clinic/pages/talk.dart';
import 'package:cult_clinic/store.dart';
import 'package:cult_clinic/widgets.dart';
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
}
