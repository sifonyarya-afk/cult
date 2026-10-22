import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'theme.dart';

class YcException implements Exception {
  YcException(this.message);

  final String message;

  @override
  String toString() => message;
}

class YcService {
  YcService({
    required this.id,
    required this.title,
    required this.priceMin,
    required this.priceMax,
    required     this.seanceLength,
    this.comment = '',
    this.categoryId = 0,
    this.category = '',
  });

  final int id;
  final String title;
  final int priceMin;
  final int priceMax;
  final int seanceLength;
  final String comment;
  final int categoryId;
  final String category;

  YcService withCategory(String name) {
    if (name.isEmpty || name == category) return this;
    return YcService(
      id: id,
      title: title,
      priceMin: priceMin,
      priceMax: priceMax,
      seanceLength: seanceLength,
      comment: comment,
      categoryId: categoryId,
      category: name,
    );
  }

  String get durationLabel {
    if (seanceLength <= 0) return '';
    final minutes = (seanceLength / 60).round();
    if (minutes < 60) return '$minutes мин';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (rest == 0) return '$hours ч';
    return '$hours ч $rest мин';
  }

  String get priceLabel {
    if (priceMin <= 0 && priceMax <= 0) return 'по запросу';
    if (priceMax > priceMin && priceMin > 0) return '${rub(priceMin)} – ${rub(priceMax)}';
    return rub(priceMax > 0 ? priceMax : priceMin);
  }
}

class YcStaff {
  YcStaff({required this.id, required this.name, required this.specialization, required this.bookable});

  final int id;
  final String name;
  final String specialization;
  final bool bookable;
}

class YcSlot {
  YcSlot({required this.time, required this.datetime});

  final String time;
  final String datetime;
}

class YcBooked {
  YcBooked({required this.recordId, required this.recordHash});

  final int recordId;
  final String recordHash;
}

class YcCard {
  YcCard({required this.title, required this.balance});

  final String title;
  final int balance;
}

class YcClient {
  YcClient({required this.id, required this.name, required this.phone, this.email = ''});

  final int id;
  final String name;
  final String phone;
  final String email;
}

String normalizePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('8') && digits.length == 11) digits = '7${digits.substring(1)}';
  if (digits.length == 10) digits = '7$digits';
  return digits;
}

String bookingDatetime(Object? raw, String date, String time) {
  if (raw is String && (raw.contains('-') || raw.contains('T'))) return raw;
  final clock = time.length == 5 ? '$time:00' : time;
  return '$date $clock';
}

class YClientsApi {
  YClientsApi({http.Client? client, this.base = 'https://api.yclients.com/api/v1'}) : _client = client ?? http.Client();

  final http.Client _client;
  final String base;
  static const _timeout = Duration(seconds: 20);

  Future<List<YcService>> services(String partnerToken, int companyId, {int? staffId}) async {
    final query = <String, String>{};
    if (staffId != null && staffId > 0) query['staff_id'] = '$staffId';
    final data = await _get('/book_services/$companyId', partnerToken, query: query);
    final list = data is Map ? data['services'] : null;
    if (list is! List) return [];
    return [
      for (final item in list)
        if (item is Map)
          YcService(
            id: _asInt(item['id']),
            title: '${item['title'] ?? ''}',
            priceMin: _asInt(item['price_min']),
            priceMax: _asInt(item['price_max']),
            seanceLength: _asInt(item['seance_length'] ?? item['duration']),
            comment: '${item['comment'] ?? ''}',
            categoryId: _asInt(item['category_id']),
          ),
    ].where((item) => item.id > 0 && item.title.isNotEmpty).toList();
  }

  Future<Map<int, String>> categoryNames(String partnerToken, int companyId) async {
    final data = await _get('/book_services/$companyId', partnerToken);
    final list = data is Map ? (data['category'] ?? data['categories']) : null;
    if (list is! List) return {};
    return {
      for (final item in list)
        if (item is Map && _asInt(item['id']) > 0) _asInt(item['id']): '${item['title'] ?? ''}',
    };
  }

  Future<List<YcService>> companyServices(String partnerToken, String userToken, int companyId) async {
    final data = await _get('/company/$companyId/services', partnerToken, userToken: userToken);
    if (data is! List) return [];
    return [
      for (final item in data)
        if (item is Map && item['active'] != 0)
          YcService(
            id: _asInt(item['id']),
            title: '${item['title'] ?? ''}',
            priceMin: _asInt(item['price_min']),
            priceMax: _asInt(item['price_max']),
            seanceLength: _asInt(item['duration'] ?? item['seance_length']),
            comment: '${item['comment'] ?? ''}',
            categoryId: _asInt(item['category_id']),
          ),
    ].where((item) => item.id > 0 && item.title.isNotEmpty).toList();
  }

  Future<List<YcStaff>> staff(String partnerToken, int companyId, {int? serviceId}) async {
    final query = <String, String>{};
    if (serviceId != null && serviceId > 0) query['service_ids[]'] = '$serviceId';
    final data = await _get('/book_staff/$companyId', partnerToken, query: query);
    if (data is! List) return [];
    return [
      for (final item in data)
        if (item is Map)
          YcStaff(
            id: _asInt(item['id']),
            name: '${item['name'] ?? ''}',
            specialization: '${item['specialization'] ?? ''}',
            bookable: item['bookable'] != false,
          ),
    ].where((item) => item.id > 0 && item.name.isNotEmpty).toList();
  }

  Future<List<String>> bookableDates(String partnerToken, int companyId, {int? staffId, int? serviceId}) async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 60));
    String ymd(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    final query = <String, String>{'date_from': ymd(from), 'date_to': ymd(to)};
    if (staffId != null && staffId > 0) query['staff_id'] = '$staffId';
    if (serviceId != null && serviceId > 0) query['service_ids[]'] = '$serviceId';
    final data = await _get('/book_dates/$companyId', partnerToken, query: query);
    if (data is! Map) return [];
    final dates = data['booking_dates'];
    if (dates is! List) return [];
    return [
      for (final item in dates)
        if (item is String && item.length >= 10) item.substring(0, 10) else if (item is num) _ymdFromUnix(item.toInt()),
    ].where((item) => item.isNotEmpty).toList();
  }

  Future<List<YcSlot>> times(String partnerToken, int companyId, int staffId, String date, {int? serviceId}) async {
    final query = <String, String>{};
    if (serviceId != null && serviceId > 0) query['service_ids[]'] = '$serviceId';
    final data = await _get('/book_times/$companyId/$staffId/$date', partnerToken, query: query);
    if (data is! List) return [];
    return [
      for (final item in data)
        if (item is Map && '${item['time'] ?? ''}'.isNotEmpty)
          YcSlot(
            time: '${item['time']}',
            datetime: bookingDatetime(item['datetime'], date, '${item['time']}'),
          ),
    ];
  }

  Future<YcBooked> book({
    required String partnerToken,
    required int companyId,
    required String phone,
    required String fullname,
    required String email,
    required int serviceId,
    required int staffId,
    required String datetime,
    String code = '',
  }) async {
    final body = <String, Object?>{
      'phone': phone,
      'fullname': fullname,
      'email': email.isEmpty ? 'client@cult.clinic' : email,
      'comment': 'Запись из приложения CULT',
      'appointments': [
        {
          'id': 1,
          'services': [serviceId],
          'staff_id': staffId,
          'datetime': datetime,
        },
      ],
    };
    if (code.trim().isNotEmpty) body['code'] = code.trim();
    final data = await _post('/book_record/$companyId', partnerToken, body);
    final row = data is List && data.isNotEmpty ? data.first : data;
    if (row is! Map) throw YcException('YClients не подтвердил запись.');
    final recordId = _asInt(row['record_id']);
    final hash = '${row['record_hash'] ?? ''}';
    if (recordId <= 0 || hash.isEmpty) throw YcException('YClients не вернул номер записи.');
    return YcBooked(recordId: recordId, recordHash: hash);
  }

  Future<void> cancel({
    required String partnerToken,
    required String userToken,
    required int recordId,
    required String recordHash,
  }) async {
    await _delete('/user/records/$recordId/$recordHash', partnerToken, userToken: userToken);
  }

  Future<YcClient?> findClientByPhone({
    required String partnerToken,
    required String userToken,
    required int companyId,
    required String phone,
  }) async {
    final digits = normalizePhone(phone);
    if (digits.length < 11) return null;
    final data = await _get(
      '/clients/$companyId',
      partnerToken,
      userToken: userToken,
      query: {'phone': digits, 'page': '1', 'count': '5'},
    );
    if (data is! List || data.isEmpty) return null;
    for (final item in data) {
      if (item is! Map) continue;
      final client = _parseClient(item);
      if (client != null && normalizePhone(client.phone) == digits) return client;
    }
    final first = data.first;
    return first is Map ? _parseClient(first) : null;
  }

  Future<YcClient> createClient({
    required String partnerToken,
    required String userToken,
    required int companyId,
    required String name,
    required String phone,
    String email = '',
  }) async {
    final digits = normalizePhone(phone);
    if (digits.length < 11) throw YcException('Укажите телефон в формате +7.');
    final body = <String, Object?>{
      'name': name.trim(),
      'phone': int.tryParse(digits) ?? digits,
      'comment': 'Регистрация из приложения CULT',
    };
    if (email.trim().isNotEmpty) body['email'] = email.trim();
    try {
      final data = await _post('/clients/$companyId', partnerToken, body, userToken: userToken);
      final client = data is Map ? _parseClient(data) : null;
      if (client == null) throw YcException('YClients не сохранил клиента.');
      return client;
    } on YcException catch (error) {
      if (!error.message.toLowerCase().contains('уже существует')) rethrow;
      final existing = await findClientByPhone(
        partnerToken: partnerToken,
        userToken: userToken,
        companyId: companyId,
        phone: digits,
      );
      if (existing != null) return existing;
      rethrow;
    }
  }

  Future<YcClient> registerClient({
    required String partnerToken,
    required String userToken,
    required int companyId,
    required String name,
    required String phone,
    String email = '',
  }) async {
    final existing = await findClientByPhone(
      partnerToken: partnerToken,
      userToken: userToken,
      companyId: companyId,
      phone: phone,
    );
    if (existing != null) return existing;
    return createClient(
      partnerToken: partnerToken,
      userToken: userToken,
      companyId: companyId,
      name: name,
      phone: phone,
      email: email,
    );
  }

  YcClient? _parseClient(Map item) {
    final id = _asInt(item['id']);
    final name = '${item['display_name'] ?? item['name'] ?? ''}'.trim();
    final phone = '${item['phone'] ?? ''}';
    if (id <= 0) return null;
    return YcClient(id: id, name: name.isEmpty ? 'Клиент' : name, phone: phone, email: '${item['email'] ?? ''}');
  }

  Future<List<YcCard>> loyaltyCards({
    required String partnerToken,
    required String userToken,
    required String phone,
    required int companyId,
    required int chainId,
  }) async {
    final data = await _get('/loyalty/cards/$phone/$chainId/$companyId', partnerToken, userToken: userToken);
    if (data is! List) return [];
    return [
      for (final item in data)
        if (item is Map)
          YcCard(
            title: item['type'] is Map ? '${(item['type'] as Map)['title'] ?? 'Карта'}' : 'Карта ${item['number'] ?? ''}',
            balance: _asInt(item['balance']),
          ),
    ];
  }

  Future<Object?> _get(String path, String partnerToken, {Map<String, String>? query, String userToken = ''}) async {
    final response = await _guard(() => _client.get(_uri(path, query), headers: _headers(partnerToken, userToken)).timeout(_timeout));
    return _payload(response);
  }

  Future<Object?> _post(String path, String partnerToken, Map<String, Object?> body, {String userToken = ''}) async {
    final response = await _guard(
      () => _client.post(_uri(path), headers: _headers(partnerToken, userToken), body: jsonEncode(body)).timeout(_timeout),
    );
    return _payload(response);
  }

  Future<void> _delete(String path, String partnerToken, {String userToken = ''}) async {
    final response = await _guard(() => _client.delete(_uri(path), headers: _headers(partnerToken, userToken)).timeout(_timeout));
    if (response.body.isEmpty) return;
    _payload(response);
  }

  Future<http.Response> _guard(Future<http.Response> Function() send) async {
    try {
      final response = await send();
      if (response.statusCode >= 400) throw YcException(_message(response));
      return response;
    } on YcException {
      rethrow;
    } on TimeoutException {
      throw YcException('YClients не отвечает.');
    } on http.ClientException {
      throw YcException('Нет связи с YClients.');
    } catch (_) {
      throw YcException('Не удалось обратиться к YClients.');
    }
  }

  Object? _payload(http.Response response) {
    if (response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is Map) {
      if (decoded['success'] == false) throw YcException(_message(response));
      if (decoded.containsKey('data')) return decoded['data'];
    }
    return decoded;
  }

  Map<String, String> _headers(String partnerToken, String userToken) => {
        'Accept': 'application/vnd.yclients.v2+json',
        'Content-Type': 'application/json',
        'Authorization': userToken.trim().isEmpty ? 'Bearer $partnerToken' : 'Bearer $partnerToken, User $userToken',
      };

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$base$path');
    if (query == null || query.isEmpty) return uri;
    final tail = query.entries.map((entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}').join('&');
    return Uri.parse('$uri?$tail');
  }

  String _message(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final meta = decoded['meta'];
        if (meta is Map && meta['message'] is String && (meta['message'] as String).trim().isNotEmpty) {
          return _known(meta['message'] as String);
        }
        if (meta is List && meta.isNotEmpty && meta.first is Map && meta.first['message'] is String) {
          return _known(meta.first['message'] as String);
        }
        if (decoded['message'] is String && (decoded['message'] as String).trim().isNotEmpty) {
          return _known(decoded['message'] as String);
        }
      }
    } catch (_) {}
    return switch (response.statusCode) {
      401 => 'Неверный партнёрский токен. Нужен API-ключ из настроек аккаунта в маркетплейсе, не User token приложения.',
      403 => 'Нет доступа к компании.',
      404 => 'Компания не найдена.',
      _ => 'YClients ответил с ошибкой ${response.statusCode}.',
    };
  }
}

String _known(String message) {
  if (message.trim().toLowerCase() == 'unknown token') {
    return 'YClients не знает этот токен. Нужен API-ключ из настроек аккаунта в маркетплейсе, не User token приложения.';
  }
  return message;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.round() ?? 0;
  return 0;
}

String _ymdFromUnix(int seconds) {
  final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
