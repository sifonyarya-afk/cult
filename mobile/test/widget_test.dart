import 'package:cult_clinic/data.dart';
import 'package:cult_clinic/main.dart';
import 'package:cult_clinic/store.dart';
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
    expect(find.text('Для кого протокол?'), findsOneWidget);
    expect(find.text('Женщина'), findsOneWidget);
    expect(find.text('Мужчина'), findsOneWidget);
  });

  test('Запись отменяется, бонусов не хватает на крупный сертификат', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.bookVisit(service: 'Анализ крови', doctor: 'AlethiaPro', date: '2026-04-12', time: '10:30');
    expect(store.upcoming.length, 1);
    await store.cancelVisit(store.upcoming.first.id);
    expect(store.upcoming.where((visit) => visit.service == 'Анализ крови'), isEmpty);
    expect(store.spendBonus(30000), isFalse);
    final code = store.buyGift(5000, 'Песок');
    expect(code, startsWith('CULT-5-'));
    expect(store.gifts, isNotEmpty);
  });
}
