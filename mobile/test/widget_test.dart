import 'package:cult_clinic/data.dart';
import 'package:cult_clinic/main.dart';
import 'package:cult_clinic/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Главная ведёт в анализы и биохакерский магазин', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    await store.setGender(ClientGender.woman);
    await tester.pumpWidget(CultApp(store: store, splash: Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('Запись онлайн'), findsOneWidget);
    expect(find.text('Биохакерский магазин'), findsOneWidget);
    expect(find.text('Чат с доктором'), findsOneWidget);

    await tester.tap(find.text('Мои анализы'));
    await tester.pumpAndSettle();
    expect(find.text('Назначен'), findsOneWidget);
    expect(find.text('Готов'), findsOneWidget);
    expect(find.text('Сдан'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Биохакерский магазин'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Биохакерский магазин'));
    await tester.pumpAndSettle();
    expect(find.text('Home Bio-Scan Kit'), findsOneWidget);
  });

  test('Запись отменяется, бонусов не хватает на крупный сертификат', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.bookVisit(service: 'Анализ крови', doctor: 'AlethiaPro', date: '2026-04-12', time: '10:30');
    expect(store.upcoming.length, 2);
    await store.cancelVisit(store.upcoming.first.id);
    expect(store.upcoming.where((visit) => visit.service == 'Анализ крови'), isEmpty);
    expect(store.spendBonus(30000), isFalse);
    final code = store.buyGift(5000, 'Песок');
    expect(code, startsWith('CULT-5-'));
    expect(store.gifts, isNotEmpty);
  });
}