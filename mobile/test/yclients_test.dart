import 'dart:convert';

import 'package:cult_clinic/data.dart';
import 'package:cult_clinic/store.dart';
import 'package:cult_clinic/yclients.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Телефон приводится к формату YClients', () {
    expect(normalizePhone('+7 (916) 150-22-39'), '79161502239');
    expect(normalizePhone('89161502239'), '79161502239');
    expect(normalizePhone('9161502239'), '79161502239');
    expect(bookingDatetime(1443513600, '2026-04-12', '12:00'), '2026-04-12 12:00:00');
    expect(bookingDatetime('2026-04-12T12:00:00+03:00', '2026-04-12', '12:00'), '2026-04-12T12:00:00+03:00');
  });

  test('Услуги, слоты и запись читаются из ответа API', () async {
    final seen = <String>[];
    final api = YClientsApi(
      client: _Scripted((request) async {
        seen.add('${request.method} ${request.url}');
        if (request.url.path.endsWith('/book_services/77')) {
          return _json({
            'success': true,
            'data': {
              'services': [
                {'id': '15', 'title': 'Скульптурный массаж', 'price_min': 8000, 'price_max': 8000, 'seance_length': 3600, 'comment': ''},
              ],
            },
          });
        }
        if (request.url.path.contains('/book_staff/')) {
          expect(Uri.decodeQueryComponent(request.url.query), contains('service_ids[]=15'));
          return _json({
            'success': true,
            'data': [
              {'id': 4, 'name': 'Анна', 'specialization': 'Косметолог', 'bookable': true},
            ],
          });
        }
        if (request.url.path.contains('/book_times/')) {
          return _json({
            'success': true,
            'data': [
              {'time': '12:00', 'datetime': 1443513600, 'seance_length': 3600},
            ],
          });
        }
        if (request.url.path.endsWith('/book_record/77')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['phone'], '79161502239');
          expect(request.headers['Authorization'], 'Bearer partner');
          expect(request.headers['Accept'], 'application/vnd.yclients.v2+json');
          return _json({
            'success': true,
            'data': [
              {'id': 1, 'record_id': 99, 'record_hash': 'abc'},
            ],
          });
        }
        return http.Response('{"meta":{"message":"нет"}}', 404);
      }),
    );

    final services = await api.services('partner', 77);
    expect(services.single.title, 'Скульптурный массаж');
    expect(services.single.priceLabel, contains('8'));
    final staff = await api.staff('partner', 77, serviceId: 15);
    expect(staff.single.name, 'Анна');
    final slots = await api.times('partner', 77, 4, '2026-04-12', serviceId: 15);
    expect(slots.single.datetime, '2026-04-12 12:00:00');
    final booked = await api.book(
      partnerToken: 'partner',
      companyId: 77,
      phone: '79161502239',
      fullname: 'Анна',
      email: '',
      serviceId: 15,
      staffId: 4,
      datetime: slots.single.datetime,
    );
    expect(booked.recordId, 99);
    expect(booked.recordHash, 'abc');
    expect(seen, hasLength(4));
  });

  test('Филиал CULT подключён ключами по умолчанию', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    expect(store.companyId, ClinicStore.branchId);
    expect(store.partnerToken, ClinicStore.partnerKey);
    expect(store.userToken, ClinicStore.userKey);
    expect(store.yclientsReady, isTrue);
    expect(store.signedIn, isFalse);
  });

  test('Регистрация по телефону создаёт клиента в YClients', () async {
    SharedPreferences.setMockInitialValues({});
    var created = false;
    final api = YClientsApi(
      client: _Scripted((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/clients/988587')) {
          return _json({'success': true, 'data': []});
        }
        if (request.method == 'POST' && request.url.path.endsWith('/clients/988587')) {
          created = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['phone'], 79001112233);
          expect(body['name'], 'Мария');
          expect(body['sex_id'], 2);
          expect(request.headers['Authorization'], contains('User'));
          return _json({
            'success': true,
            'data': {'id': 42, 'name': 'Мария', 'phone': '+79001112233', 'email': 'm@cult.clinic'},
          });
        }
        if (request.method == 'PUT' && request.url.path.contains('/client/988587/42')) {
          return _json({'success': true, 'data': {'id': 42}});
        }
        return http.Response('{"meta":{"message":"нет"}}', 404);
      }),
    );
    final store = ClinicStore();
    await store.load();
    store.yclients = api;
    await store.setGender(ClientGender.woman);
    expect(await store.registerWithPhone(name: 'Мария', phone: '+7 900 111-22-33', email: 'm@cult.clinic'), isNull);
    expect(created, isTrue);
    expect(store.signedIn, isTrue);
    expect(store.ycClientId, 42);
    expect(store.profilePhone, '79001112233');
    expect(store.profileName, 'Мария');
    expect(store.catalogServices.any((item) => item.slug == 'sculpt'), isTrue);
    expect(store.catalogServices.any((item) => item.slug == 'men-face'), isFalse);

    final next = ClinicStore();
    await next.load();
    expect(next.signedIn, isTrue);
    expect(next.ycClientId, 42);
    expect(next.gender, ClientGender.woman);
    await next.signOut();
    expect(next.signedIn, isFalse);
    expect(next.ycClientId, 0);
    expect(next.gender, ClientGender.woman);
  });

  test('Мужской каталог скрывает женские услуги', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    await store.setGender(ClientGender.man);
    expect(store.catalogServices.any((item) => item.slug == 'men-face'), isTrue);
    expect(store.catalogServices.any((item) => item.slug == 'sculpt'), isFalse);
    expect(store.catalogServices.any((item) => item.slug == 'iv'), isTrue);
  });

  test('Повторный вход находит существующего клиента', () async {
    final api = YClientsApi(
      client: _Scripted((request) async {
        expect(request.method, 'GET');
        expect(request.url.queryParameters['phone'], '79991112233');
        return _json({
          'success': true,
          'data': [
            {'id': 459368479, 'name': 'CULT App Test', 'phone': '+79991112233', 'email': 'cult.app.test@cult.clinic'},
          ],
        });
      }),
    );
    final client = await api.registerClient(
      partnerToken: 'partner',
      userToken: 'user',
      companyId: 988587,
      name: 'Новое Имя',
      phone: '79991112233',
    );
    expect(client.id, 459368479);
    expect(client.name, 'CULT App Test');
  });

  test('Пустой онлайн-каталог дополняется услугами филиала', () async {
    final api = YClientsApi(
      client: _Scripted((request) async {
        if (request.url.path.endsWith('/book_services/988587')) {
          return _json({
            'success': true,
            'data': {
              'services': [],
              'category': [
                {'id': 5, 'title': 'Массажи, spa уходы'},
              ],
            },
          });
        }
        expect(request.headers['Authorization'], 'Bearer partner, User user');
        return _json({
          'success': true,
          'data': [
            {'id': 9, 'title': 'Общий массаж тела, 60 минут', 'price_min': 5500, 'price_max': 5500, 'duration': 3600, 'category_id': 5, 'active': 1},
          ],
        });
      }),
    );
    final store = ClinicStore();
    store.yclients = api;
    store.companyId = '988587';
    store.partnerToken = 'partner';
    store.userToken = 'user';
    expect(await store.refreshCatalog(), isNull);
    expect(store.liveServices.single.title, 'Общий массаж тела, 60 минут');
    expect(store.liveServices.single.category, 'Массажи, spa уходы');
    expect(store.liveServices.single.durationLabel, '1 ч');
  });

  test('Незнакомый токен объясняется по-русски', () async {
    final api = YClientsApi(
      client: _Scripted(
        (request) async => http.Response('{"message":"Unknown token"}', 401, headers: {'content-type': 'application/json'}),
      ),
    );
    expect(
      api.services('x', 988587),
      throwsA(isA<YcException>().having((error) => error.message, 'message', contains('не знает этот токен'))),
    );
  });

  test('Ошибка авторизации приходит текстом филиала', () async {
    final api = YClientsApi(
      client: _Scripted(
        (request) async => http.Response(
          '{"success":false,"meta":{"message":"Неверный токен"}}',
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    expect(api.services('bad', 1), throwsA(isA<YcException>().having((error) => error.message, 'message', 'Неверный токен')));
  });

  test('Отмена записи уходит в YClients с ключами филиала', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.bookVisit(service: 'Массаж', doctor: 'Анна', date: '2026-05-01', time: '12:00', recordId: 99, recordHash: 'abc');
    var cancelled = false;
    store.yclients = YClientsApi(
      client: _Scripted((request) async {
        cancelled = request.method == 'DELETE' && request.url.path.endsWith('/user/records/99/abc');
        expect(request.headers['Authorization'], startsWith('Bearer ${ClinicStore.partnerKey}, User'));
        return http.Response('{"success":true,"data":null}', 200);
      }),
    );
    expect(await store.cancelVisit(store.upcoming.first.id), isNull);
    expect(cancelled, isTrue);
    expect(store.upcoming.where((visit) => visit.recordId == 99), isEmpty);
  });
}

http.Response _json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

class _Scripted extends http.BaseClient {
  _Scripted(this.handler);

  final Future<http.Response> Function(http.Request request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    final materialized = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = bytes;
    final response = await handler(materialized);
    return http.StreamedResponse(Stream<List<int>>.value(response.bodyBytes), response.statusCode, headers: response.headers);
  }
}
